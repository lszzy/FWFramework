//
//  TestDrawerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/28.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestDrawerController: UIViewController, ViewControllerProtocol, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private var canScroll = true
    private var isInset = true
    
    private lazy var contentView: UIView = {
        let result = UIView()
        result.frame = CGRect(x: -FW.screenWidth / 2.0, y: 0, width: FW.screenWidth / 2.0, height: view.fw.height)
        result.backgroundColor = .brown
        return result
    }()
    
    private lazy var bottomView: UIView = {
        let result = UIView()
        result.frame = CGRect(x: 0, y: view.fw.height - 100.0, width: FW.screenWidth, height: view.fw.height - 100)
        result.backgroundColor = .fw.randomColor
        result.addSubview(tableView)
        
        let lineView = UIView()
        lineView.frame = CGRect(x: FW.screenWidth / 2 - 24, y: 8, width: 48, height: 4)
        lineView.backgroundColor = .gray
        lineView.layer.cornerRadius = 2
        result.addSubview(lineView)
        return result
    }()
    
    private lazy var tableView: UITableView = {
        let result = UITableView.fw.tableView()
        result.frame = CGRect(x: 0, y: 50, width: FW.screenWidth, height: view.fw.height - 150)
        result.contentInsetAdjustmentBehavior = .never
        result.backgroundColor = AppTheme.tableColor
        result.dataSource = result.fw.tableDelegate
        result.delegate = result.fw.tableDelegate
        result.fw.tableDelegate.numberOfRows = { [weak self] _ in
            return (self?.canScroll ?? false) ? 30 : 3
        }
        result.fw.tableDelegate.cellConfiguation = { cell, indexPath in
            cell.fw.maxYViewExpanded = true
            cell.contentView.backgroundColor = AppTheme.cellColor
            cell.textLabel?.text = "\(indexPath.row + 1)"
        }
        result.fw.tableDelegate.didScroll = { [weak self] scrollView in
            self?.bottomView.fw.drawerView?.scrollDidScroll(scrollView)
        }
        return result
    }()
    
    func didInitialize() {
        fw.extendedLayoutEdge = .top
        fw.navigationBarStyle = .transparent
    }
    
    override var shouldPopController: Bool {
        let drawerView = contentView.fw.drawerView
        drawerView?.setPosition(drawerView?.openPosition ?? 0, animated: true)
        return false
    }
    
    func setupNavbar() {
        fw.setLeftBarItem(FW.iconImage("zmdi-var-menu", 24)) { [weak self] _ in
            self?.toggleMenu()
        }
        
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换内容高度", "contentInset撑开", "footerView撑开", "文字识别"], currentIndex: -1, actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    self.canScroll = !self.canScroll
                    self.tableView.reloadData()
                    self.toggleInset()
                } else if index == 1 {
                    self.isInset = true
                    self.toggleInset()
                } else if index == 2 {
                    self.isInset = false
                    self.toggleInset()
                } else {
                    self.onPhotoSheet()
                }
            })
        }
    }
    
    func setupSubviews() {
        view.backgroundColor = AppTheme.tableColor
        
        let topLabel = UILabel(frame: CGRect(x: 50, y: 200, width: 100, height: 30))
        topLabel.text = "默认模式"
        contentView.addSubview(topLabel)
        topLabel.isUserInteractionEnabled = true
        topLabel.fw.addTapGesture { [weak self] _ in
            guard let drawerView = self?.bottomView.fw.drawerView else { return }
            drawerView.scrollViewFilter = { _ in true }
            drawerView.scrollViewPositions = nil
            self?.toggleMenu()
        } customize: { gesture in
            gesture.highlightedAlpha = 0.5
        }
        
        let middleLabel = UILabel(frame: CGRect(x: 50, y: 250, width: 100, height: 30))
        middleLabel.text = "可滚动模式"
        contentView.addSubview(middleLabel)
        middleLabel.isUserInteractionEnabled = true
        middleLabel.fw.addTapGesture { [weak self] _ in
            guard let drawerView = self?.bottomView.fw.drawerView else { return }
            drawerView.scrollViewFilter = { _ in true }
            drawerView.scrollViewPositions = { _ in
                return [
                    NSNumber(value: drawerView.openPosition),
                    NSNumber(value: drawerView.middlePosition)
                ]
            }
            self?.toggleMenu()
        } customize: { gesture in
            gesture.highlightedAlpha = 0.5
        }
        
        let bottomLabel = UILabel(frame: CGRect(x: 50, y: 300, width: 100, height: 30))
        bottomLabel.text = "仅拖动模式"
        contentView.addSubview(bottomLabel)
        bottomLabel.isUserInteractionEnabled = true
        bottomLabel.fw.addTapGesture { [weak self] _ in
            guard let drawerView = self?.bottomView.fw.drawerView else { return }
            drawerView.scrollViewFilter = { _ in false }
            drawerView.scrollViewPositions = nil
            self?.toggleMenu()
        } customize: { gesture in
            gesture.highlightedAlpha = 0.5
        }
        
        let closeLabel = UILabel(frame: CGRect(x: 50, y: 400, width: 100, height: 30))
        closeLabel.text = "返回"
        closeLabel.isUserInteractionEnabled = true
        closeLabel.fw.addTapGesture { [weak self] _ in
            self?.fw.close()
        } customize: { gesture in
            gesture.highlightedAlpha = 0.5
        }
        contentView.addSubview(closeLabel)
        
        view.addSubview(bottomView)
        bottomView.fw.drawerView(
            .up,
            positions: [NSNumber(value: 100), NSNumber(value: view.fw.height / 2.0), NSNumber(value: view.fw.height - 100.0)],
            kickbackHeight: 25
        ) { [weak self] position, finished in
            self?.navigationItem.title = "DrawerView-\(String(format: "%.2f", position))"
        }
        toggleInset()
        
        view.addSubview(contentView)
        contentView.fw.drawerView(
            .right,
            positions: [NSNumber(value: -FW.screenWidth / 2.0), NSNumber(value: 0)],
            kickbackHeight: 25
        )
    }
    
    func toggleMenu() {
        guard let drawerView = contentView.fw.drawerView else { return }
        let position = drawerView.position == drawerView.openPosition ? drawerView.closePosition : drawerView.openPosition
        drawerView.setPosition(position, animated: true)
    }
    
    func toggleInset() {
        guard let drawerView = bottomView.fw.drawerView else { return }
        
        if isInset {
            tableView.tableFooterView = nil
            // 使用scrollViewInsets占满底部
            drawerView.scrollViewInsets = canScroll ? { _ in
                return [
                    NSValue(uiEdgeInsets: .zero),
                    NSValue(uiEdgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: drawerView.middlePosition - drawerView.openPosition, right: 0)),
                    NSValue(uiEdgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: drawerView.closePosition - drawerView.openPosition, right: 0)),
                ]
            } : nil
        } else {
            drawerView.scrollViewInsets = nil
            tableView.contentInset = .zero
            // 使用tableFooterView占满底部
            if canScroll {
                let view = UIView(frame: CGRect(x: 0, y: 0, width: FW.screenWidth, height: drawerView.middlePosition - drawerView.openPosition))
                tableView.tableFooterView = view
            } else {
                tableView.tableFooterView = nil
            }
        }
    }
    
    func onPhotoSheet() {
        fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["拍照", "选取相册"]) { [weak self] index in
            if index == 0 {
                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self?.fw.showAlert(title: "未检测到您的摄像头", message: nil)
                    return
                }
                
                self?.fw.showImageCamera(allowsEditing: true, completion: { image, cancel in
                    self?.onPickerResult(image, cancelled: cancel)
                })
            } else {
                self?.fw.showImagePicker(allowsEditing: true) { image, cancel in
                    self?.onPickerResult(image, cancelled: cancel)
                }
            }
        }
    }
    
    func onPickerResult(_ image: UIImage?, cancelled: Bool) {
        guard let cgImage = image?.cgImage else { return }
        
        if #available(iOS 13.0, *) {
            UIWindow.fw.showLoading()
            Detector.recognizeText(in: cgImage) { request in
                request.recognitionLanguages = ["zh-CN", "en-US"]
                request.usesLanguageCorrection = true
            } completion: { results in
                UIWindow.fw.hideLoading()
                let string = NSMutableString()
                for result in results {
                    string.appendFormat("text: %@\nconfidence: %@\n", result.text, NSNumber(value: result.confidence))
                }
                let message = string.length > 0 ? string.copy() : "识别结果为空"
                UIWindow.fw.main?.fw.showAlert(title: "扫描结果", message: message)
            }
        }
    }
    
}
