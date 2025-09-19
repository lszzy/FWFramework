//
//  TestCloudController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

struct TestCloudTimeModel: SmartModel, AnyArchivable {
    var value: Double = 0
}

class TestCloudModel: ObservableObject {
    @CloudStorage(TestCloudController.cloudKeyName)
    var testCloudTime: TestCloudTimeModel = .init()
}

class TestCloudController: UIViewController {
    private var cloudModel = TestCloudModel()

    fileprivate static let cloudKeyName = "testCloudTime"
    fileprivate static let cloudFileName = "testCloudTime.txt"

    private lazy var timeLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.textAlignment = .center
        return result
    }()

    private lazy var readKeyButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("读取iCloud数据", for: .normal)
        result.app.addTouch { [weak self] _ in
            self?.refreshCloud()
        }
        return result
    }()

    private lazy var writeKeyButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("写入iCloud数据", for: .normal)
        result.app.addTouch { [weak self] _ in
            self?.cloudModel.testCloudTime = TestCloudTimeModel(value: Date.app.currentTime)
            self?.refreshCloud()
        }
        return result
    }()

    private lazy var removeKeyButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("删除iCloud数据", for: .normal)
        result.app.addTouch { [weak self] _ in
            CloudStorageSync.shared.remove(for: Self.cloudKeyName)
            self?.refreshCloud()
        }
        return result
    }()

    private lazy var readFileButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("读取iCloud文件", for: .normal)
        result.app.addTouch { [weak self] _ in
            self?.refreshCloud()
        }
        return result
    }()

    private lazy var writeFileButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("写入iCloud文件", for: .normal)
        result.app.addTouch { [weak self] _ in
            Task {
                do {
                    let cloudDrive = try await CloudDrive()
                    let timeData = Date().app.stringValue.data(using: .utf8)!
                    try await cloudDrive.writeFile(with: timeData, at: .root.appending(Self.cloudFileName))
                    self?.refreshCloud()
                } catch {
                    await self?.app.showMessage(error: error)
                }
            }
        }
        return result
    }()

    private lazy var removeFileButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("删除iCloud文件", for: .normal)
        result.app.addTouch { [weak self] _ in
            Task {
                do {
                    let cloudDrive = try await CloudDrive()
                    let fileExists = try await cloudDrive.fileExists(at: .root.appending(Self.cloudFileName))
                    if fileExists {
                        try await cloudDrive.removeFile(at: .root.appending(Self.cloudFileName))
                    }
                    self?.refreshCloud()
                } catch {
                    await self?.app.showMessage(error: error)
                }
            }
        }
        return result
    }()
}

extension TestCloudController: ViewControllerProtocol {
    func setupSubviews() {
        view.addSubview(timeLabel)
        view.addSubview(readKeyButton)
        view.addSubview(writeKeyButton)
        view.addSubview(removeKeyButton)
        view.addSubview(readFileButton)
        view.addSubview(writeFileButton)
        view.addSubview(removeFileButton)
    }

    func setupLayout() {
        timeLabel.app.layoutChain
            .horizontal(10)
            .top(toSafeArea: 10)

        readKeyButton.app.layoutChain
            .top(toViewBottom: timeLabel, offset: 10)
            .centerX()

        writeKeyButton.app.layoutChain
            .top(toViewBottom: readKeyButton, offset: 10)
            .centerX()

        removeKeyButton.app.layoutChain
            .top(toViewBottom: writeKeyButton, offset: 10)
            .centerX()

        readFileButton.app.layoutChain
            .top(toViewBottom: removeKeyButton, offset: 10)
            .centerX()

        writeFileButton.app.layoutChain
            .top(toViewBottom: readFileButton, offset: 10)
            .centerX()

        removeFileButton.app.layoutChain
            .top(toViewBottom: writeFileButton, offset: 10)
            .centerX()

        refreshCloud()
    }
}

extension TestCloudController {
    func refreshCloud() {
        Task {
            var statusStr = "iCloud数据：\n"
            if cloudModel.testCloudTime.value > 0 {
                statusStr += Date(timeIntervalSince1970: cloudModel.testCloudTime.value).app.stringValue
            } else {
                statusStr += "不存在"
            }

            statusStr += "\niCloud文件：\n"
            do {
                let cloudDrive = try await CloudDrive()
                let fileExists = try await cloudDrive.fileExists(at: .root.appending(Self.cloudFileName))
                if fileExists {
                    let timeData = try await cloudDrive.readFile(at: .root.appending(Self.cloudFileName))
                    let timeString = String(data: timeData, encoding: .utf8)
                    statusStr += timeString ?? ""
                } else {
                    statusStr += "不存在"
                }
            } catch {
                statusStr += error.localizedDescription
            }
            timeLabel.text = statusStr.app.trimString
        }
    }
}
