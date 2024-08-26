//
//  TestToolbarController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestToolbarController: UIViewController, TableViewControllerProtocol, ToolbarTitleViewDelegate, PopupMenuDelegate {
    typealias TableElement = String

    private var horizontalAlignment: UIControl.ContentHorizontalAlignment = .center

    private var titleView: ToolbarTitleView?

    private lazy var navigationView: ToolbarView = {
        let result = ToolbarView(type: .navBar)
        result.menuView.tintColor = AppTheme.textColor
        result.backgroundColor = AppTheme.barColor
        result.menuView.titleView?.showsLoadingView = true
        result.menuView.titleView?.title = "我是很长很长要多长有多长长得不得了的按钮"
        result.bottomHeight = APP.navigationBarHeight
        result.bottomHidden = true
        result.bottomView.backgroundColor = .green
        result.menuView.leftButton = ToolbarButton(object: Icon.backImage, block: { [weak self] _ in
            guard let self else { return }
            if !shouldPopController { return }
            app.close()
        })
        result.menuView.rightButton = ToolbarButton(object: APP.iconImage("zmdi-var-refresh", 24), block: { [weak self] _ in
            guard let self else { return }
            if !shouldPopController { return }
            app.close()
        })
        result.menuView.rightMoreButton = ToolbarButton(object: APP.iconImage("zmdi-var-share", 24), block: { [weak self] _ in
            guard let self else { return }
            if !shouldPopController { return }
            app.close()
        })
        return result
    }()

    private lazy var toolbarView: ToolbarView = {
        let result = ToolbarView()
        result.tintColor = AppTheme.textColor
        result.backgroundColor = AppTheme.barColor
        result.topHeight = 44
        result.topHidden = true
        result.topView.backgroundColor = .green
        result.menuView.leftButton = ToolbarButton(object: "取消", block: { [weak self] _ in
            self?.toolbarView.setToolbarHidden(true, animated: true)
            self?.app.showMessage(text: "点击了取消")
        })
        result.menuView.rightButton = ToolbarButton(object: "确定", block: { [weak self] _ in
            self?.toolbarView.setToolbarHidden(true, animated: true)
            self?.app.showMessage(text: "点击了确定")
        })
        return result
    }()

    override var shouldPopController: Bool {
        app.showConfirm(title: nil, message: "是否关闭") { [weak self] in
            self?.app.close()
        }
        return false
    }

    func didInitialize() {
        app.navigationBarHidden = true
    }

    func setupTableStyle() -> UITableView.Style {
        .plain
    }

    func setupTableLayout() {
        titleView = navigationView.menuView.titleView
        horizontalAlignment = titleView?.contentHorizontalAlignment ?? .center
        view.addSubview(navigationView)
        navigationView.app.layoutChain.left().right().top()
        view.addSubview(toolbarView)
        toolbarView.app.layoutChain.left().right().bottom()

        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: APP.screenWidth, height: 300))
        tableView.app.layoutChain.left().right()
            .top(toViewBottom: navigationView)
            .bottom(toViewTop: toolbarView)
    }

    func setupSubviews() {
        tableData.append(contentsOf: [
            "标题左对齐",
            "显示左边的loading",
            "显示右边的accessoryView",
            "显示副标题",
            "切换为上下两行显示",
            "水平方向的对齐方式",
            "模拟标题的loading状态切换",
            "标题点击效果",

            "导航栏顶部切换",
            "导航栏菜单切换",
            "导航栏底部切换",
            "导航栏切换",

            "工具栏顶部切换",
            "工具栏菜单切换",
            "工具栏底部切换",
            "工具栏切换"
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .value1)
        cell.accessoryType = .none
        cell.detailTextLabel?.text = nil

        guard let titleView else { return cell }
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = navigationView.menuView.alignmentLeft ? "标题居中对齐" : "标题左对齐"
        case 1:
            cell.textLabel?.text = titleView.loadingViewHidden ? "显示左边的loading" : "隐藏左边的loading"
        case 2:
            cell.textLabel?.text = titleView.accessoryImage == nil ? "显示右边的accessoryView" : "去掉右边的accessoryView"
        case 3:
            cell.textLabel?.text = titleView.subtitle != nil ? "去掉副标题" : "显示副标题"
        case 4:
            cell.textLabel?.text = titleView.style == .horizontal ? "切换为上下两行显示" : "切换为水平一行显示"
        case 5:
            cell.textLabel?.text = tableData[indexPath.row]
            cell.detailTextLabel?.text = (horizontalAlignment == .left ? "左对齐" : (horizontalAlignment == .right ? "右对齐" : "居中对齐"))
        default:
            cell.textLabel?.text = tableData[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        titleView?.isUserInteractionEnabled = false
        titleView?.delegate = nil

        guard let titleView else { return }
        switch indexPath.row {
        case 0:
            navigationView.menuView.alignmentLeft = !navigationView.menuView.alignmentLeft
            titleView.titleLabel.textAlignment = navigationView.menuView.alignmentLeft ? .left : .center
            titleView.showsLoadingPlaceholder = navigationView.menuView.alignmentLeft ? false : true
        case 1:
            titleView.loadingViewHidden = !titleView.loadingViewHidden
        case 2:
            titleView.accessoryImage = titleView.accessoryImage != nil ? nil : APP.iconImage("zmdi-var-caret-down", 24)
        case 3:
            titleView.subtitle = titleView.subtitle != nil ? nil : "(副标题)"
        case 4:
            titleView.style = titleView.style == .horizontal ? .vertical : .horizontal
            titleView.subtitle = titleView.style == .vertical ? "(副标题)" : titleView.subtitle
        case 5:
            app.showSheet(title: "水平对齐方式", message: nil, cancel: "取消", actions: ["左对齐", "居中对齐", "右对齐"]) { [weak self] index in
                if index == 0 {
                    titleView.contentHorizontalAlignment = .left
                } else if index == 1 {
                    titleView.contentHorizontalAlignment = .center
                } else {
                    titleView.contentHorizontalAlignment = .left
                }
                self?.horizontalAlignment = titleView.contentHorizontalAlignment
                self?.tableView.reloadData()
            }
        case 6:
            titleView.loadingViewHidden = false
            titleView.showsLoadingPlaceholder = false
            titleView.title = "加载中..."
            titleView.subtitle = nil
            titleView.style = .horizontal
            titleView.accessoryImage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                titleView.showsLoadingPlaceholder = true
                titleView.loadingViewHidden = true
                titleView.title = "主标题"
            }
        case 7:
            titleView.isUserInteractionEnabled = true
            titleView.title = "点我展开分类"
            titleView.accessoryImage = APP.iconImage("zmdi-var-caret-down", 24)
            titleView.delegate = self
        case 8:
            navigationView.setTopHidden(!navigationView.topHidden, animated: true)
        case 9:
            navigationView.setMenuHidden(!navigationView.menuHidden, animated: true)
        case 10:
            navigationView.setBottomHidden(!navigationView.bottomHidden, animated: true)
        case 11:
            navigationView.setToolbarHidden(!navigationView.toolbarHidden, animated: true)
        case 12:
            toolbarView.setTopHidden(!toolbarView.topHidden, animated: true)
        case 13:
            toolbarView.setMenuHidden(!toolbarView.menuHidden, animated: true)
        case 14:
            toolbarView.setBottomHidden(!toolbarView.bottomHidden, animated: true)
        case 15:
            toolbarView.setToolbarHidden(!toolbarView.toolbarHidden, animated: true)
        default:
            break
        }

        tableView.reloadData()
    }

    func didChangedActive(_ active: Bool, for titleView: ToolbarTitleView) {
        if !active { return }
        PopupMenu.show(relyOn: titleView, titles: ["菜单1", "菜单2"], icons: nil, menuWidth: 120) { [weak self] popupMenu in
            popupMenu.delegate = self
        }
    }

    func popupMenuDidDismiss(_ popupMenu: PopupMenu) {
        titleView?.isActive = false
    }
}
