//
//  AudioRecorderPlayer.swift
//  AudioRecorderPlayer
//
//  Created by wuyong on 2025/6/11.
//

import Foundation
import AVFoundation

/// 音频录制播放器
///
/// [react-native-audio-recorder-player](https://github.com/hyochan/react-native-audio-recorder-player)
class AudioRecorderPlayer: NSObject, AVAudioRecorderDelegate {
    var recordBackListener: (([String : Any]) -> Void)?
    var playBackListener: (([String : Any]) -> Void)?
    
    var subscriptionDuration: Double = 0.5
    var audioFileURL: URL?

    // Recorder
    var audioRecorder: AVAudioRecorder!
    var audioSession: AVAudioSession!
    var recordTimer: Timer?
    var _meteringEnabled: Bool = false

    // Player
    var pausedPlayTime: CMTime?
    var audioPlayerAsset: AVURLAsset!
    var audioPlayerItem: AVPlayerItem!
    var audioPlayer: AVPlayer!
    var timeObserverToken: Any?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setAudioFileURL(path: String) {
        if (path == "DEFAULT") {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            audioFileURL = cachesDirectory.appendingPathComponent("sound.m4a")
        } else if (path.hasPrefix("http://") || path.hasPrefix("https://") || path.hasPrefix("file://")) {
            audioFileURL = URL(string: path)
        } else {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            audioFileURL = cachesDirectory.appendingPathComponent(path)
        }
    }

    /**********               Recorder               **********/

    @objc(updateRecorderProgress:)
    func updateRecorderProgress(timer: Timer) -> Void {
        if (audioRecorder != nil) {
            var currentMetering: Float = 0

            if (_meteringEnabled) {
                audioRecorder.updateMeters()
                currentMetering = audioRecorder.averagePower(forChannel: 0)
            }

            let status = [
                "isRecording": audioRecorder.isRecording,
                "currentPosition": audioRecorder.currentTime * 1000,
                "currentMetering": currentMetering,
            ] as [String : Any];

            recordBackListener?(status)
        }
    }

