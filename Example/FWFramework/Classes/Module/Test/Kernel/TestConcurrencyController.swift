//
//  TestConcurrencyController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestConcurrencyController: UIViewController, TableViewControllerProtocol {
    typealias TableElement = [String]

    func setupTableStyle() -> UITableView.Style {
        .grouped
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        _ = perform(NSSelectorFromString(rowData[1]))
    }

    func setupSubviews() {
        tableData.append(contentsOf: [
            ["Promise(Success)", "onPromiseSuccess"],
            ["Promise(Failure)", "onPromiseFailure"],
            ["Download(Success)", "onDownloadSuccess"],
            ["Download(Failure)", "onDownloadFailure"],
            ["Download(Cancel)", "onDownloadCancel"],
            ["Request(Success)", "onRequestSuccess"],
            ["Request(Failure)", "onRequestFailure"],
            ["Request(Cancel)", "onRequestCancel"],
            ["Request(Clear)", "onRequestClear"],
            ["Authorize(Location)", "onAuthorizeLocation"],
            ["Authorize(Biometry)", "onAuthorizeBiometry"],
            ["Toolkit(Safari)", "onToolkitSafari"],
            ["Toolkit(App)", "onToolkitApp"]
        ])
    }
}

extension TestConcurrencyController {
    @objc func onPromiseSuccess() {
        app.showLoading()

        Task.init {
            let promise = Promise.delay(1).then { (_: Sendable) in
                "Promise succeed"
            }

            do {
                let result: String = try await promise.value()
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(text: result)
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(error: error)
                }
            }
        }
    }

    @objc func onPromiseFailure() {
        app.showLoading()

        Task.init {
            let promise = Promise.delay(1).then { (_: Sendable) in
                throw PromiseError.failed
            }

            do {
                let result: String = try await promise.value()
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(text: result)
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(error: error)
                }
            }
        }
    }

    @objc func onDownloadSuccess() {
        app.showLoading()

        Task.init {
            let url = "https://up.enterdesk.com/edpic_source/b0/d1/f3/b0d1f35504e4106d48c84434f2298ada.jpg?t=\(Date.app.currentTime)"

            do {
                let image = try await UIImage.app.downloadImage(url)
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showImagePreview(imageURLs: [image])
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(error: error)
                }
            }
        }
    }

    @objc func onDownloadFailure() {
        app.showLoading()

        Task.init {
            let url = "https://up.enterdesk.com/edpic_source/b0/d1/f3/b0d1f35504e4106d48c84434f2298ada_404.jpg?t=\(Date.app.currentTime)"

            do {
                let image = try await UIImage.app.downloadImage(url)
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showImagePreview(imageURLs: [image])
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(error: error)
                }
            }
        }
    }

    @objc func onDownloadCancel() {
        app.showLoading()

        let task = Task.init {
            let url = "https://up.enterdesk.com/edpic_source/b0/d1/f3/b0d1f35504e4106d48c84434f2298ada.jpg?t=\(Date.app.currentTime)"

            do {
                try Task.checkCancellation()

                let image = try await UIImage.app.downloadImage(url)
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showImagePreview(imageURLs: [image])
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.hideLoading()
                    self.app.showMessage(error: error)
                }
            }
        }
        task.cancel()
    }

    @objc func onRequestSuccess() {
        Task.init {
            let request = TestModelRequest()
            request.context = self
            request.autoShowLoading = true
            request.autoShowError = true

            let result = try await request.safeResponseModel()
            DispatchQueue.app.mainAsync {
                self.app.showMessage(text: result.name)
            }
        }
    }

    @objc func onRequestFailure() {
        Task.init {
            let request = TestModelRequest()
            request.context = self
            request.autoShowLoading = true
            request.autoShowError = true
            request.testFailed = true

            let result = await request.response()
            DispatchQueue.app.mainAsync {
                if result.error == nil {
                    self.app.showMessage(text: result.safeResponseModel.name)
                }
            }
        }
    }

    @objc func onRequestCancel() {
        let task = Task.init {
            let request = TestModelRequest()
            request.context = self
            request.autoShowLoading = true

            do {
                try Task.checkCancellation()

                let result = try await request.responseSuccess()
                DispatchQueue.app.mainAsync {
                    self.app.showMessage(text: result.safeResponseModel.name)
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.showMessage(error: error)
                }
            }
        }
        task.cancel()
    }

    @objc func onRequestClear() {
        Task {
            let request = TestModelRequest()
            request.context = self
            request.autoShowLoading = true

            let accessory = RequestAccessory()
            accessory.willStartBlock = { _ in
                RequestManager.shared.cancelAllRequests()
            }
            request.addAccessory(accessory)

            do {
                let result = try await request.responseSuccess()
                DispatchQueue.app.mainAsync {
                    self.app.showMessage(text: result.safeResponseModel.name)
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    self.app.showMessage(error: error)
                }
            }
        }
    }

    @objc func onAuthorizeLocation() {
        Task {
            let result = await AuthorizeLocation.shared.requestAuthorize()
            DispatchQueue.app.mainAsync {
                switch result.status {
                case .authorized:
                    self.app.showMessage(text: "GPS已开启")
                case .denied:
                    self.app.showMessage(text: "GPS已关闭")
                case .restricted:
                    self.app.showMessage(text: "GPS受限制")
                case .notDetermined:
                    self.app.showMessage(text: "GPS未检测")
                }
            }
        }
    }

    @objc func onAuthorizeBiometry() {
        Task {
            let result = await AuthorizeBiometry.shared.requestAuthorize()
            DispatchQueue.app.mainAsync {
                switch result.status {
                case .authorized:
                    self.app.showMessage(text: "验证成功")
                case .denied:
                    self.app.showAlert(title: "验证失败", message: result.error?.localizedDescription)
                case .restricted:
                    self.app.showAlert(title: "验证受限制", message: result.error?.localizedDescription)
                case .notDetermined:
                    self.app.showAlert(title: "身份未验证", message: result.error?.localizedDescription)
                }
            }
        }
    }

    @objc func onToolkitSafari() {
        Task {
            let success = await UIApplication.app.openURL("https://www.baidu.com")
            DispatchQueue.app.mainAsync {
                self.app.showAlert(title: success ? "打开Safari成功" : "打开Safari失败", message: nil)
            }
        }
    }

    @objc func onToolkitApp() {
        Task {
            let success = await UIApplication.app.openUniversalLinks("https://v.douyin.com/JYmHJ9k/")
            DispatchQueue.app.mainAsync {
                self.app.showAlert(title: success ? "打开App成功" : "打开App失败", message: nil)
            }
        }
    }
}
