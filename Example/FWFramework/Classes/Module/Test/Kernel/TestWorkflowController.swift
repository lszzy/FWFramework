//
//  TestWorkflowController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@objc protocol TestWorkflowProtocol {
    @objc optional func testMethod1()
    @objc optional func testMethod2()
}

struct TestWeakObject<T: AnyObject> {
   weak var value: T?

   init(_ value: T?) {
      self.value = value
   }
}

class TestWorkflowController: UIViewController {
    
    // MARK: - Accessor
    var step: Int = 1
    weak var delegate: TestWorkflowProtocol?
    
    private static let testNotification = Notification.Name("TestWorkflowNotifiation")
    private static var notificationCount: Int = 0
    private static var notificationTargets: [TestWeakObject<NSObjectProtocol>] = []
    
    private static var kvoCount: Int = 0
    @objc dynamic private var kvoValue: Int = 0
    private static var kvoTargets: [TestWeakObject<NSObjectProtocol>] = []
    
    // MARK: - Subviews
    private lazy var delegateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Optional delegate method", for: .normal)
        button.addTarget(self, action: #selector(onDelegate), for: .touchUpInside)
        return button
    }()
    
    private lazy var notificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test notification", for: .normal)
        button.addTarget(self, action: #selector(onNotification), for: .touchUpInside)
        return button
    }()
    
    private lazy var kvoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test kvo", for: .normal)
        button.addTarget(self, action: #selector(onKvo), for: .touchUpInside)
        return button
    }()
    
}

// MARK: - Setup
extension TestWorkflowController: ViewControllerProtocol {
    
    func setupNavbar() {
        app.workflowName = "workflow.\(step)"
        navigationItem.title = "工作流-\(step)"
        
        if step < 3 {
            app.setRightBarItem("下一步", target: self, action: #selector(onNext))
        } else {
            app.addRightBarItem("退出", target: self, action: #selector(onExit))
            app.addRightBarItem("重来", target: self, action: #selector(onOpen))
        }
        
        let notificationTarget = app.observeNotification(Self.testNotification) { notification in
            TestWorkflowController.notificationCount += 1
            let targetCount = TestWorkflowController.notificationTargets.filter { $0.value != nil }.count
            UIWindow.app.showMessage(text: "收到通知总数: \(TestWorkflowController.notificationCount)次通知\n监听对象总数: \(targetCount)")
        }
        TestWorkflowController.notificationTargets.append(TestWeakObject(notificationTarget))
        
        let kvoTarget = app.observeProperty("kvoValue") { vc, _ in
            TestWorkflowController.kvoCount += 1
            let targetCount = TestWorkflowController.kvoTargets.filter { $0.value != nil }.count
            UIWindow.app.showMessage(text: "触发监听总数: \(TestWorkflowController.kvoCount)次通知\n监听对象总数: \(targetCount)")
        }
        TestWorkflowController.kvoTargets.append(TestWeakObject(kvoTarget))
    }
    
    func setupSubviews() {
        self.delegate = self
        view.addSubview(delegateButton)
        view.addSubview(notificationButton)
        view.addSubview(kvoButton)
    }
    
    func setupLayout() {
        delegateButton.app.layoutChain
            .horizontal()
            .top(toSafeArea: 20)
            .height(30)
        
        notificationButton.app.layoutChain
            .horizontal()
            .top(toViewBottom: delegateButton, offset: 20)
            .height(30)
        
        kvoButton.app.layoutChain
            .horizontal()
            .top(toViewBottom: notificationButton, offset: 20)
            .height(30)
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
    
}