    func startRecorderTimer() -> Void {
        let timer = Timer(
            timeInterval: self.subscriptionDuration,
            target: self,
            selector: #selector(self.updateRecorderProgress),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .default)
        self.recordTimer = timer
    }

    func pauseRecorder() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            recordTimer?.invalidate()
            recordTimer = nil;
            
            DispatchQueue.main.async {
                if (self.audioRecorder == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recorder is not recording"]))
                    return
                }

                self.audioRecorder.pause()
                continuation.resume()
            }
        }
    }

    func resumeRecorder() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if (self.audioRecorder == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recorder is nil"]))
                    return
                }

                self.audioRecorder.record()

                if (self.recordTimer == nil) {
                    self.startRecorderTimer()
                }
                continuation.resume()
            }
        }
    }

    func setSubscriptionDuration(duration: Double) -> Void {
        subscriptionDuration = duration
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
            break
        case AVAudioSession.InterruptionType.ended.rawValue:
            Task {
                try? await resumeRecorder()
            }
            break
        default:
            break
        }
    }

    /**********               Player               **********/

    @discardableResult
    func startRecorder(path: String, audioSets: [String: Any], meteringEnabled: Bool) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            _meteringEnabled = meteringEnabled;

            let encoding = audioSets["AVFormatIDKeyIOS"] as? String
            let mode = audioSets["AVModeIOS"] as? String
            let avLPCMBitDepth = audioSets["AVLinearPCMBitDepthKeyIOS"] as? Int
            let avLPCMIsBigEndian = audioSets["AVLinearPCMIsBigEndianKeyIOS"] as? Bool
            let avLPCMIsFloatKey = audioSets["AVLinearPCMIsFloatKeyIOS"] as? Bool
            let avLPCMIsNonInterleaved = audioSets["AVLinearPCMIsNonInterleavedIOS"] as? Bool

            var avMode: AVAudioSession.Mode = AVAudioSession.Mode.default
            var sampleRate = audioSets["AVSampleRateKeyIOS"] as? Int
            var numberOfChannel = audioSets["AVNumberOfChannelsKeyIOS"] as? Int
            var audioQuality = audioSets["AVEncoderAudioQualityKeyIOS"] as? Int
            var bitRate = audioSets["AVEncoderBitRateKeyIOS"] as? Int

            if (sampleRate == nil) {
                sampleRate = 44100;
            }

            guard let avFormat: AudioFormatID = avFormat(fromString: encoding) else {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Audio format not available"]))
                return
            }

            if (path == "DEFAULT") {
                let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let fileExt = fileExtension(forAudioFormat: avFormat)
                audioFileURL = cachesDirectory.appendingPathComponent("sound." + fileExt)
            } else {
                setAudioFileURL(path: path)
            }

            if (mode == "measurement") {
                avMode = AVAudioSession.Mode.measurement
            } else if (mode == "gamechat") {
                avMode = AVAudioSession.Mode.gameChat
            } else if (mode == "movieplayback") {
                avMode = AVAudioSession.Mode.moviePlayback
            } else if (mode == "spokenaudio") {
                avMode = AVAudioSession.Mode.spokenAudio
            } else if (mode == "videochat") {
                avMode = AVAudioSession.Mode.videoChat
            } else if (mode == "videorecording") {
                avMode = AVAudioSession.Mode.videoRecording
            } else if (mode == "voicechat") {
                avMode = AVAudioSession.Mode.voiceChat
            } else if (mode == "voiceprompt") {
                avMode = AVAudioSession.Mode.voicePrompt
            }


            if (numberOfChannel == nil) {
                numberOfChannel = 2
            }

            if (audioQuality == nil) {
                audioQuality = AVAudioQuality.medium.rawValue
            }

            if (bitRate == nil) {
                bitRate = 128000
            }

            func startRecording() {
                let settings = [
                    AVSampleRateKey: sampleRate!,
                    AVFormatIDKey: avFormat,
                    AVNumberOfChannelsKey: numberOfChannel!,
                    AVEncoderAudioQualityKey: audioQuality!,
                    AVLinearPCMBitDepthKey: avLPCMBitDepth ?? AVLinearPCMBitDepthKey.count,
                    AVLinearPCMIsBigEndianKey: avLPCMIsBigEndian ?? true,
                    AVLinearPCMIsFloatKey: avLPCMIsFloatKey ?? false,
                    AVLinearPCMIsNonInterleaved: avLPCMIsNonInterleaved ?? false,
                     AVEncoderBitRateKey: bitRate!
                ] as [String : Any]

                do {
                    audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)

                    if (audioRecorder != nil) {
                        audioRecorder.prepareToRecord()
                        audioRecorder.delegate = self
                        audioRecorder.isMeteringEnabled = _meteringEnabled
                        let isRecordStarted = audioRecorder.record()

                        if !isRecordStarted {
                            continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error occured during initiating recorder"]))
                            return
                        }

                        startRecorderTimer()

                        continuation.resume(returning: audioFileURL?.absoluteString ?? "")
                        return
                    }

                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error occured during initiating recorder"]))
                } catch {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                }
            }

            audioSession = AVAudioSession.sharedInstance()

            do {
                try audioSession.setCategory(.playAndRecord, mode: avMode, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetooth])
                try audioSession.setActive(true)

                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted {
                            startRecording()
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

    @discardableResult
    func stopRecorder() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if (recordTimer != nil) {
                recordTimer!.invalidate()
                recordTimer = nil
            }

            DispatchQueue.main.async {
                if (self.audioRecorder == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to stop recorder. It is already nil."]))
                    return
                }

                self.audioRecorder.stop()

                continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
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
                                                                queue: .main) {_ in
            if (self.audioPlayer != nil) {
                self.playBackListener?([
                    "isMuted": self.audioPlayer.isMuted,
                    "currentPosition": self.audioPlayerItem.currentTime().seconds * 1000,
                    "duration": self.audioPlayerItem.asset.duration.seconds * 1000,
                    "isFinished": false,
                ])
            }
        }
    }

    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    @discardableResult
    func startPlayer(
        path: String,
        httpHeaders: [String: String]
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            audioSession = AVAudioSession.sharedInstance()

            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetooth])
                try audioSession.setActive(true)
            } catch {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                return
            }

            setAudioFileURL(path: path)
            audioPlayerAsset = AVURLAsset(url: audioFileURL!, options:["AVURLAssetHTTPHeaderFieldsKey": httpHeaders])
            audioPlayerItem = AVPlayerItem(asset: audioPlayerAsset!)

            if (audioPlayer == nil) {
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
            let duration = playerItem.duration.seconds * 1000
            self.playBackListener?([
                "isMuted": self.audioPlayer?.isMuted as Any,
                "currentPosition": duration,
                "duration": duration,
                "isFinished": true,
            ])
        }
    }

    @discardableResult
    func stopPlayer() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if (self.audioPlayer == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player has already stopped."]))
                    return
                }
                
                self.audioPlayer.pause()
                self.removePeriodicTimeObserver()
                self.audioPlayer = nil;

                continuation.resume(returning: self.audioFileURL?.absoluteString ?? "")
            }
        }
    }

    func pausePlayer() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if (self.audioPlayer == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is not playing"]))
                    return
                }
                
                self.audioPlayer.pause()
                continuation.resume()
            }
        }
    }

    func resumePlayer() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if (self.audioPlayer == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                    return
                }
                
                self.audioPlayer.play()
                continuation.resume()
            }
        }
    }

    func seekToPlayer(time: Double) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if (self.audioPlayer == nil) {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                return
            }
            
            audioPlayer.seek(to: CMTime(seconds: time / 1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            continuation.resume()
        }
    }

    func setVolume(volume: Float) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if (self.audioPlayer == nil) {
                continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                return
            }
            
            self.audioPlayer.volume = volume
            continuation.resume()
        }
    }

    func setPlaybackSpeed(playbackSpeed: Float) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.fw.mainAsync {
                if (self.audioPlayer == nil) {
                    continuation.resume(throwing: NSError(domain: "AudioPlayerRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Player is null"]))
                    return
                }
                
                self.audioPlayer.rate = playbackSpeed
                continuation.resume()
            }
        }
    }

    private func avFormat(fromString encoding: String?) -> AudioFormatID? {
        if (encoding == nil) {
            return kAudioFormatAppleLossless
        } else {
            if (encoding == "lpcm") {
                return kAudioFormatAppleIMA4
            } else if (encoding == "ima4") {
                return kAudioFormatAppleIMA4
            } else if (encoding == "aac") {
                return kAudioFormatMPEG4AAC
            } else if (encoding == "MAC3") {
                return kAudioFormatMACE3
            } else if (encoding == "MAC6") {
                return kAudioFormatMACE6
            } else if (encoding == "ulaw") {
                return kAudioFormatULaw
            } else if (encoding == "alaw") {
                return kAudioFormatALaw
            } else if (encoding == "mp1") {
                return kAudioFormatMPEGLayer1
            } else if (encoding == "mp2") {
                return kAudioFormatMPEGLayer2
            } else if (encoding == "mp4") {
                return kAudioFormatMPEG4AAC
            } else if (encoding == "alac") {
                return kAudioFormatAppleLossless
            } else if (encoding == "amr") {
                return kAudioFormatAMR
            } else if (encoding == "flac") {
                return kAudioFormatFLAC
            } else if (encoding == "opus") {
                return kAudioFormatOpus
            } else if (encoding == "wav") {
                return kAudioFormatLinearPCM
            }
        }
        return nil;
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
