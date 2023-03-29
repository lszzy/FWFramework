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

class TestWorkflowController: UIViewController {
    
    // MARK: - Accessor
    var step: Int = 1
    weak var delegate: TestWorkflowProtocol?
    
    // MARK: - Subviews
    private lazy var delegateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Optional delegate method", for: .normal)
        button.addTarget(self, action: #selector(onDelegate), for: .touchUpInside)
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
    }
    
    func setupSubviews() {
        self.delegate = self
        view.addSubview(delegateButton)
    }
    
    func setupLayout() {
        delegateButton.app.layoutChain
            .horizontal()
            .top(toSafeArea: 20)
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
    
}
