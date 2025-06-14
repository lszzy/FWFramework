//
//  TestRecorderController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2025/6/14.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestRecorderController: UIViewController {
    class State {
        var recordSecs: Double = 0
        var recordTime: String = "00:00:00"
        var currentPosition: Double = 0
        var currentDuration: Double = 0
        var playTime: String = "00:00:00"
        var duration: String = "00:00:00"
    }
    
    // MARK: - Accessor
    private var state = State()
    
    private lazy var recorder: AudioRecorderPlayer = {
        let result = AudioRecorderPlayer()
        result.subscriptionDuration = 0.1
        return result
    }()

    // MARK: - Subviews
    private lazy var audioImage: UIImageView = {
        let result = UIImageView()
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] _ in
            self?.toggleAudio()
        }
        return result
    }()

    private lazy var previousImage: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        result.image = APP.iconImage("zmdi-var-skip-previous", 100)
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] _ in
            self?.playPrevious()
        }
        return result
    }()

    private lazy var nextImage: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        result.image = APP.iconImage("zmdi-var-skip-next", 100)
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] _ in
            self?.playNext()
        }
        return result
    }()

    private lazy var audioLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
}

extension TestRecorderController: ViewControllerProtocol {
    func setupNavbar() {
        
    }

    func setupSubviews() {
        view.addSubview(audioImage)
        view.addSubview(previousImage)
        view.addSubview(nextImage)
        view.addSubview(audioLabel)
    }

    func setupLayout() {
        audioImage.app.layoutChain.centerX().size(CGSize(width: 100, height: 100))
            .centerY(toView: view as Any, offset: -58)
        audioLabel.app.layoutChain.centerX().attribute(.top, toAttribute: .centerY, ofView: view, offset: 8)

        let margin = (APP.screenWidth - 100.0 * 3) / 4.0
        previousImage.layoutChain.centerY(toView: audioImage).right(toViewLeft: audioImage, offset: -margin).size(CGSize(width: 100, height: 100))
        nextImage.layoutChain.centerY(toView: audioImage).left(toViewRight: audioImage, offset: margin).size(CGSize(width: 100, height: 100))

        audioPlayer.delegate = self
        audioPlayer.dataSource = self
        audioPlayer.observePeriodicTime = true
        audioPlayer.playItem(from: 0)
        renderData()
    }
    
    func updateState() {
        
    }
}

extension TestRecorderController {
    func onStartRecord() {
        
    }
    
    func onPauseRecord() {
        Task {
            do {
                try await recorder.pauseRecorder()
            } catch {
                self.app.showMessage(error: error)
            }
        }
    }
    
    func onResumeRecord() {
        Task {
            do {
                try await recorder.resumeRecorder()
            } catch {
                self.app.showMessage(error: error)
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
                self.app.showMessage(error: error)
            }
        }
    }
    
    func onStatusPress() {
        
    }
    
    func onStartPlay() {
        Task {
            do {
                let path = try await recorder.startPlayer()
                let volume = try await recorder.setVolume(1.0)
                Logger.debug("path: %@ volumn: %@", path ?? "", "\(volume)")
            } catch {
                self.app.showMessage(error: error)
            }
        }
    }
    
    func onPausePlay() {
        Task {
            do {
                try await recorder.pausePlayer()
            } catch {
                self.app.showMessage(error: error)
            }
        }
    }
    
    func onResumePlay() {
        Task {
            do {
                try await recorder.resumePlayer()
            } catch {
                self.app.showMessage(error: error)
            }
        }
    }
    
    func onStopPlay() {
        Task {
            do {
                try await recorder.stopPlayer()
                recorder.playBackListener = nil
            } catch {
                self.app.showMessage(error: error)
            }
        }
    }
}
