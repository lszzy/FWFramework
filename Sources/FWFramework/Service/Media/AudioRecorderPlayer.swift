//
//  AudioRecorderPlayer.swift
//  AudioRecorderPlayer
//
//  Created by wuyong on 2025/6/11.
//

import AVFoundation
import Foundation

/// 音频录制播放器
///
/// [react-native-audio-recorder-player](https://github.com/hyochan/react-native-audio-recorder-player)
class AudioRecorderPlayer: NSObject, AVAudioRecorderDelegate {
    public struct RecordBackType: Sendable {
        public var isRecording: Bool
        public var currentPosition: TimeInterval
        public var currentMetering: Float
    }

    public struct PlayBackType: Sendable {
        public var isMuted: Bool?
        public var currentPosition: TimeInterval
        public var duration: TimeInterval
        public var isFinished: Bool
    }

    public struct AudioSet: Sendable {
        public var sampleRate: Int?
        public var formatID: AudioFormatID?
        public var mode: AVAudioSession.Mode?
        public var numberOfChannels: Int?
        public var encoderAudioQuality: AVAudioQuality?
        public var encoderBitRate: Int?
        public var linearPCMBitDepth: Int?
        public var linearPCMIsBigEndian: Bool?
        public var linearPCMIsFloat: Bool?
        public var linearPCMIsNonInterleaved: Bool?
    }

    // MARK: - Accessor
    /// 录制回调监听
    public var recordBackListener: ((RecordBackType) -> Void)?
    /// 播放回调监听
    public var playBackListener: ((PlayBackType) -> Void)?
    /// 音量监听频率
    public var subscriptionDuration: Double = 0.5

    private var audioFileURL: URL?
    private var audioRecorder: AVAudioRecorder!
    private var recordTimer: Timer?
    private var isMeteringEnabled = false

    private var pausedPlayTime: CMTime?
    private var audioPlayerAsset: AVURLAsset!
    private var audioPlayerItem: AVPlayerItem!
    private var audioPlayer: AVPlayer!
    private var timeObserverToken: Any?

    private var _isRecording = false
    private var _isPlaying = false
    private var _hasPaused = false
    private var _hasPausedRecord = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public
    /// 开始录制
    public func startRecorder(
        uri: String? = nil,
        audioSet: AudioSet? = nil,
        meteringEnabled: Bool? = nil
    ) async throws -> String? {
        guard !_isRecording else { return nil }

        _isRecording = true
        do {
            return try await startRecorder(path: uri ?? "DEFAULT", audioSet: audioSet, meteringEnabled: meteringEnabled ?? false)
        } catch {
            _isRecording = false
            throw error
        }
    }

