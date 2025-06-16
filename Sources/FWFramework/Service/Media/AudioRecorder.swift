//
//  AudioRecorder.swift
//  AudioRecorder
//
//  Created by wuyong on 2025/6/11.
//

import AVFoundation
import Speech

/// 音频录制播放器
///
/// [react-native-audio-recorder-player](https://github.com/hyochan/react-native-audio-recorder-player)
open class AudioRecorder: NSObject, AVAudioRecorderDelegate, @unchecked Sendable {
    /// 录制回调对象
    public struct RecordBackState: Sendable {
        public var isRecording: Bool = false
        public var currentPosition: TimeInterval = 0
        public var currentMetering: Float = 0
        
        public init() {}
    }

    /// 播放回调对象
    public struct PlayBackState: Sendable {
        public var isMuted: Bool?
        public var currentPosition: TimeInterval = 0
        public var duration: TimeInterval = 0
        public var isFinished: Bool = false
        
        public init() {}
    }

    /// 音频设置
    public struct AudioSettings: Sendable {
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
        
        public init() {}
    }

    // MARK: - Accessor
    /// 录制回调监听
    public var recordBackListener: ((RecordBackState) -> Void)?
    /// 播放回调监听
    public var playBackListener: ((PlayBackState) -> Void)?
    /// 音量监听频率
    public var subscriptionDuration: Double = 0.5
    
    /// 音频文件URL
    public private(set) var audioFileURL: URL?
    /// 是否正在录制
    public private(set) var isRecording = false
    /// 是否录制已暂停
    public private(set) var isRecordingPaused = false
    /// 是否正在播放
    public private(set) var isPlaying = false
    /// 是否播放已暂停
    public private(set) var isPaused = false
    /// 是否正在识别
    public private(set) var isRecognizing = false

    private var audioRecorder: AVAudioRecorder!
    private var recordTimer: Timer?
    private var isMeteringEnabled = false

    private var pausedPlayTime: CMTime?
    private var audioPlayerAsset: AVURLAsset!
    private var audioPlayerItem: AVPlayerItem!
    private var audioPlayer: AVPlayer!
    private var timeObserverToken: Any?
    
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionLocale: Locale?

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public
    /// 开始录制
    @discardableResult
    open func startRecorder(
        uri: String? = nil,
        audioSettings: AudioSettings? = nil,
        meteringEnabled: Bool? = nil
    ) async throws -> String? {
        guard !isRecording else { return nil }

        isRecording = true
        do {
            return try await startRecorder(path: uri ?? "", audioSettings: audioSettings, meteringEnabled: meteringEnabled ?? false)
        } catch {
            isRecording = false
            throw error
        }
    }

