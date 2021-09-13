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
    
    override func renderModel() {
        fwSetRightBarItem(FWIcon.refreshImage) { [weak self] sender in
            let allowsEditing = self?.allowsEditing ?? false
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: nil, actions: ["浏览已选图片", "切换图片插件", allowsEditing ? "切换不可编辑" : "切换可编辑"], actionBlock: { index in
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
                } else {
                    self?.allowsEditing = !allowsEditing
                }
            })
        }
    }
    
    override func renderData() {
        tableData.addObjects(from: [
            "照片选择器(图片兼容)",
            "照片选择器(LivePhoto兼容)",
            "照片选择器(视频兼容)",
            "照片选择器(图片旧版)",
            "照片选择器(LivePhoto旧版)",
            "照片选择器(视频旧版)",
            "照相机(图片)",
            "照相机(LivePhoto)",
            "照相机(视频)",
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
            let pickerController = PHPhotoLibrary.fwPickerController(with: .image, selectionLimit: 9, shouldDismiss: true) { [weak self] picker, objects, results, cancel in
                self?.showData(objects)
            }
            if let picker = pickerController as? UIImagePickerController {
                picker.allowsEditing = allowsEditing
            }
            present(pickerController!, animated: true)
            break
        case 1:
            let pickerController = PHPhotoLibrary.fwPickerController(with: .livePhoto, selectionLimit: 9, shouldDismiss: true) { [weak self] picker, objects, results, cancel in
                self?.showData(objects)
            }
            if let picker = pickerController as? UIImagePickerController {
                picker.allowsEditing = allowsEditing
            }
            present(pickerController!, animated: true)
            break
        case 2:
            let pickerController = PHPhotoLibrary.fwPickerController(with: .video, selectionLimit: 9, shouldDismiss: true) { [weak self] picker, objects, results, cancel in
                self?.showData(objects)
            }
            if let picker = pickerController as? UIImagePickerController {
                picker.allowsEditing = allowsEditing
            }
            present(pickerController!, animated: true)
            break
        case 3:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .image, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            present(pickerController!, animated: true)
            break
        case 4:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .livePhoto, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            present(pickerController!, animated: true)
            break
        case 5:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .video, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            present(pickerController!, animated: true)
            break
        case 6:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .image, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            present(pickerController!, animated: true)
            break
        case 7:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .livePhoto, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            present(pickerController!, animated: true)
            break
        case 8:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .video, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.allowsEditing = allowsEditing
            pickerController?.cameraCaptureMode = .video
            present(pickerController!, animated: true)
            break
        default:
            break
        }
    }
}
