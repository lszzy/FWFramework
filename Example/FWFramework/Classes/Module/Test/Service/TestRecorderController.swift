//
//  TestRecorderController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2025/6/14.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import AVFoundation
import FWFramework
import Speech

class TestRecorderController: UIViewController {
    class State {
        var recordSecs: Double = 0
        var recordTime: String = "00:00:00"
        var currentPosition: Double = 0
        var currentDuration: Double = 0
        var playTime: String = "00:00:00"
        var duration: String = "00:00:00"
        var recognizeText: String = ""
    }

    // MARK: - Accessor
    private var state = State()

    private lazy var recorder: AudioRecorder = {
        let result = AudioRecorder()
        result.subscriptionDuration = 0.1
        return result
    }()

    private var locale: Locale = .current
    private var task: Task<Void, Never>?

    // MARK: - Subviews
    private lazy var recordTimeLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        return result
    }()

    private lazy var recordButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Record", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStartRecord()
        }
        return result
    }()

    private lazy var pauseButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Pause", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onPauseRecord()
        }
        return result
    }()

    private lazy var resumeButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Resume", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onResumeRecord()
        }
        return result
    }()

    private lazy var stopButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Stop", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStopRecord()
        }
        return result
    }()

    private lazy var progressView: UIProgressView = {
        let result = UIProgressView()
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] gesture in
            self?.onStatusPress(gesture)
        }
        return result
    }()

    private lazy var playTimeLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        return result
    }()

    private lazy var playButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Play", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStartPlay()
        }
        return result
    }()

    private lazy var pausePlayButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Pause", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onPausePlay()
        }
        return result
    }()

    private lazy var resumePlayButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Resume", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onResumePlay()
        }
        return result
    }()

    private lazy var stopPlayButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Stop", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStopPlay()
        }
        return result
    }()

    private lazy var recognizeLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    private lazy var recognizeButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Recognize", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStartRecognizer()
        }
        return result
    }()

    private lazy var stopRecognizeButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Stop", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onStopRecognizer()
        }
        return result
    }()

    private lazy var localeButton: UIButton = {
        let result = UIButton()
        result.app.setBorderColor(AppTheme.textColor, width: 1, cornerRadius: 8)
        result.app.setTitle("Locale", font: UIFont.app.font(ofSize: 15), titleColor: AppTheme.textColor)
        result.app.addTouch { [weak self] _ in
            self?.onChooseLocale()
        }
        return result
    }()
}

extension TestRecorderController: ViewControllerProtocol {
    func setupNavbar() {}

    func setupSubviews() {
        view.addSubview(recordTimeLabel)
        view.addSubview(recordButton)
        view.addSubview(pauseButton)
        view.addSubview(resumeButton)
        view.addSubview(stopButton)
        view.addSubview(progressView)
        view.addSubview(playTimeLabel)
        view.addSubview(playButton)
        view.addSubview(pausePlayButton)
        view.addSubview(resumePlayButton)
        view.addSubview(stopPlayButton)
        view.addSubview(recognizeLabel)
        view.addSubview(recognizeButton)
        view.addSubview(stopRecognizeButton)
        view.addSubview(localeButton)
    }

    func setupLayout() {
        recordTimeLabel.layoutChain
            .centerX()
            .top(toSafeArea: 50)

        recordButton.layoutChain
            .left(20)
            .top(toViewBottom: recordTimeLabel, offset: 30)
            .size(width: 60, height: 24)

        pauseButton.layoutChain
            .centerY(toView: recordButton)
            .size(toView: recordButton)
            .left(toViewRight: recordButton, offset: 20)

        resumeButton.layoutChain
            .centerY(toView: recordButton)
            .size(toView: recordButton)
            .left(toViewRight: pauseButton, offset: 20)

        stopButton.layoutChain
            .centerY(toView: recordButton)
            .size(toView: recordButton)
            .left(toViewRight: resumeButton, offset: 20)

        progressView.layoutChain
            .horizontal(28)
            .top(toViewBottom: recordButton, offset: 50)
            .height(5)

        playTimeLabel.layoutChain
            .centerX()
            .top(toViewBottom: progressView, offset: 20)

        playButton.layoutChain
            .left(20)
            .top(toViewBottom: playTimeLabel, offset: 30)
            .size(width: 60, height: 24)

        pausePlayButton.layoutChain
            .centerY(toView: playButton)
            .size(toView: playButton)
            .left(toViewRight: playButton, offset: 20)

        resumePlayButton.layoutChain
            .centerY(toView: playButton)
            .size(toView: playButton)
            .left(toViewRight: pausePlayButton, offset: 20)

        stopPlayButton.layoutChain
            .centerY(toView: playButton)
            .size(toView: playButton)
            .left(toViewRight: resumePlayButton, offset: 20)

        recognizeLabel.layoutChain
            .horizontal(16)
            .top(toViewBottom: playButton, offset: 50)

        recognizeButton.layoutChain
            .left(20)
            .top(toViewBottom: recognizeLabel, offset: 30)
            .size(width: 280 / 3.0, height: 24)

        stopRecognizeButton.layoutChain
            .centerY(toView: recognizeButton)
            .size(toView: recognizeButton)
            .left(toViewRight: recognizeButton, offset: 20)

        localeButton.layoutChain
            .centerY(toView: recognizeButton)
            .size(toView: recognizeButton)
            .left(toViewRight: stopRecognizeButton, offset: 20)

        updateState()
    }

