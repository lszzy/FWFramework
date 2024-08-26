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
        result.app.addTouch(target: self, action: #selector(onClick(_:)))
        return result
    }()

    private var isLocked = false

    private var machine = StateMachine()
}

extension TestStateController: ViewControllerProtocol {
    func setupNavbar() {
        app.setRightBarItem(Icon.iconImage("zmdi-var-lock-open", size: 24)) { [weak self] sender in
            guard let self else { return }

            isLocked = !isLocked
            sender.image = isLocked ? Icon.iconImage("zmdi-var-lock", size: 24) : Icon.iconImage("zmdi-var-lock-open", size: 24)
        }
    }

    func setupSubviews() {
        view.addSubview(label)
        view.addSubview(button)
    }

    func setupLayout() {
        label.app.layoutChain
            .horizontal(10)
            .top(toSafeArea: 10)

        button.app.layoutChain
            .top(toViewBottom: label, offset: 10)
            .centerX()

        setupMachine()
    }

    func setupMachine() {
        // 添加状态
        let unread = StateObject(name: "unread")
        unread.didEnterBlock = { [weak self] _ in
            self?.label.text = "状态：未读"
            self?.button.setTitle("已读", for: .normal)
            self?.button.tag = 1
        }

        let read = StateObject(name: "read")
        read.didEnterBlock = { [weak self] _ in
            self?.label.text = "状态：已读"
            self?.button.setTitle("删除", for: .normal)
            self?.button.tag = 2
        }

        let delete = StateObject(name: "delete")
        delete.didEnterBlock = { [weak self] _ in
            self?.label.text = "状态：删除"
            self?.button.setTitle("恢复", for: .normal)
            self?.button.tag = 3
        }

        machine.addStates([unread, read, delete])
        machine.initialState = unread

        // 添加事件
        let viewEvent = StateEvent(name: "view", from: [unread], to: read)
        viewEvent.fireBlock = { [weak self] _, completion in
            self?.app.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.app.hideLoading()

                if [0, 1, 2].randomElement() != 0 {
                    completion(true)
                } else {
                    self?.app.showMessage(text: "请求失败")
                    completion(false)
                }
            }
        }

        let deleteEvent = StateEvent(name: "trash", from: [read, unread], to: delete)
        deleteEvent.shouldFireBlock = { [weak self] _ in
            if self?.isLocked ?? false {
                self?.app.showMessage(text: "已锁定，不能删除")
                return false
            }
            return true
        }
        deleteEvent.fireBlock = { [weak self] _, completion in
            self?.app.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.app.hideLoading()

                if [0, 1, 2].randomElement() != 0 {
                    completion(true)
                } else {
                    self?.app.showMessage(text: "请求失败")
                    completion(false)
                }
            }
        }

        let unreadEvent = StateEvent(name: "restore", from: [read, delete], to: unread)
        unreadEvent.shouldFireBlock = { [weak self] _ in
            if self?.isLocked ?? false {
                self?.app.showMessage(text: "已锁定，不能恢复")
                return false
            }
            return true
        }
        unreadEvent.fireBlock = { [weak self] _, completion in
            self?.app.showLoading(text: "正在请求")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.app.hideLoading()

                if [0, 1, 2].randomElement() != 0 {
                    completion(true)
                } else {
                    self?.app.showMessage(text: "请求失败")
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
