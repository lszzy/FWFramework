//
//  TestWorkflowController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestWorkflowController: UIViewController {
    
    // MARK: - Accessor
    var step: Int = 1
    
}

// MARK: - Setup
extension TestWorkflowController: ViewControllerProtocol {
    
    func setupNavbar() {
        fw.workflowName = "workflow.\(step)"
        navigationItem.title = "工作流-\(step)"
        
        if step < 3 {
            fw.setRightBarItem("下一步", target: self, action: #selector(onNext))
        } else {
            fw.addRightBarItem("退出", target: self, action: #selector(onExit))
            fw.addRightBarItem("重来", target: self, action: #selector(onOpen))
        }
    }
}

// MARK: - Action
@objc private extension TestWorkflowController {
    
    func onNext() {
        let workflow = TestWorkflowController()
        workflow.step = step + 1
        navigationController?.pushViewController(workflow, animated: true)
    }
    
    func onExit() {
        navigationController?.fw.popWorkflows(["workflow"], animated: true, completion: nil)
    }
    
    func onOpen() {
        navigationController?.fw.push(TestWorkflowController(), popWorkflows: ["workflow"], animated: true, completion: nil)
    }
    
}