    func updateState() {
        recordTimeLabel.text = state.recordTime
        progressView.setProgress(state.currentDuration > 0 ? Float(state.currentPosition / state.currentDuration) : 0, animated: true)
        playTimeLabel.text = "\(state.playTime) / \(state.duration)"
        recognizeLabel.text = state.recognizeText.isNotEmpty ? state.recognizeText : "-"
        localeButton.setTitle(locale.localizedString(forLanguageCode: locale.languageCode ?? ""), for: .normal)
    }
}

extension TestRecorderController {
    func onStartRecord() {
        Task {
            do {
                var audioSettings = AudioRecorder.AudioSettings()
                audioSettings.encoderAudioQuality = .high
                audioSettings.numberOfChannels = 2
                audioSettings.formatID = kAudioFormatMPEG4AAC

                let uri = try await recorder.startRecorder(audioSettings: audioSettings)
                recorder.recordBackListener = { [weak self] event in
                    guard let self else { return }
                    state.recordSecs = event.currentPosition
                    state.recordTime = recorder.formatDuration(event.currentPosition, hasMilliseconds: true)
                    updateState()
                }
                Logger.debug("uri: %@", uri ?? "")
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onPauseRecord() {
        Task {
            do {
                try await recorder.pauseRecorder()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onResumeRecord() {
        Task {
            do {
                try await recorder.resumeRecorder()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onStopRecord() {
        Task {
            do {
                try await recorder.stopRecorder()
                recorder.recordBackListener = nil
                self.state.recordSecs = 0
                self.updateState()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onStatusPress(_ gesture: UITapGestureRecognizer) {
        let touchProgress = gesture.location(in: progressView).x / progressView.frame.width
        Task {
            do {
                guard state.currentDuration > 0 else { return }
                try await recorder.seekToPlayer(state.currentDuration * touchProgress)
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onStartPlay() {
        Task {
            do {
                let path = try await recorder.startPlayer()
                let volume = try await recorder.setVolume(1.0)
                Logger.debug("path: %@ volumn: %@", path ?? "", "\(volume)")

                recorder.playBackListener = { [weak self] event in
                    guard let self else { return }
                    state.currentPosition = event.currentPosition
                    state.currentDuration = event.duration
                    state.playTime = recorder.formatDuration(event.currentPosition, hasMilliseconds: true)
                    state.duration = recorder.formatDuration(event.duration, hasMilliseconds: true)
                    updateState()
                }
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onPausePlay() {
        Task {
            do {
                try await recorder.pausePlayer()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onResumePlay() {
        Task {
            do {
                try await recorder.resumePlayer()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onStopPlay() {
        Task {
            do {
                try await recorder.stopPlayer()
                recorder.playBackListener = nil
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func onStartRecognizer() {
        task = Task {
            do {
                state.recognizeText = "Recognizing..."
                updateState()
                let result = try await recorder.startRecognizer(locale: locale)
                state.recognizeText = result ?? ""
                updateState()
            } catch {
                state.recognizeText = ""
                updateState()
                if task != nil {
                    await self.app.showMessage(error: error)
                }
            }
        }
    }

    func onStopRecognizer() {
        task?.cancel()
        task = nil
        state.recognizeText = ""
        updateState()
    }

    func onChooseLocale() {
        let locales = Array(SFSpeechRecognizer.supportedLocales())
        app.showSheet(title: nil, message: nil, actions: locales.map {
            $0.localizedString(forLanguageCode: $0.languageCode ?? "") ?? ""
        }, actionBlock: { [weak self] index in
            self?.locale = locales[index]
            self?.updateState()
        })
    }
}
