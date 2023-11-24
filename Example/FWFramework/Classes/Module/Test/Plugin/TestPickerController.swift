//
//  TestPickerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import Photos
import PhotosUI

class TestPickerController: UIViewController, TableViewControllerProtocol {
    
    private var livePhotoResources: AssetLivePhoto.Resources?
    
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
            self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["自定义选取样式", "切换PHPicker展示模式", "切换自定义选择器视频质量", "切换PHPicker导出进度", "清理缓存目录"], currentIndex: -1, actionBlock: { index in
                if index == 0 {
                    self?.setupPlugin()
                } else if index == 1 {
                    if #available(iOS 14.0, *) {
                        if PHPickerViewController.app.pickerConfigurationBlock == nil {
                            PHPickerViewController.app.pickerConfigurationBlock = {
                                var configuration = PHPickerConfiguration()
                                configuration.preferredAssetRepresentationMode = .current
                                return configuration
                            }
                        } else {
                            PHPickerViewController.app.pickerConfigurationBlock = nil
                        }
                    }
                } else if index == 2 {
                    if ImagePickerControllerImpl.shared.videoExportPreset == nil {
                        ImagePickerControllerImpl.shared.videoExportPreset = AVAssetExportPresetHighestQuality
                    } else {
                        ImagePickerControllerImpl.shared.videoExportPreset = nil
                    }
                } else if index == 3 {
                    if ImagePickerPluginImpl.shared.exportProgressBlock == nil {
                        ImagePickerPluginImpl.shared.exportProgressBlock = { controller, finished, total in
                            if finished != total {
                                controller.app.showLoading()
                            } else {
                                controller.app.hideLoading()
                            }
                        }
                    } else {
                        ImagePickerPluginImpl.shared.exportProgressBlock = nil
                    }
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
                    self?.showData(objects)
                }
            }
        } else if index == 4 {
            app.showImagePicker(filterType: .livePhoto, selectionLimit: 1, allowsEditing: false, customBlock: nil) { [weak self] objects, _, _ in
                guard let livePhoto = objects.first as? PHLivePhoto else {
                    self?.app.showMessage(text: "请选择LivePhoto")
                    return
                }
                
                AssetLivePhoto.extractResources(from: livePhoto) { resources in
                    guard let resources = resources else {
                        self?.app.showMessage(text: "导出失败")
                        return
                    }
                    
                    self?.livePhotoResources = resources
                    self?.showData([resources.pairedImage, resources.pairedVideo])
                }
            }
        } else if index == 5 {
            guard let resources = livePhotoResources else {
                self.app.showMessage(text: "请先导出LivePhoto")
                return
            }
            
            AssetLivePhoto.generate(from: resources.pairedImage, videoURL: resources.pairedVideo) { [weak self] progress in
                self?.app.showProgress(progress, text: "合成中...")
            } completion: { [weak self] livePhoto, _ in
                self?.app.hideProgress()
                guard let livePhoto = livePhoto else {
                    self?.app.showMessage(text: "合成失败")
                    return
                }
                
                self?.showData([livePhoto])
            }
        } else if index == 6 {
            guard let resources = livePhotoResources else {
                self.app.showMessage(text: "请先导出LivePhoto")
                return
            }
            
            AssetLivePhoto.saveToLibrary(resources) { [weak self] success, _ in
                self?.app.showMessage(text: success ? "保存成功" : "保存失败")
            }
        }
    }
    
    private func showData(_ results: [Any]) {
        app.showImagePreview(imageURLs: results, imageInfos: results.map({ object in
            var title: String = ""
            if let url = object as? URL, url.isFileURL {
                title = String.app.sizeString(FileManager.app.fileSize(url.path))
            }
            return title
        }), currentIndex: 0, sourceView: nil, placeholderImage: nil, customBlock: { controller in
            guard let controller = controller as? ImagePreviewController else { return }
            
            controller.pageLabelText = { [weak controller] index, count in
                var text = "\(index + 1) / \(count)"
                if let title = controller?.imagePreviewView.imageInfos?.safeElement(index) as? String, !title.isEmpty {
                    text += " - \(title)"
                }
                return text
            }
        })
    }
    
}
