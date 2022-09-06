//
//  TestStateController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestStateController: UIViewController {
    
    private lazy var label: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.textAlignment = .center
        return result
    }()
    
    private lazy var button: UIButton = {
        let result = AppTheme.largeButton()
        result.fw.addTouch(target: self, action: #selector(onClick(_:)))
        return result
    }()
    
    private var isLocked = false
    
    private var machine = StateMachine()
    
}

extension TestStateController: ViewControllerProtocol {
    
    func setupNavbar() {
        fw.setRightBarItem("锁定") { [weak self] sender in
            guard let this = self else { return }
            
            this.isLocked = !this.isLocked
            (sender as? UIBarButtonItem)?.title = this.isLocked ? "解锁" : "锁定"
        }
    }
    
    func setupSubviews() {
        view.addSubview(label)
        view.addSubview(button)
    }
    
    func setupLayout() {
        label.fw.layoutChain
            .horizontal(10)
            .top(toSafeArea: 10)
        
        button.fw.layoutChain
            .top(toViewBottom: label, offset: 10)
            .centerX()
        
        setupMachine()
    }
    
    func setupMachine() {
        // 添加状态
        let unread = StateObject.state(withName: "unread")
        unread.didEnterBlock = { [weak self] transition in
            self?.label.text = "状态：未读"
            self?.button.setTitle("已读", for: .normal)
            self?.button.tag = 1
        }
        
        let read = StateObject.state(withName: "read")
        read.didEnterBlock = { [weak self] transition in
            self?.label.text = "状态：已读"
            self?.button.setTitle("删除", for: .normal)
            self?.button.tag = 2
        }
        
        let delete = StateObject.state(withName: "delete")
        delete.didEnterBlock = { [weak self] transition in
            self?.label.text = "状态：删除"
            self?.button.setTitle("恢复", for: .normal)
            self?.button.tag = 3
        }
        
        machine.addStates([unread, read, delete])
        machine.initialState = unread
        
        // 添加事件
        let viewEvent = StateEvent(name: "view", fromStates: [unread], toState: read)
        viewEvent.fireBlock = { [weak self] transition, completion in
            self?.fw.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.fw.hideLoading()
                
                if [true, false].randomElement() == true {
                    completion(true)
                } else {
                    self?.fw.showMessage(text: "请求失败")
                    completion(false)
                }
            }
        }
        
        let deleteEvent = StateEvent(name: "trash", fromStates: [read, unread], toState: delete)
        deleteEvent.shouldFireBlock = { [weak self] transition in
            if self?.isLocked ?? false {
                self?.fw.showMessage(text: "已锁定，不能删除")
                return false
            }
            return true
        }
        deleteEvent.fireBlock = { [weak self] transition, completion in
            self?.fw.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.fw.hideLoading()
                
                if [true, false].randomElement() == true {
                    completion(true)
                } else {
                    self?.fw.showMessage(text: "请求失败")
                    completion(false)
                }
            }
        }
        
        let unreadEvent = StateEvent(name: "restore", fromStates: [read, delete], toState: unread)
        unreadEvent.shouldFireBlock = { [weak self] transition in
            if self?.isLocked ?? false {
                self?.fw.showMessage(text: "已锁定，不能恢复")
                return false
            }
            return true
        }
        unreadEvent.fireBlock = { [weak self] transition, completion in
            self?.fw.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.fw.hideLoading()
                
                if [true, false].randomElement() == true {
                    completion(true)
                } else {
                    self?.fw.showMessage(text: "请求失败")
                    completion(false)
                }
            }
        }
        
        machine.addEvents([viewEvent, deleteEvent, unreadEvent])
        // 激活事件
        machine.activate()
    }
    
}

@objc extension TestStateController {
    
    func onClick(_ button: UIButton) {
        let type = button.tag
        var event: String?
        if type == 1 {
            event = "view"
        } else if type == 2 {
            event = "trash"
        } else if type == 3 {
            event = "restore"
        }
        machine.fireEvent(event)
    }
    
}
