//
//  TestPromiseController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPromiseController: UIViewController, TableViewControllerProtocol {
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
            ["safe", "onSafe"],
            ["-done", "onDone"],
            ["-then", "onThen"],
            ["-delay", "onDelay"],
            ["-validate", "onValidate"],
            ["-timeout", "onTimeout"],
            ["-recover", "onRecover"],
            ["-reduce", "onReduce"],
            ["-retry", "onRetry"],
            ["-progress", "onProgress"],
            ["+await", "onAwait"],
            ["+all", "onAll"],
            ["+any", "onAny"],
            ["+race", "onRace"],
            ["+retry", "onRetry2"],
            ["+progress", "onProgress2"]
        ])
    }
}

extension TestPromiseController {
    private static func successPromise(_ value: Int = 0) -> Promise {
        Promise { resolve, _ in
            Promise.delay(1).done { _ in
                resolve(value + 1)
            }
        }
    }

    private static func failurePromise() -> Promise {
        Promise { completion in
            Promise.delay(1).done { _ in
                completion(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test failed"]))
            }
        }
    }

    private static func randomPromise(_ value: Int = 0) -> Promise {
        [0, 1].randomElement() == 1 ? successPromise(value) : failurePromise()
    }

    private static func progressPromise() -> Promise {
        Promise { resolve, reject, progress in
            DispatchQueue.global().async {
                let value = SendableObject<Double>(0)
                while value.object < 1 {
                    value.object += 0.02
                    let finish = value.object >= 1
                    DispatchQueue.main.async {
                        if finish {
                            progress(1)
                            if [0, 1, 2].randomElement() == 0 {
                                reject(Promise.failedError)
                            } else {
                                resolve(UIImage())
                            }
                        } else {
                            progress(value.object)
                        }
                    }
                    usleep(50_000)
                }
            }
        }
    }

    private static func showMessage(_ text: String) {
        UIWindow.app.showMessage(text: text)
    }

    private static var isLoading: Bool = false {
        didSet {
            if isLoading {
                UIWindow.app.showLoading()
            } else {
                UIWindow.app.hideLoading()
            }
        }
    }

    @objc func onSafe() {
        Self.isLoading = true
        var value = 0
        let index = [1, 2].randomElement()!
        if index == 1 {
            let values = SendableObject<[Int]>([])
            let semaphore = DispatchSemaphore(value: 1)
            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                semaphore.wait()
                let last = values.object.last ?? 0
                values.object.append(last + 1)
                semaphore.signal()
            }
            value = values.object.last.safeInt
        } else {
            let values = SendableObject<[Int]>([])
            let queue = DispatchQueue(label: "serial")
            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                queue.async {
                    let last = values.object.last ?? 0
                    values.object.append(last + 1)
                }
            }
            queue.sync {
                value = values.object.last.safeInt
            }
        }
        Self.isLoading = false
        Self.showMessage("\(index).result: \(value)")
    }

    @objc func onDone() {
        Self.isLoading = true
        var value = 0
        Promise { completion in
            for i in 0..<10_000 {
                Self.successPromise(i).done { _ in
                    value += 1
                    completion(value)
                }
            }
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onThen() {
        Self.isLoading = true
        Self.successPromise().then { (value: Int) in
            Self.successPromise(value)
        }.then { (value: Int) in
            value + 1
        }.done({ (value: Int) in
            Self.showMessage("done: 3 => \(value)")
        }, catch: { error in
            Self.showMessage("error: \(error)")
        }, finally: {
            Self.isLoading = false
        })
    }

    @objc func onAwait() {
        Self.isLoading = true
        Task {
            do {
                var value: Int = try await Self.successPromise().value()
                value = try await Self.successPromise(value).value()

                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("value: 2 => \(value)")
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("error: \(error)")
                }
            }
        }
    }

    @objc func onAll() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0..<10_000 {
            promises.append(i < 9999 ? Self.successPromise() : Self.randomPromise())
        }
        Task {
            do {
                let result: Int = try await Promise.all(promises).then { (values: [Sendable]) in
                    values.count
                }.value()

                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("result: \(result)")
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("error: \(error)")
                }
            }
        }
    }

    @objc func onAny() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0..<10_000 {
            promises.append(i < 5000 ? Self.failurePromise() : Self.randomPromise(i))
        }
        Task {
            do {
                let result: Int = try await Promise.any(promises).value()

                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("result: \(result)")
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("error: \(error)")
                }
            }
        }
    }

    @objc func onRace() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0..<10_000 {
            promises.append(Self.randomPromise(i))
        }
        Task {
            do {
                let result: Int = try await Promise.race(promises.shuffled()).value()

                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("result: \(result)")
                }
            } catch {
                DispatchQueue.app.mainAsync {
                    Self.isLoading = false
                    Self.showMessage("error: \(error)")
                }
            }
        }
    }

    @objc func onDelay() {
        Self.isLoading = true
        Self.randomPromise().then { value in
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "delay")
            }
            return value
        }.delay(1).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onValidate() {
        Self.isLoading = true
        Self.randomPromise([0, 1].randomElement()!).validate { (value: Int) in
            value > 1
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onTimeout() {
        Self.isLoading = true
        let delayTime: TimeInterval = [0, 1].randomElement() == 1 ? 4 : 1
        Self.randomPromise().delay(delayTime).timeout(3).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onRecover() {
        Self.isLoading = true
        Self.failurePromise().recover { error in
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "\(error)")
            }
            return 1
        }.delay(1).then { (value: Int) in
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "\(value)")
            }
            return Self.successPromise(value)
        }.validate { (_: Int) in
            false
        }.recover { error in
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "\(error)")
            }
            return Self.successPromise()
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onReduce() {
        Self.isLoading = true
        Self.randomPromise().reduce([2, 3, 4, 5]) { value, item in
            "\(value),\(item)"
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result)")
        }
    }

    @objc func onRetry() {
        Self.isLoading = true
        let startTime = Date.app.currentTime
        var count = 0
        Self.failurePromise().recover { $0 }.retry(4, delay: 0) {
            count += 1
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "retry: \(count)")
            }
            if count < 4 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = Date.app.currentTime
            Self.showMessage("result: \(result) => " + String(format: "%.1fs", endTime - startTime))
        }
    }

    @objc func onRetry2() {
        Self.isLoading = true
        let startTime = Date.app.currentTime
        var count = 0
        Promise.retry(4, delay: 0) {
            count += 1
            if count == 1 { return Self.failurePromise() }
            DispatchQueue.main.async {
                UIWindow.app.showLoading(text: "retry: \(count - 1)")
            }
            if count < 5 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count - 1)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = Date.app.currentTime
            Self.showMessage("result: \(result) => " + String(format: "%.1fs", endTime - startTime))
        }
    }

    @objc func onProgress() {
        var promise: Promise?
        let index = [1, 2, 3].randomElement()!
        if index == 1 {
            promise = Self.progressPromise().then { (_: Sendable) in
                Self.successPromise()
            }
        } else if index == 2 {
            promise = Self.successPromise().then { (_: Sendable) in
                Self.progressPromise()
            }
        } else {
            promise = Self.failurePromise().recover { _ in
                Self.progressPromise()
            }
        }
        UIWindow.app.showProgress(0, text: String(format: "\(index)下载中(%.0f%%)", 0 * 100))
        promise?.validate { (_: Sendable) in
            false
        }.recover { _ in
            Promise(value: "\(index)下载成功")
        }.reduce([1, 2], reducer: { value, _ in
            value
        }).delay(1).timeout(30).retry(1, delay: 0, block: {
            Self.successPromise()
        }).done({ (value: Sendable) in
            Self.showMessage("\(value)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.app.showProgress(CGFloat(progress), text: String(format: "\(index)下载中(%.0f%%)", progress * 100))
        }, finally: {
            UIWindow.app.hideProgress()
        })
    }

    @objc func onProgress2() {
        let promises = [Self.progressPromise(),
                        Promise.delay(0.5).then { (_: Sendable) in Self.progressPromise() },
                        Promise.delay(1.0).then { (_: Sendable) in Self.progressPromise() }]
        var promise: Promise?
        let index = [1, 2, 3].randomElement()!
        if index == 1 {
            promise = Promise.all(promises)
        } else if index == 2 {
            promise = Promise.any(promises)
        } else {
            promise = Promise.race(promises)
        }
        UIWindow.app.showProgress(0, text: String(format: "\(index)下载中(%.0f%%)", 0 * 100))
        promise?.done({ (value: Sendable) in
            Self.showMessage("\(value)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.app.showProgress(CGFloat(progress), text: String(format: "\(index)下载中(%.0f%%)", progress * 100))
        }, finally: {
            UIWindow.app.hideProgress()
        })
    }
}
