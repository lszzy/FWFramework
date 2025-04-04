//
//  TestWorkflowController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@MainActor @objc protocol TestWorkflowProtocol {
    @objc optional func testMethod1()
    @objc optional func testMethod2()
}

class TestWorkflowController: UIViewController, TableViewControllerProtocol {
    class DeinitObject {
        let name: String

        init(name: String = "DeinitObject") {
            self.name = name
        }

        func test() {
            Logger.debug("%@", "\(name) test")
        }

        deinit {
            Logger.debug("%@", "\(name) deinit")

            MainActor.runDeinit(object: name) { name in
                UIWindow.app.showMessage(text: "\(name) deinit")
            }
        }
    }

    // MARK: - Accessor
    var step: Int = 1
    weak var delegate: TestWorkflowProtocol?

    private static let testNotification = Notification.Name("TestWorkflowNotifiation")
    private static var notificationCount: Int = 0
    private static var notificationTargets: [WeakValue] = []

    private static var kvoCount: Int = 0
    @objc private dynamic var kvoValue: Int = 0
    private static var kvoTargets: [WeakValue] = []

    typealias TableElement = [String]

    func setupNavbar() {
        app.workflowName = "workflow.\(step)"
        navigationItem.title = "工作流-\(step)"

        if step < 3 {
            app.setRightBarItem(Icon.iconImage("zmdi-var-arrow-right", size: 24), target: self, action: #selector(onNext))
        } else {
            app.addRightBarItem(Icon.closeImage, target: self, action: #selector(onExit))
            app.addRightBarItem(Icon.iconImage("zmdi-var-replay", size: 24), target: self, action: #selector(onOpen))
        }

        let notificationTarget = app.safeObserveNotification(Self.testNotification) { _ in
            TestWorkflowController.notificationCount += 1
            let targetCount = TestWorkflowController.notificationTargets.filter { $0.value != nil }.count
            UIWindow.app.showMessage(text: "收到通知总数: \(TestWorkflowController.notificationCount)次通知\n监听对象总数: \(targetCount)")
        }
        TestWorkflowController.notificationTargets.append(WeakValue(notificationTarget))

        let kvoTarget = app.safeObserveProperty(\.kvoValue) { _, _ in
            TestWorkflowController.kvoCount += 1
            let targetCount = TestWorkflowController.kvoTargets.filter { $0.value != nil }.count
            UIWindow.app.showMessage(text: "触发监听总数: \(TestWorkflowController.kvoCount)次通知\n监听对象总数: \(targetCount)")
        }
        TestWorkflowController.kvoTargets.append(WeakValue(kvoTarget))
    }

    func setupSubviews() {
        delegate = self
        tableData.append(contentsOf: [
            ["Optional delegate method", "onDelegate"],
            ["Test notification", "onNotification"],
            ["Test kvo", "onKvo"],
            ["Capture exception", "onException"],
            ["Capture error", "onError"],
            ["Uncaught exception (Crash)", "onUncaughtException"],
            ["Uncaught signal (Crash)", "onUncaughtError"],
            ["Background task", "onBackground"],
            ["Background request", "onRequest"],
            ["MainActor deinit", "onDeinit1"],
            ["MainActor deinit (global)", "onDeinit2"]
        ])
    }

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
}

// MARK: - Action
@objc extension TestWorkflowController: TestWorkflowProtocol {
    func onNext() {
        let workflow = TestWorkflowController()
        workflow.step = step + 1
        navigationController?.pushViewController(workflow, animated: true)
    }

    func onExit() {
        navigationController?.app.popWorkflows(["workflow"], animated: true, completion: nil)
    }

    func onOpen() {
        navigationController?.app.push(TestWorkflowController(), popWorkflows: ["workflow"], animated: true, completion: nil)
    }

    func onDelegate() {
        let result1 = delegate?.testMethod1?() != nil
        let result2 = delegate?.testMethod2?() != nil
        app.showMessage(text: "testMethod1: \(result1)\ntestMethod2: \(result2)")
    }

    func testMethod1() {
        print("testMethod1")
    }

    func onNotification() {
        NSObject.app.postNotification(Self.testNotification)
    }

    func onKvo() {
        kvoValue = [0, 1].randomElement()!
    }

    func onException() {
        NSNull().perform(NSSelectorFromString("onException"))
    }

    func onError() {
        ErrorManager.captureError(PromiseError.failed, remark: "Test error")
    }

    func onUncaughtException() {
        perform(NSSelectorFromString("onMethodNotFound"))
    }

    func onUncaughtError() {
        var str: String!
        str = str + "..."
    }

    func onBackground() {
        let string = CacheFile.shared.object(forKey: "backgroundTask") as String?
        if let string, !string.isEmpty {
            app.showAlert(title: "上次后台结果", message: string)
        } else {
            app.showAlert(title: "后台任务创建成功", message: "请将App退后台测试\n时间：\(Date.app.currentTime)")
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.didEnterBackground = {
            UIApplication.app.beginBackgroundTask({ completionHandler in
                CacheFile.shared.setObject("后台任务开始\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                DispatchQueue.global().async {
                    sleep(1)
                    CacheFile.shared.setObject("后台任务执行1秒，未完成\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                    sleep(1)
                    CacheFile.shared.setObject("后台任务执行2秒，未完成\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                    sleep(1)
                    CacheFile.shared.setObject("后台任务执行3秒，未完成\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                    sleep(1)
                    CacheFile.shared.setObject("后台任务执行4秒，未完成\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                    sleep(1)
                    CacheFile.shared.setObject("后台任务执行5秒，已完成\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                    completionHandler()
                }
            }, expirationHandler: {
                CacheFile.shared.setObject("后台任务已过期\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")
            })
        }
    }

    func onRequest() {
        let string = CacheFile.shared.object(forKey: "backgroundTask") as String?
        if let string, !string.isEmpty {
            app.showAlert(title: "上次后台结果", message: string)
        } else {
            app.showAlert(title: "后台任务创建成功", message: "请将App退后台测试\n时间：\(Date.app.currentTime)")
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.didEnterBackground = {
            UIApplication.app.beginBackgroundTask({ completionHandler in
                CacheFile.shared.setObject("后台请求开始\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")

                let request = TestModelRequest()
                request.start { _ in
                    let string = "后台请求成功：\(request.safeResponseModel.name)\n时间：\(request.responseServerTime)"
                    CacheFile.shared.setObject(string, forKey: "backgroundTask")

                    completionHandler()
                } failure: { _ in
                    let string = "后台请求失败：\(request.error?.localizedDescription ?? "")\n时间：\(request.responseServerTime)"
                    CacheFile.shared.setObject(string, forKey: "backgroundTask")

                    completionHandler()
                }
            }, expirationHandler: {
                CacheFile.shared.setObject("后台请求已过期\n时间：\(Date.app.currentTime)", forKey: "backgroundTask")
            })
        }
    }

    func onDeinit1() {
        var object: DeinitObject? = DeinitObject()
        object?.test()
        object = nil
    }

    func onDeinit2() {
        DispatchQueue.global().async {
            var object: DeinitObject? = DeinitObject()
            object?.test()
            object = nil
        }
    }
}
