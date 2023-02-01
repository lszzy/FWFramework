//
//  TestPickerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPickerController: UIViewController, TableViewControllerProtocol {
    
    static var isInitialized = false
    
    func didInitialize() {
        if Self.isInitialized { return }
        Self.isInitialized = true
        
        setupPlugin()
    }
    
    func setupPlugin() {
        PluginManager.registerPlugin(ImagePickerPlugin.self, object: ImagePickerControllerImpl.self)
        ImagePickerControllerImpl.shared.pickerControllerBlock = {
            let pickerController = ImagePickerController()
            pickerController.titleAccessoryImage = FW.iconImage("zmdi-var-caret-down", 24)?.fw.image(tintColor: .white)
            
            let showsCheckedIndexLabel = [true, false].randomElement() ?? false
            pickerController.customCellBlock = { cell, indexPath in
                cell.showsCheckedIndexLabel = showsCheckedIndexLabel
                cell.editedIconImage = FW.iconImage("zmdi-var-edit", 12)?.fw.image(tintColor: .white)
            }
            return pickerController
        }
        ImagePickerControllerImpl.shared.albumControllerBlock = {
            let albumController = ImageAlbumController()
            albumController.customCellBlock = { cell, indexPath in
                cell.checkedMaskColor = UIColor.fw.color(hex: 0xFFFFFF, alpha: 0.1)
            }
            return albumController
        }
        ImagePickerControllerImpl.shared.previewControllerBlock = {
            let previewController = ImagePickerPreviewController()
            previewController.showsOriginImageCheckboxButton = [true, false].randomElement() ?? false
            previewController.showsEditButton = [true, false].randomElement() ?? false
            previewController.customCellBlock = { cell, indexPath in
                cell.editedIconImage = FW.iconImage("zmdi-var-edit", 12)?.fw.image(tintColor: .white)
            }
            return previewController
        }
        ImagePickerControllerImpl.shared.cropControllerBlock = { image in
            let cropController = ImageCropController(image: image)
            cropController.aspectRatioPickerButtonHidden = true
            cropController.cropView.backgroundColor = .black
            cropController.toolbar.tintColor = .white
            cropController.toolbar.cancelTextButton.fw.setImage(FW.iconImage("zmdi-var-close", 22))
            cropController.toolbar.cancelTextButton.setTitle(nil, for: .normal)
            cropController.toolbar.doneTextButton.fw.setImage(FW.iconImage("zmdi-var-check", 22))
            cropController.toolbar.doneTextButton.setTitle(nil, for: .normal)
            return cropController
        }
    }
    
    func setupNavbar() {
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换选取插件", "切换选取样式"], currentIndex: -1, actionBlock: { index in
                if index == 0 {
                    if PluginManager.loadPlugin(ImagePickerPlugin.self) != nil {
                        PluginManager.unloadPlugin(ImagePickerPlugin.self)
                        PluginManager.unregisterPlugin(ImagePickerPlugin.self)
                    } else {
                        self?.setupPlugin()
                    }
                } else {
                    if PluginManager.loadPlugin(ImagePickerPlugin.self) != nil {
                        ImagePickerControllerImpl.shared.showsAlbumController = !ImagePickerControllerImpl.shared.showsAlbumController
                    } else {
                        ImagePickerPluginImpl.shared.photoPickerDisabled = !ImagePickerPluginImpl.shared.photoPickerDisabled
                    }
                }
            })
        }
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            "选择单张图片",
            "选择多张图片",
            "多选仅图片",
            "多选仅视频",
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        cell.textLabel?.text = tableData[indexPath.row] as? String
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let index = indexPath.row
        fw.showImagePicker(filterType: index == 2 ? .image : (index == 3 ? .video : []), selectionLimit: index == 0 ? 1 : 9, allowsEditing: index == 2 ? false : true, customBlock: nil) { [weak self] objects, results, cancel in
            if cancel || objects.count < 1 {
                self?.fw.showMessage(text: "已取消")
            } else {
                self?.fw.showImagePreview(imageURLs: objects, imageInfos: nil, currentIndex: 0)
            }
        }
    }
    
}