    /// 暂停录制
    open func pauseRecorder() async throws {
        guard !isRecordingPaused else { return }

        isRecordingPaused = true
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
    open func resumeRecorder() async throws {
        guard isRecordingPaused else { return }

        isRecordingPaused = false
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
    open func stopRecorder() async throws -> String? {
        guard isRecording else { return nil }

        isRecording = false
        isRecordingPaused = false
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
    @discardableResult
    open func startPlayer(
        uri: String? = nil,
        httpHeaders: [String: String]? = nil
    ) async throws -> String? {
        guard !isPlaying || isPaused else { return nil }

        isPlaying = true
        isPaused = false
        return try await startPlayer(path: uri ?? "", httpHeaders: httpHeaders ?? [:])
    }

    /// 暂停播放
    open func pausePlayer() async throws {
        guard isPlaying, !isPaused else { return }

        isPaused = true
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
    open func resumePlayer() async throws {
        guard isPlaying, isPaused else { return }

        isPaused = false
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
    open func stopPlayer() async throws -> String? {
        guard isPlaying else { return nil }

        isPlaying = false
        isPaused = false
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
    open func seekToPlayer(_ seconds: Double) async throws {
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
    @discardableResult
    open func setVolume(_ volume: Float) async throws -> Float {
        return try await withCheckedThrowingContinuation { continuation in
            guard volume >= 0 && volume <= 1 else {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Value of volume should be between 0.0 to 1.0"]))
                return
            }
            
            if self.audioPlayer == nil {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                return
            }

            self.audioPlayer.volume = volume
            continuation.resume(returning: self.audioPlayer.volume)
        }
    }

    /// 设置播放速度
    open func setPlaybackSpeed(_ playbackSpeed: Float) async throws {
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
    open func formatDuration(_ duration: TimeInterval, hasMilliseconds: Bool = true) -> String {
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
    
    /// 开始语音识别，取消调用Task.cancel即可
    open func startRecognizer(
        uri: String? = nil,
        locale: Locale? = nil,
        customize: ((SFSpeechRecognizer) -> Void)? = nil,
        requestCustomize: ((SFSpeechURLRecognitionRequest) -> Void)? = nil
    ) async throws -> SFSpeechRecognitionResult? {
        guard !isRecognizing else { return nil }

        isRecognizing = true
        do {
            let sendableResult = try await startRecognizer(path: uri ?? "", locale: locale ?? .current, customize: customize, requestCustomize: requestCustomize)
            isRecognizing = false
            return sendableResult.value
        } catch {
            isRecognizing = false
            throw error
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    open func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "AudioRecorderPlayer: Failed to stop recorder")
            #endif
        }
    }

    open func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
        if let error {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "AudioRecorderPlayer: %@", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Recorder
    private func setAudioFileURL(path: String, fileExt: String? = nil) {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            audioFileURL = URL(string: path)
            return
        }
        
        if path.hasPrefix("file://") {
            audioFileURL = URL(string: path)
        } else if (path as NSString).isAbsolutePath {
            audioFileURL = URL(fileURLWithPath: path)
        } else {
            let filePath = FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "AudioRecorder"])
            let fileName = !path.isEmpty ? path : ("sound." + (fileExt ?? "m4a"))
            audioFileURL = URL(fileURLWithPath: filePath.fw.appendingPath(fileName))
        }
        
        if let audioFileDir = audioFileURL?.deletingLastPathComponent(), !FileManager.default.fileExists(atPath: audioFileDir.path) {
            try? FileManager.default.createDirectory(at: audioFileDir, withIntermediateDirectories: true)
        }
    }

    @objc(updateRecorderProgress:)
    private func updateRecorderProgress(timer: Timer) {
        if audioRecorder != nil {
            var currentMetering: Float = 0
            if isMeteringEnabled {
                audioRecorder.updateMeters()
                currentMetering = audioRecorder.averagePower(forChannel: 0)
            }

            var state = RecordBackState()
            state.isRecording = audioRecorder.isRecording
            state.currentPosition = audioRecorder.currentTime
            state.currentMetering = currentMetering
            recordBackListener?(state)
        }
    }

    private func startRecorderTimer() {
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

    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
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

    @discardableResult
    private func startRecorder(path: String, audioSettings: AudioSettings?, meteringEnabled: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            isMeteringEnabled = meteringEnabled

            let avFormat = audioSettings?.formatID ?? kAudioFormatAppleLossless
            let fileExt = fileExtension(for: avFormat)
            setAudioFileURL(path: path, fileExt: fileExt)

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: audioSettings?.mode ?? .default, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetooth])
                try audioSession.setActive(true)

                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted {
                            let settings: [String: Any] = [
                                AVSampleRateKey: audioSettings?.sampleRate ?? 44_100,
                                AVFormatIDKey: avFormat,
                                AVNumberOfChannelsKey: audioSettings?.numberOfChannels ?? 2,
                                AVEncoderAudioQualityKey: (audioSettings?.encoderAudioQuality ?? .medium).rawValue,
                                AVLinearPCMBitDepthKey: audioSettings?.linearPCMBitDepth ?? AVLinearPCMBitDepthKey.count,
                                AVLinearPCMIsBigEndianKey: audioSettings?.linearPCMIsBigEndian ?? true,
                                AVLinearPCMIsFloatKey: audioSettings?.linearPCMIsFloat ?? false,
                                AVLinearPCMIsNonInterleaved: audioSettings?.linearPCMIsNonInterleaved ?? false,
                                AVEncoderBitRateKey: audioSettings?.encoderBitRate ?? 128_000
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

    // MARK: - Player
    private func addPeriodicTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: subscriptionDuration, preferredTimescale: timeScale)

        timeObserverToken = audioPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) { _ in
            DispatchQueue.fw.mainAsync {
                if self.audioPlayer != nil {
                    var state = PlayBackState()
                    state.isMuted = self.audioPlayer.isMuted
                    state.currentPosition = self.audioPlayerItem.currentTime().seconds
                    state.duration = self.audioPlayerItem.asset.duration.seconds
                    state.isFinished = false
                    self.playerCallback(state)
                }
            }
        }
    }

    private func removePeriodicTimeObserver() {
        if let timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    @discardableResult
    private func startPlayer(
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

    @objc private func playerDidFinishPlaying(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            let duration = playerItem.duration.seconds
            var state = PlayBackState()
            state.isMuted = audioPlayer?.isMuted
            state.currentPosition = duration
            state.duration = duration
            state.isFinished = true
            playerCallback(state)
        }
    }

    private func playerCallback(_ event: PlayBackState) {
        playBackListener?(event)

        if event.isFinished {
            Task {
                try? await stopPlayer()
            }
        }
    }

    private func fileExtension(for audioFormat: AudioFormatID) -> String {
        switch audioFormat {
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
    
    // MARK: - Recognizer
    private func startRecognizer(
        path: String,
        locale: Locale,
        customize: ((SFSpeechRecognizer) -> Void)?,
        requestCustomize: ((SFSpeechURLRecognitionRequest) -> Void)?
    ) async throws -> SendableValue<SFSpeechRecognitionResult> {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    guard status == .authorized else {
                        continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recognize permission not granted"]))
                        return
                    }
                    
                    self.setAudioFileURL(path: path)
                    guard let recordURL = self.audioFileURL,
                          FileManager.default.fileExists(atPath: recordURL.path) else {
                        continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "The audio file does not exist"]))
                        return
                    }
                    
                    if self.speechRecognizer == nil || locale != self.recognitionLocale {
                        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
                        self.recognitionLocale = locale
                    }
                    guard self.speechRecognizer != nil, self.speechRecognizer.isAvailable else {
                        continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "The speech recognizer is unavailable"]))
                        return
                    }
                    customize?(self.speechRecognizer)
                    
                    let recognitionRequest = SFSpeechURLRecognitionRequest(url: recordURL)
                    requestCustomize?(recognitionRequest)
                    let sendableResumed = SendableValue(false)
                    self.recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
                        if let result, result.isFinal {
                            self?.recognitionTask = nil
                            if !sendableResumed.value {
                                sendableResumed.value = true
                                continuation.resume(returning: SendableValue(result))
                            }
                        } else if let error {
                            self?.recognitionTask = nil
                            if !sendableResumed.value {
                                sendableResumed.value = true
                                continuation.resume(throwing: error)
                            }
                        }
                    })
                }
            }
        } onCancel: {
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            isRecognizing = false
        }
    }
}