    /// 暂停录制
    public func pauseRecorder() async throws {
        guard !_hasPausedRecord else { return }

        _hasPausedRecord = true
        return try await withCheckedThrowingContinuation { continuation in
            recordTimer?.invalidate()
            recordTimer = nil

            DispatchQueue.main.async {
                if self.audioRecorder == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recorder is not recording"]))
                    return
                }

                self.audioRecorder.pause()
                continuation.resume()
            }
        }
    }

    /// 继续录制
    public func resumeRecorder() async throws {
        guard _hasPausedRecord else { return }

        _hasPausedRecord = false
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if self.audioRecorder == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recorder is nil"]))
                    return
                }

                self.audioRecorder.record()

                if self.recordTimer == nil {
                    self.startRecorderTimer()
                }
                continuation.resume()
            }
        }
    }

    /// 停止录制
    @discardableResult
    public func stopRecorder() async throws -> String? {
        guard _isRecording else { return nil }

        _isRecording = false
        _hasPausedRecord = false
        return try await withCheckedThrowingContinuation { continuation in
            if recordTimer != nil {
                recordTimer!.invalidate()
                recordTimer = nil
            }

            DispatchQueue.main.async {
                if self.audioRecorder == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to stop recorder. It is already nil."]))
                    return
                }

                self.audioRecorder.stop()

                continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
            }
        }
    }

    /// 开始播放
    public func startPlayer(
        uri: String? = nil,
        httpHeaders: [String: String]? = nil
    ) async throws -> String? {
        guard !_isPlaying || _hasPaused else { return nil }

        _isPlaying = true
        _hasPaused = false
        return try await startPlayer(path: uri ?? "DEFAULT", httpHeaders: httpHeaders ?? [:])
    }

    /// 暂停播放
    public func pausePlayer() async throws {
        guard _isPlaying, !_hasPaused else { return }

        _hasPaused = true
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if self.audioPlayer == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is not playing"]))
                    return
                }

                self.audioPlayer.pause()
                continuation.resume()
            }
        }
    }

    /// 继续播放
    public func resumePlayer() async throws {
        guard _isPlaying, _hasPaused else { return }

        _hasPaused = false
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if self.audioPlayer == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                    return
                }

                self.audioPlayer.play()
                continuation.resume()
            }
        }
    }

    /// 停止播放
    @discardableResult
    public func stopPlayer() async throws -> String? {
        guard _isPlaying else { return nil }

        _isPlaying = false
        _hasPaused = false
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if self.audioPlayer == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player has already stopped."]))
                    return
                }

                self.audioPlayer.pause()
                self.removePeriodicTimeObserver()
                self.audioPlayer = nil

                continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
            }
        }
    }

    /// 跳转播放
    public func seekToPlayer(_ seconds: Double) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if self.audioPlayer == nil {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                return
            }

            audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            continuation.resume()
        }
    }

    /// 设置音量
    public func setVolume(_ volume: Float) async throws {
        guard volume >= 0 && volume <= 1 else { return }

        return try await withCheckedThrowingContinuation { continuation in
            if self.audioPlayer == nil {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                return
            }

            self.audioPlayer.volume = volume
            continuation.resume()
        }
    }

    /// 设置播放速度
    public func setPlaybackSpeed(_ playbackSpeed: Float) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if self.audioPlayer == nil {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                    return
                }

                self.audioPlayer.rate = playbackSpeed
                continuation.resume()
            }
        }
    }

    /// 格式化时长，格式"00:00"或"00:00:00"
    public func formatDuration(_ duration: TimeInterval, hasMilliseconds: Bool = true) -> String {
        if hasMilliseconds {
            var milliseconds = Int64(duration * 1000)
            var seconds = milliseconds / 1000
            let minutes = seconds / 60
            seconds = seconds % 60
            milliseconds = (milliseconds % 1000) / 10
            return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
        } else {
            var seconds = Int64(duration)
            var minutes = seconds / 60
            seconds = seconds % 60
            minutes = minutes % 60
            return String(format: "%02ld:%02ld", minutes, seconds)
        }
    }

    // MARK: - Private
    func setAudioFileURL(path: String) {
        if path == "DEFAULT" {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            audioFileURL = cachesDirectory.appendingPathComponent("sound.m4a")
        } else if path.hasPrefix("http://") || path.hasPrefix("https://") || path.hasPrefix("file://") {
            audioFileURL = URL(string: path)
        } else {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            audioFileURL = cachesDirectory.appendingPathComponent(path)
        }
    }

    /**********               Recorder               **********/

    @objc(updateRecorderProgress:)
    func updateRecorderProgress(timer: Timer) {
        if audioRecorder != nil {
            var currentMetering: Float = 0
            if isMeteringEnabled {
                audioRecorder.updateMeters()
                currentMetering = audioRecorder.averagePower(forChannel: 0)
            }

            let status = RecordBackType(isRecording: audioRecorder.isRecording, currentPosition: audioRecorder.currentTime, currentMetering: currentMetering)
            recordBackListener?(status)
        }
    }

    func startRecorderTimer() {
        let timer = Timer(
            timeInterval: subscriptionDuration,
            target: self,
            selector: #selector(updateRecorderProgress),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .default)
        recordTimer = timer
    }

    @objc func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }

        switch interruptionType {
        case AVAudioSession.InterruptionType.began.rawValue:
            Task {
                try? await pauseRecorder()
            }
        case AVAudioSession.InterruptionType.ended.rawValue:
            Task {
                try? await resumeRecorder()
            }
        default:
            break
        }
    }

    /**********               Player               **********/

    @discardableResult
    func startRecorder(path: String, audioSet: AudioSet?, meteringEnabled: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            isMeteringEnabled = meteringEnabled

            let avFormat = audioSet?.formatID ?? kAudioFormatAppleLossless
            if path == "DEFAULT" {
                let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let fileExt = fileExtension(forAudioFormat: avFormat)
                audioFileURL = cachesDirectory.appendingPathComponent("sound." + fileExt)
            } else {
                setAudioFileURL(path: path)
            }

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: audioSet?.mode ?? .default, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetooth])
                try audioSession.setActive(true)

                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted {
                            let settings: [String: Any] = [
                                AVSampleRateKey: audioSet?.sampleRate ?? 44_100,
                                AVFormatIDKey: avFormat,
                                AVNumberOfChannelsKey: audioSet?.numberOfChannels ?? 2,
                                AVEncoderAudioQualityKey: (audioSet?.encoderAudioQuality ?? .medium).rawValue,
                                AVLinearPCMBitDepthKey: audioSet?.linearPCMBitDepth ?? AVLinearPCMBitDepthKey.count,
                                AVLinearPCMIsBigEndianKey: audioSet?.linearPCMIsBigEndian ?? true,
                                AVLinearPCMIsFloatKey: audioSet?.linearPCMIsFloat ?? false,
                                AVLinearPCMIsNonInterleaved: audioSet?.linearPCMIsNonInterleaved ?? false,
                                AVEncoderBitRateKey: audioSet?.encoderBitRate ?? 128_000
                            ]

                            do {
                                self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL!, settings: settings)

                                if self.audioRecorder != nil {
                                    self.audioRecorder.prepareToRecord()
                                    self.audioRecorder.delegate = self
                                    self.audioRecorder.isMeteringEnabled = meteringEnabled
                                    let isRecordStarted = self.audioRecorder.record()
                                    if !isRecordStarted {
                                        continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error occured during initiating recorder"]))
                                        return
                                    }

                                    self.startRecorderTimer()

                                    continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
                                    return
                                }

                                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error occured during initiating recorder"]))
                            } catch {
                                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                            }
                        } else {
                            continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Record permission not granted"]))
                        }
                    }
                }
            } catch {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            }
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Failed to stop recorder")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
        print(error ?? "")
    }

    /**********               Player               **********/
    func addPeriodicTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: subscriptionDuration, preferredTimescale: timeScale)

        timeObserverToken = audioPlayer.addPeriodicTimeObserver(forInterval: time,
                                                                queue: .main) { _ in
            if self.audioPlayer != nil {
                self.playerCallback(
                    PlayBackType(
                        isMuted: self.audioPlayer.isMuted,
                        currentPosition: self.audioPlayerItem.currentTime().seconds,
                        duration: self.audioPlayerItem.asset.duration.seconds,
                        isFinished: false
                    )
                )
            }
        }
    }

    func removePeriodicTimeObserver() {
        if let timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    @discardableResult
    func startPlayer(
        path: String,
        httpHeaders: [String: String]
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetooth])
                try audioSession.setActive(true)
            } catch {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                return
            }

            setAudioFileURL(path: path)
            audioPlayerAsset = AVURLAsset(url: audioFileURL!, options: ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders])
            audioPlayerItem = AVPlayerItem(asset: audioPlayerAsset!)

            if audioPlayer == nil {
                audioPlayer = AVPlayer(playerItem: audioPlayerItem)
            } else {
                audioPlayer.replaceCurrentItem(with: audioPlayerItem)
            }

            addPeriodicTimeObserver()
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer.currentItem)
            DispatchQueue.fw.mainAsync {
                self.audioPlayer.play()

                continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
            }
        }
    }

    @objc func playerDidFinishPlaying(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            let duration = playerItem.duration.seconds
            playerCallback(
                PlayBackType(
                    isMuted: audioPlayer?.isMuted,
                    currentPosition: duration,
                    duration: duration,
                    isFinished: true
                )
            )
        }
    }

    func playerCallback(_ event: PlayBackType) {
        playBackListener?(event)

        if event.isFinished {
            Task {
                try? await stopPlayer()
            }
        }
    }

    private func fileExtension(forAudioFormat format: AudioFormatID) -> String {
        switch format {
        case kAudioFormatOpus:
            return "ogg"
        case kAudioFormatLinearPCM:
            return "wav"
        case kAudioFormatAC3, kAudioFormat60958AC3:
            return "ac3"
        case kAudioFormatAppleIMA4:
            return "caf"
        case kAudioFormatMPEG4AAC, kAudioFormatMPEG4CELP, kAudioFormatMPEG4HVXC, kAudioFormatMPEG4TwinVQ, kAudioFormatMPEG4AAC_HE, kAudioFormatMPEG4AAC_LD, kAudioFormatMPEG4AAC_ELD, kAudioFormatMPEG4AAC_ELD_SBR, kAudioFormatMPEG4AAC_ELD_V2, kAudioFormatMPEG4AAC_HE_V2, kAudioFormatMPEG4AAC_Spatial:
            return "m4a"
        case kAudioFormatMACE3, kAudioFormatMACE6:
            return "caf"
        case kAudioFormatULaw, kAudioFormatALaw:
            return "wav"
        case kAudioFormatQDesign, kAudioFormatQDesign2:
            return "mov"
        case kAudioFormatQUALCOMM:
            return "qcp"
        case kAudioFormatMPEGLayer1:
            return "mp1"
        case kAudioFormatMPEGLayer2:
            return "mp2"
        case kAudioFormatMPEGLayer3:
            return "mp3"
        case kAudioFormatMIDIStream:
            return "mid"
        case kAudioFormatAppleLossless:
            return "m4a"
        case kAudioFormatAMR:
            return "amr"
        case kAudioFormatAMR_WB:
            return "awb"
        case kAudioFormatAudible:
            return "aa"
        case kAudioFormatiLBC:
            return "ilbc"
        case kAudioFormatDVIIntelIMA, kAudioFormatMicrosoftGSM:
            return "wav"
        default:
            return "audio"
        }
    }
}
