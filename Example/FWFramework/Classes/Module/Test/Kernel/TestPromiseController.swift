//
//  TestPromiseController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPromiseController: UIViewController, TableViewControllerProtocol {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fw.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
}

extension TestPromiseController {
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupSubviews() {
        tableData.addObjects(from: [
            ["unsafe(Crash)", "onUnsafe"],
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
            ["+progress", "onProgress2"],
        ])
    }
    
    private static func successPromise(_ value: Int = 0) -> Promise {
        return Promise { resolve, reject in
            Promise.delay(1).done { _ in
                resolve(value + 1)
            }
        }
    }
    
    private static func failurePromise() -> Promise {
        return Promise { completion in
            Promise.delay(1).done { _ in
                completion(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test failed"]))
            }
        }
    }
    
    private static func randomPromise(_ value: Int = 0) -> Promise {
        return [0, 1].randomElement() == 1 ? successPromise(value) : failurePromise()
    }
    
    private static func progressPromise() -> Promise {
        return Promise { resolve, reject, progress in
            DispatchQueue.global().async {
                var value: Double = 0
                while (value < 1) {
                    value += 0.02
                    let finish = value >= 1
                    DispatchQueue.main.async {
                        if (finish) {
                            progress(1)
                            if [0, 1, 2].randomElement() == 0 {
                                reject(Promise.defaultError)
                            } else {
                                resolve(UIImage())
                            }
                        } else {
                            progress(value)
                        }
                    }
                    usleep(50000)
                }
            }
        }
    }
    
    private static func showMessage(_ text: String) {
        UIWindow.fw.showMessage(text: text)
    }
    
    private static var isLoading: Bool = false {
        didSet {
            if isLoading {
                UIWindow.fw.showLoading()
            } else {
                UIWindow.fw.hideLoading()
            }
        }
    }
    
    @objc func onUnsafe() {
        Self.isLoading = true
        var values: [Int] = []
        DispatchQueue.concurrentPerform(iterations: 10000) { index in
            let last = values.last ?? 0
            values.append(last + 1)
        }
        Self.isLoading = false
        Self.showMessage("result: \(values.last.safeInt)")
    }
    
    @objc func onSafe() {
        Self.isLoading = true
        var value: Int = 0
        let index = [1, 2].randomElement()!
        if index == 1 {
            var values: [Int] = []
            let semaphore = DispatchSemaphore(value: 1)
            DispatchQueue.concurrentPerform(iterations: 10000) { index in
                semaphore.wait()
                let last = values.last ?? 0
                values.append(last + 1)
                semaphore.signal()
            }
            value = values.last.safeInt
        } else {
            var values: [Int] = []
            let queue = DispatchQueue(label: "serial")
            DispatchQueue.concurrentPerform(iterations: 10000) { index in
                queue.async {
                    let last = values.last ?? 0
                    values.append(last + 1)
                }
            }
            queue.sync {
                value = values.last.safeInt
            }
        }
        Self.isLoading = false
        Self.showMessage("\(index).result: \(value)")
    }
    
    @objc func onDone() {
        Self.isLoading = true
        var value = 0
        Promise { completion in
            for i in 0 ..< 10000 {
                Self.successPromise(i).done { _ in
                    value += 1
                    completion(value)
                }
            }
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onThen() {
        Self.isLoading = true
        Self.successPromise().then { value in
            return Self.successPromise(value.safeInt)
        }.then({ value in
            return value.safeInt + 1
        }).done({ value in
            Self.showMessage("done: 3 => \(value.safeInt)")
        }, catch: { error in
            Self.showMessage("error: \(error)")
        }, finally: {
            Self.isLoading = false
        })
    }
    
    @objc func onAwait() {
        Self.isLoading = true
        FW.async {
            var value = try FW.await(Self.successPromise())
            value = try FW.await(Self.successPromise(value.safeInt))
            return value
        }.done { value in
            Self.isLoading = false
            Self.showMessage("value: 2 => \(value.safeString)")
        }
    }
    
    @objc func onAll() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0 ..< 10000 {
            promises.append(i < 9999 ? Self.successPromise() : Self.randomPromise())
        }
        FW.async {
            return try FW.await(Promise.all(promises).then { values in
                return values.safeArray.count
            })
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onAny() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0 ..< 10000 {
            promises.append(i < 5000 ? Self.failurePromise() : Self.randomPromise(i))
        }
        FW.async {
            return try FW.await(Promise.any(promises))
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onRace() {
        Self.isLoading = true
        var promises: [Promise] = []
        for i in 0 ..< 10000 {
            promises.append(Self.randomPromise(i))
        }
        FW.async {
            return try FW.await(Promise.race(promises.shuffled()))
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onDelay() {
        Self.isLoading = true
        Self.randomPromise().then({ value in
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "delay")
            }
            return value
        }).delay(1).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onValidate() {
        Self.isLoading = true
        Self.randomPromise([0, 1].randomElement()!).validate { value in
            return value.safeInt > 1
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onTimeout() {
        Self.isLoading = true
        let delayTime: TimeInterval = [0, 1].randomElement() == 1 ? 4 : 1
        Self.randomPromise().delay(delayTime).timeout(3).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onRecover() {
        Self.isLoading = true
        Self.failurePromise().recover { error in
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "\(error)")
            }
            return 1
        }.delay(1).then({ value in
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "\(value.safeInt)")
            }
            return Self.successPromise(value.safeInt)
        }).validate { value in
            return false
        }.recover { error in
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "\(error)")
            }
            return Self.successPromise()
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onReduce() {
        Self.isLoading = true
        Self.randomPromise().reduce([2, 3, 4, 5]) { value, item in
            return "\(value.safeString),\(FW.safeString(item))"
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.safeString)")
        }
    }
    
    @objc func onRetry() {
        Self.isLoading = true
        let startTime = Date.fw.currentTime
        var count = 0
        Self.failurePromise().recover({ $0 }).retry(4, delay: 0) {
            count += 1
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "retry: \(count)")
            }
            if count < 4 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = Date.fw.currentTime
            Self.showMessage("result: \(result.safeString) => " + String(format: "%.1fs", endTime - startTime))
        }
    }
    
    @objc func onRetry2() {
        Self.isLoading = true
        let startTime = Date.fw.currentTime
        var count = 0
        Promise.retry(4, delay: 0) {
            count += 1
            if count == 1 { return Self.failurePromise() }
            DispatchQueue.main.async {
                UIWindow.fw.showLoading(text: "retry: \(count - 1)")
            }
            if count < 5 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count - 1)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = Date.fw.currentTime
            Self.showMessage("result: \(result.safeString) => " + String(format: "%.1fs", endTime - startTime))
        }
    }
    
    @objc func onProgress() {
        var promise: Promise?
        let index = [1, 2, 3].randomElement()!
        if index == 1 {
            promise = Self.progressPromise().then({ value in
                return Self.successPromise()
            })
        } else if index == 2 {
            promise = Self.successPromise().then({ value in
                return Self.progressPromise()
            })
        } else {
            promise = Self.failurePromise().recover({ value in
                return Self.progressPromise()
            })
        }
        UIWindow.fw.showProgress(0, text: String(format: "\(index)下载中(%.0f%%)", 0 * 100))
        promise?.validate({ value in
            return false
        }).recover({ error in
            return Promise(value: "\(index)下载成功")
        }).reduce([1, 2], reducer: { value, item in
            return value
        }).delay(1).timeout(30).retry(1, delay: 0, block: {
            return Self.successPromise()
        }).done({ value in
            Self.showMessage("\(value.safeString)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.fw.showProgress(CGFloat(progress), text: String(format: "\(index)下载中(%.0f%%)", progress * 100))
        }, finally: {
            UIWindow.fw.hideProgress()
        })
    }
    
    @objc func onProgress2() {
        let promises = [Self.progressPromise(),
                        Promise.delay(0.5).then({ _ in Self.progressPromise() }),
                        Promise.delay(1.0).then({ _ in Self.progressPromise() })]
        var promise: Promise?
        let index = [1, 2, 3].randomElement()!
        if index == 1 {
            promise = Promise.all(promises)
        } else if index == 2 {
            promise = Promise.any(promises)
        } else {
            promise = Promise.race(promises)
        }
        UIWindow.fw.showProgress(0, text: String(format: "\(index)下载中(%.0f%%)", 0 * 100))
        promise?.done({ value in
            Self.showMessage("\(value.safeString)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.fw.showProgress(CGFloat(progress), text: String(format: "\(index)下载中(%.0f%%)", progress * 100))
        }, finally: {
            UIWindow.fw.hideProgress()
        })
    }
}
