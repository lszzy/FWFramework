//
//  TestPhotoBrowserViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestPhotoBrowserViewController: TestViewController, FWTableViewController {
    private var results: [Any] = []
    private var allowsEditing: Bool = false
    private var isFullscreen: Bool = false
    
    override func renderModel() {
        fwSetRightBarItem(FWIcon.refreshImage) { [weak self] sender in
            let allowsEditing = self?.allowsEditing ?? false
            let isFullscreen = self?.isFullscreen ?? false
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: nil, actions: ["浏览已选图片", "切换图片插件", allowsEditing ? "切换不可编辑" : "切换可编辑", FWImagePickerPluginImpl.sharedInstance.cropControllerEnabled ? "切换系统裁剪" : "切换自定义裁剪", isFullscreen ? "默认弹出样式" : "全屏弹出样式"], actionBlock: { index in
                if index == 0 {
                    self?.showData(self?.results ?? [])
                } else if index == 1 {
                    let plugin = FWPluginManager.loadPlugin(FWImagePreviewPlugin.self)
                    if plugin != nil {
                        FWPluginManager.unloadPlugin(FWImagePreviewPlugin.self)
                        FWPluginManager.unregisterPlugin(FWImagePreviewPlugin.self)
                    } else {
                        FWPluginManager.registerPlugin(FWImagePreviewPlugin.self, with: FWPhotoBrowserPlugin.self)
                    }
                } else if index == 2 {
                    self?.allowsEditing = !allowsEditing
                } else if index == 3 {
                    FWImagePickerPluginImpl.sharedInstance.cropControllerEnabled = !FWImagePickerPluginImpl.sharedInstance.cropControllerEnabled;
                } else {
                    self?.isFullscreen = !isFullscreen
                    if self?.isFullscreen ?? false {
                        FWImagePickerPluginImpl.sharedInstance.customBlock = { viewController in
                            viewController.modalPresentationStyle = .fullScreen
                        }
                    } else {
                        FWImagePickerPluginImpl.sharedInstance.customBlock = nil
                    }
                }
            })
        }
    }
    
    override func renderData() {
        tableData.addObjects(from: [
            "照片选择器(图片)",
            "照片选择器(LivePhoto)",
            "照片选择器(视频)",
            "照片选择器(默认)",
            "照片选择器(图片-旧版)",
            "照片选择器(LivePhoto-旧版)",
            "照片选择器(视频-旧版)",
            "照片选择器(默认-旧版)",
            "照相机(图片)",
            "照相机(LivePhoto)",
            "照相机(视频)",
            "照相机(默认)",
        ])
    }
    
    private func showData(_ results: [Any]) {
        self.results = results
        if results.count < 1 {
            fwShowMessage(withText: "请选择照片")
            return
        }
        
        fwShowImagePreview(withImageURLs: results.map({ result in
            if let url = result as? URL {
                return AVPlayerItem(url: url)
            }
            return result
        }), currentIndex: 0, sourceView: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView)
        let value = tableData.object(at: indexPath.row) as? String
        cell.textLabel?.text = value
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            fwShowImagePicker(with: .image, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 1:
            fwShowImagePicker(with: .livePhoto, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 2:
            fwShowImagePicker(with: .video, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 3:
            fwShowImagePicker(with: [], selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 4:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .image, allowsEditing: allowsEditing, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 5:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .livePhoto, allowsEditing: allowsEditing, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 6:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .video, allowsEditing: allowsEditing, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 7:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: [], allowsEditing: allowsEditing, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 8:
            fwShowImageCamera(with: .image, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 9:
            fwShowImageCamera(with: .livePhoto, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 10:
            fwShowImageCamera(with: .video, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 11:
            fwShowImageCamera(with: [], allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        default:
            break
        }
    }
}
