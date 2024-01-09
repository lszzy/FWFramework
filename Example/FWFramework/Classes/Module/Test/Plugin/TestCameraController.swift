//
//  TestCameraController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestCameraController: UIViewController, TableViewControllerProtocol {
    
    // MARK: - Accessor
    private var results: [Any] = []
    private var allowsEditing: Bool = false
    
    // MARK: - Setup
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] sender in
            let allowsEditing = self?.allowsEditing ?? false
            self?.app.showSheet(title: nil, message: nil, cancel: nil, actions: ["浏览已选图片", allowsEditing ? "切换不可编辑" : "切换可编辑"], currentIndex: -1, actionBlock: { index in
                if index == 0 {
                    self?.showData(self?.results ?? [])
                } else if index == 1 {
                    self?.allowsEditing = !allowsEditing
                }
            })
        }
    }
    
    func setupTableView() {
        tableData.append(contentsOf: [
            "照片选择器(单图)",
            "照片选择器(图片)",
            "照片选择器(LivePhoto)",
            "照片选择器(视频)",
            "照片选择器(默认)",
            "照相机(图片)",
            "照相机(LivePhoto)",
            "照相机(视频)",
            "照相机(默认)",
        ])
    }
    
    private func showData(_ results: [Any]) {
        self.results = results
        if results.count < 1 {
            app.showMessage(text: "请选择照片")
            return
        }
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let value = tableData[indexPath.row] as? String
        cell.textLabel?.text = value
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            app.showImagePicker(filterType: .image, selectionLimit: 1, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 1:
            app.showImagePicker(filterType: .image, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 2:
            app.showImagePicker(filterType: .livePhoto, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 3:
            app.showImagePicker(filterType: .video, selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 4:
            app.showImagePicker(filterType: [], selectionLimit: 9, allowsEditing: allowsEditing, customBlock: nil) { [weak self] objects, results, cancel in
                self?.showData(objects)
            }
            break
        case 5:
            app.showImageCamera(filterType: .image, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 6:
            app.showImageCamera(filterType: .livePhoto, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 7:
            app.showImageCamera(filterType: .video, allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        case 8:
            app.showImageCamera(filterType: [], allowsEditing: allowsEditing, customBlock: nil) { [weak self] object, info, cancel in
                self?.showData(object != nil ? [object!] : [])
            }
            break
        default:
            break
        }
    }
    
}
