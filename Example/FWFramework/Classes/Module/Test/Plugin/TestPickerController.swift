//
//  TestPickerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPickerController: UIViewController, TableViewControllerProtocol {
    
    private var livePhotoResources: LivePhoto.Resources?
    
    func setupPlugin() {
        ImagePickerControllerImpl.shared.pickerControllerBlock = {
            let pickerController = ImagePickerController()
            pickerController.titleAccessoryImage = APP.iconImage("zmdi-var-caret-down", 24)?.app.image(tintColor: .white)
            
            let showsCheckedIndexLabel = [true, false].randomElement() ?? false
            pickerController.customCellBlock = { cell, indexPath in
                cell.showsCheckedIndexLabel = showsCheckedIndexLabel
                cell.editedIconImage = APP.iconImage("zmdi-var-edit", 12)?.app.image(tintColor: .white)
            }
            return pickerController
        }
        ImagePickerControllerImpl.shared.albumControllerBlock = {
            let albumController = ImageAlbumController()
            albumController.customCellBlock = { cell, indexPath in
                cell.checkedMaskColor = UIColor.app.color(hex: 0xFFFFFF, alpha: 0.1)
            }
            return albumController
        }
        ImagePickerControllerImpl.shared.previewControllerBlock = {
            let previewController = ImagePickerPreviewController()
            previewController.showsOriginImageCheckboxButton = [true, false].randomElement() ?? false
            previewController.showsEditButton = [true, false].randomElement() ?? false
            previewController.customCellBlock = { cell, indexPath in
                cell.editedIconImage = APP.iconImage("zmdi-var-edit", 12)?.app.image(tintColor: .white)
            }
            return previewController
        }
        ImagePickerControllerImpl.shared.cropControllerBlock = { image in
            let cropController = ImageCropController(image: image)
            cropController.aspectRatioPickerButtonHidden = true
            cropController.cropView.backgroundColor = .black
            cropController.toolbar.tintColor = .white
            cropController.toolbar.cancelTextButton.app.setImage(APP.iconImage("zmdi-var-close", 22))
            cropController.toolbar.cancelTextButton.setTitle(nil, for: .normal)
            cropController.toolbar.doneTextButton.app.setImage(APP.iconImage("zmdi-var-check", 22))
            cropController.toolbar.doneTextButton.setTitle(nil, for: .normal)
            return cropController
        }
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["自定义选取样式", "清理缓存目录"], currentIndex: -1, actionBlock: { index in
                if index == 0 {
                    self?.setupPlugin()
                } else {
                    try? FileManager.default.removeItem(atPath: AssetManager.cachePath)
                    self?.app.showMessage(text: "清理完成")
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
            "导出LivePhoto",
            "合成LivePhoto",
            "保存LivePhoto",
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        cell.textLabel?.text = tableData[indexPath.row] as? String
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let index = indexPath.row
        if index < 4 {
            app.showImagePicker(filterType: index == 2 ? .image : (index == 3 ? .video : []), selectionLimit: index == 0 ? 1 : 9, allowsEditing: index == 2 ? false : true, customBlock: nil) { [weak self] objects, results, cancel in
                if cancel || objects.count < 1 {
                    self?.app.showMessage(text: "已取消")
                } else {
                    self?.app.showImagePreview(imageURLs: objects, imageInfos: nil, currentIndex: 0)
                }
            }
        } else if index == 4 {
            app.showImagePicker(filterType: .livePhoto, selectionLimit: 1, allowsEditing: false, customBlock: nil) { [weak self] objects, _, _ in
                guard let livePhoto = objects.first as? PHLivePhoto else {
                    self?.app.showMessage(text: "请选择LivePhoto")
                    return
                }
                
                LivePhoto.extractResources(from: livePhoto) { resources in
                    guard let resources = resources else {
                        self?.app.showMessage(text: "导出失败")
                        return
                    }
                    
                    self?.livePhotoResources = resources
                    self?.app.showImagePreview(imageURLs: [resources.pairedImage, resources.pairedVideo], imageInfos: nil, currentIndex: 0)
                }
            }
        } else if index == 5 {
            guard let resources = livePhotoResources else {
                self.app.showMessage(text: "请先导出LivePhoto")
                return
            }
            
            LivePhoto.generate(from: resources.pairedImage, videoURL: resources.pairedVideo) { [weak self] progress in
                self?.app.showProgress(progress, text: "合成中...")
            } completion: { [weak self] livePhoto, _ in
                self?.app.hideProgress()
                guard let livePhoto = livePhoto else {
                    self?.app.showMessage(text: "合成失败")
                    return
                }
                
                self?.app.showImagePreview(imageURLs: [livePhoto], imageInfos: nil, currentIndex: 0)
            }
        } else if index == 6 {
            guard let resources = livePhotoResources else {
                self.app.showMessage(text: "请先导出LivePhoto")
                return
            }
            
            LivePhoto.saveToLibrary(resources) { [weak self] success, _ in
                self?.app.showMessage(text: success ? "保存成功" : "保存失败")
            }
        }
    }
    
}
