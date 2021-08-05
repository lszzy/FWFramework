//
//  TestPromiseViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

@objcMembers class TestPromiseViewController: TestViewController, FWTableViewController {
    func renderTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fwPerform(NSSelectorFromString(rowData[1]))
    }
}

extension TestPromiseViewController {
    override func renderData() {
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
    
    private static func successPromise(_ value: Int = 0) -> FWPromise {
        return FWPromise { resolve, reject in
            FWPromise.delay(1).done { _ in
                resolve(value + 1)
            }
        }
    }
    
    private static func failurePromise() -> FWPromise {
        return FWPromise { completion in
            FWPromise.delay(1).done { _ in
                completion(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test failed"]))
            }
        }
    }
    
    private static func randomPromise(_ value: Int = 0) -> FWPromise {
        return [0, 1].randomElement() == 1 ? successPromise(value) : failurePromise()
    }
    
    private static func progressPromise() -> FWPromise {
        return FWPromise { resolve, reject, progress in
            DispatchQueue.global().async {
                var value: Double = 0
                while (value < 1) {
                    value += 0.02
                    let finish = value >= 1
                    DispatchQueue.main.async {
                        if (finish) {
                            progress(1)
                            if [0, 1, 2].randomElement() == 0 {
                                reject(FWPromise.defaultError)
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
        UIWindow.fwMain?.fwShowMessage(withText: text)
    }
    
    private static var isLoading: Bool = false {
        didSet {
            if isLoading {
                UIWindow.fwMain?.fwShowLoading()
            } else {
                UIWindow.fwMain?.fwHideLoading()
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
        Self.showMessage("result: \(values.last.fwAsInt)")
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
            value = values.last.fwAsInt
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
                value = values.last.fwAsInt
            }
        }
        Self.isLoading = false
        Self.showMessage("\(index).result: \(value)")
    }
    
    @objc func onDone() {
        Self.isLoading = true
        var value = 0
        FWPromise { completion in
            for i in 0 ..< 10000 {
                Self.successPromise(i).done { _ in
                    value += 1
                    completion(value)
                }
            }
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onThen() {
        Self.isLoading = true
        Self.successPromise().then { value in
            return Self.successPromise(value.fwAsInt)
        }.then({ value in
            return value.fwAsInt + 1
        }).done({ value in
            Self.showMessage("done: 3 => \(value.fwAsInt)")
        }, catch: { error in
            Self.showMessage("error: \(error)")
        }, finally: {
            Self.isLoading = false
        })
    }
    
    @objc func onAwait() {
        Self.isLoading = true
        fw_async {
            var value = try fw_await(Self.successPromise())
            value = try fw_await(Self.successPromise(value.fwAsInt))
            return value
        }.done { value in
            Self.isLoading = false
            Self.showMessage("value: 2 => \(value.fwAsString)")
        }
    }
    
    @objc func onAll() {
        Self.isLoading = true
        var promises: [FWPromise] = []
        for i in 0 ..< 10000 {
            promises.append(i < 9999 ? Self.successPromise() : Self.randomPromise())
        }
        fw_async {
            return try fw_await(FWPromise.all(promises).then { values in
                return values.fwAsArray.count
            })
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onAny() {
        Self.isLoading = true
        var promises: [FWPromise] = []
        for i in 0 ..< 10000 {
            promises.append(i < 5000 ? Self.failurePromise() : Self.randomPromise(i))
        }
        fw_async {
            return try fw_await(FWPromise.any(promises))
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onRace() {
        Self.isLoading = true
        var promises: [FWPromise] = []
        for i in 0 ..< 10000 {
            promises.append(Self.randomPromise(i))
        }
        fw_async {
            return try fw_await(FWPromise.race(promises.shuffled()))
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onDelay() {
        Self.isLoading = true
        Self.randomPromise().then({ value in
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "delay")
            }
            return value
        }).delay(1).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onValidate() {
        Self.isLoading = true
        Self.randomPromise([0, 1].randomElement()!).validate { value in
            return value.fwAsInt > 1
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onTimeout() {
        Self.isLoading = true
        let delayTime: TimeInterval = [0, 1].randomElement() == 1 ? 4 : 1
        Self.randomPromise().delay(delayTime).timeout(3).done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onRecover() {
        Self.isLoading = true
        Self.failurePromise().recover { error in
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "\(error)")
            }
            return 1
        }.delay(1).then({ value in
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "\(value.fwAsInt)")
            }
            return Self.successPromise(value.fwAsInt)
        }).validate { value in
            return false
        }.recover { error in
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "\(error)")
            }
            return Self.successPromise()
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onReduce() {
        Self.isLoading = true
        Self.randomPromise().reduce([2, 3, 4, 5]) { value, item in
            return "\(value.fwAsString),\(FWSafeString(item))"
        }.done { result in
            Self.isLoading = false
            Self.showMessage("result: \(result.fwAsString)")
        }
    }
    
    @objc func onRetry() {
        Self.isLoading = true
        let startTime = NSDate.fwCurrentTime
        var count = 0
        Self.failurePromise().recover({ $0 }).retry(4, delay: 0) {
            count += 1
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "retry: \(count)")
            }
            if count < 4 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = NSDate.fwCurrentTime
            Self.showMessage("result: \(result.fwAsString) => " + String(format: "%.1fs", endTime - startTime))
        }
    }
    
    @objc func onRetry2() {
        Self.isLoading = true
        let startTime = NSDate.fwCurrentTime
        var count = 0
        FWPromise.retry(4, delay: 0) {
            count += 1
            if count == 1 { return Self.failurePromise() }
            DispatchQueue.main.async {
                UIWindow.fwMain?.fwShowLoading(withText: "retry: \(count - 1)")
            }
            if count < 5 {
                return Self.failurePromise()
            } else {
                return Self.randomPromise(count - 1)
            }
        }.done { result in
            Self.isLoading = false
            let endTime = NSDate.fwCurrentTime
            Self.showMessage("result: \(result.fwAsString) => " + String(format: "%.1fs", endTime - startTime))
        }
    }
    
    @objc func onProgress() {
        var promise: FWPromise?
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
        UIWindow.fwMain?.fwShowProgress(withText: String(format: "\(index)下载中(%.0f%%)", 0 * 100), progress: 0)
        promise?.validate({ value in
            return false
        }).recover({ error in
            return FWPromise(value: "\(index)下载成功")
        }).reduce([1, 2], reducer: { value, item in
            return value
        }).delay(1).timeout(30).retry(1, delay: 0, block: {
            return Self.successPromise()
        }).done({ value in
            Self.showMessage("\(value.fwAsString)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.fwMain?.fwShowProgress(withText: String(format: "\(index)下载中(%.0f%%)", progress * 100), progress: CGFloat(progress))
        }, finally: {
            UIWindow.fwMain?.fwHideProgress()
        })
    }
    
    @objc func onProgress2() {
        let promises = [Self.progressPromise(),
                        FWPromise.delay(0.5).then({ _ in Self.progressPromise() }),
                        FWPromise.delay(1.0).then({ _ in Self.progressPromise() })]
        var promise: FWPromise?
        let index = [1, 2, 3].randomElement()!
        if index == 1 {
            promise = FWPromise.all(promises)
        } else if index == 2 {
            promise = FWPromise.any(promises)
        } else {
            promise = FWPromise.race(promises)
        }
        UIWindow.fwMain?.fwShowProgress(withText: String(format: "\(index)下载中(%.0f%%)", 0 * 100), progress: 0)
        promise?.done({ value in
            Self.showMessage("\(value.fwAsString)")
        }, catch: { error in
            Self.showMessage("\(error)")
        }, progress: { progress in
            UIWindow.fwMain?.fwShowProgress(withText: String(format: "\(index)下载中(%.0f%%)", progress * 100), progress: CGFloat(progress))
        }, finally: {
            UIWindow.fwMain?.fwHideProgress()
        })
    }
}
