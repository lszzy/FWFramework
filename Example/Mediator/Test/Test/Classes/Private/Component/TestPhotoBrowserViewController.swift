//
//  TestPhotoBrowserViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestPhotoBrowserViewController: TestViewController, FWTableViewController, FWPhotoBrowserDelegate {
    private var results: [Any] = []
    
    private lazy var photoBrowser: FWPhotoBrowser = {
        let result = FWPhotoBrowser()
        result.delegate = self
        return result
    }()
    
    override func renderModel() {
        fwSetRightBarItem("浏览") { [weak self] sender in
            self?.showData(self?.results ?? [])
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
        
        photoBrowser.pictureUrls = results.map({ result in
            if let url = result as? URL {
                return AVPlayerItem(url: url)
            }
            return result
        })
        photoBrowser.currentIndex = 0
        photoBrowser.show()
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
            present(pickerController!, animated: true)
            break
        case 1:
            let pickerController = PHPhotoLibrary.fwPickerController(with: .livePhoto, selectionLimit: 9, shouldDismiss: true) { [weak self] picker, objects, results, cancel in
                self?.showData(objects)
            }
            present(pickerController!, animated: true)
            break
        case 2:
            let pickerController = PHPhotoLibrary.fwPickerController(with: .video, selectionLimit: 9, shouldDismiss: true) { [weak self] picker, objects, results, cancel in
                self?.showData(objects)
            }
            present(pickerController!, animated: true)
            break
        case 3:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .image, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 4:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .livePhoto, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 5:
            let pickerController = UIImagePickerController.fwPickerController(with: .photoLibrary, filterType: .video, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 6:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .image, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 7:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .livePhoto, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            present(pickerController!, animated: true)
            break
        case 8:
            let pickerController = UIImagePickerController.fwPickerController(with: .camera, filterType: .video, shouldDismiss: true) { [weak self] picker, object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            pickerController?.cameraCaptureMode = .video
            present(pickerController!, animated: true)
            break
        default:
            break
        }
    }
}
