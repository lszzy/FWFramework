//
//  TestAssetViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestAssetViewController: TestViewController, FWTableViewController, FWPhotoBrowserDelegate, FWImagePreviewViewDelegate {
    var albums: [FWAssetGroup] = []
    var photos: [FWAsset] = []
    var isAlbum: Bool = false
    var album: FWAssetGroup = FWAssetGroup()
    var isPreview: Bool = true
    
    private lazy var photoBrowser: FWPhotoBrowser = {
        let result = FWPhotoBrowser()
        result.delegate = self
        return result
    }()
    
    private lazy var imagePreview: FWImagePreviewController = {
        let result = FWImagePreviewController()
        result.imagePreviewView.delegate = self
        result.showsPageLabel = true
        result.dismissingWhenTapped = true
        result.presentingStyle = .zoom
        result.sourceImageView = { [weak self] index in
            let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0))
            return cell?.imageView
        }
        return result
    }()
    
    override func renderModel() {
        if isAlbum {
            loadPhotos()
        } else {
            loadAlbums()
        }
    }
    
    private func loadAlbums() {
        fwShowLoading()
        DispatchQueue.global().async {
            FWAssetManager.sharedInstance.enumerateAllAlbums(with: .all) { [weak self] group in
                if let album = group {
                    self?.albums.append(album)
                } else {
                    DispatchQueue.main.async {
                        self?.fwHideLoading()
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func loadPhotos() {
        fwSetRightBarItem(FWIcon.refreshImage) { [weak self] sender in
            let isPreview = self?.isPreview ?? false
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: "取消", actions: ["\(isPreview ? "- " : "")FWImagePreview", "\(isPreview ? "" : "- ")FWPhotoBrowser"]) { index in
                self?.isPreview = index == 0 ? true : false
            }
        }
        
        fwShowLoading()
        DispatchQueue.global().async { [weak self] in
            self?.album.enumerateAssets(withOptions: .reverse, using: { asset in
                if let photo = asset {
                    self?.photos.append(photo)
                } else {
                    DispatchQueue.main.async {
                        self?.fwHideLoading()
                        self?.photoBrowser.picturesCount = self?.photos.count ?? 0
                        self?.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isAlbum ? photos.count : albums.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView, style: .subtitle)
        cell.selectionStyle = .none
        
        if isAlbum {
            cell.accessoryType = .none
            
            let photo = photos[indexPath.row]
            cell.fwTempObject = photo.identifier
            photo.requestThumbnailImage(with: CGSize(width: 88, height: 88)) { image, info in
                if cell.fwTempObject.fwAsString == photo.identifier {
                    cell.imageView?.image = image?.fwImage(withScale: CGSize(width: 88, height: 88), contentMode: .scaleAspectFill)
                } else {
                    cell.imageView?.image = nil
                }
            }
            photo.assetSize { size in
                if cell.fwTempObject.fwAsString == photo.identifier {
                    cell.textLabel?.text = NSString.fwSizeString(UInt(size))
                } else {
                    cell.textLabel?.text = nil
                }
            }
            
            if photo.assetType == .video {
                cell.detailTextLabel?.text = NSDate.fwFormatDuration(photo.duration(), hasHour: false)
            } else if photo.assetType == .audio {
                cell.detailTextLabel?.text = "audio"
            } else if photo.assetSubType == .livePhoto {
                cell.detailTextLabel?.text = "livePhoto"
            } else if photo.assetSubType == .GIF {
                cell.detailTextLabel?.text = "gif"
            } else {
                cell.detailTextLabel?.text = nil
            }
        } else {
            cell.accessoryType = .disclosureIndicator
            
            let album = albums[indexPath.row]
            cell.textLabel?.text = album.name()
            cell.imageView?.image = album.posterImage(with: CGSize(width: 88, height: 88))
            cell.detailTextLabel?.text = "\(album.numberOfAssets())"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAlbum {
            if isPreview {
                self.imagePreview.imagePreviewView.currentImageIndex = indexPath.row
                present(self.imagePreview, animated: true, completion: nil)
            } else {
                let cell = tableView.cellForRow(at: indexPath)
                self.photoBrowser.currentIndex = indexPath.row
                self.photoBrowser.show(from: cell?.imageView)
            }
        } else {
            let album = albums[indexPath.row]
            let viewController = TestAssetViewController()
            viewController.fwNavigationItem.title = album.name()
            viewController.album = album
            viewController.isAlbum = true
            fwOpen(viewController, animated: true)
        }
    }
    
    // MARK: - FWPhotoBrowserDelegate
    
    func photoBrowser(_ photoBrowser: FWPhotoBrowser, loadPhotoFor index: Int, photoView: FWPhotoView) {
        let photo = photos[index]
        if photo.assetSubType == .GIF {
            photo.requestImageData { data, info, _, _ in
                photoView.urlString = UIImage.fwImage(with:data)
            }
        } else if photo.assetSubType == .livePhoto {
            photo.requestLivePhoto { livePhoto, info in
                photoView.urlString = livePhoto
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    photoView.progress = CGFloat(progress)
                }
            }
        } else if photo.assetType == .video {
            photo.requestPlayerItem { playerItem, info in
                photoView.urlString = playerItem
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    photoView.progress = CGFloat(progress)
                }
            }
        } else {
            photoView.progress = 0.01
            photo.requestPreviewImage { image, info in
                photoView.progress = 1
                photoView.urlString = image
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    photoView.progress = CGFloat(progress)
                }
            }
        }
    }
    
    func photoBrowser(_ photoBrowser: FWPhotoBrowser, viewFor index: Int) -> Any? {
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
        return cell?.imageView
    }
    
    // MARK: - FWImagePreviewViewDelegate
    
    func numberOfImages(in imagePreviewView: FWImagePreviewView) -> Int {
        return photos.count
    }
    
    func imagePreviewView(_ imagePreviewView: FWImagePreviewView, renderZoomImageView zoomImageView: FWZoomImageView, at index: Int) {
        let photo = photos[index]
        if photo.assetSubType == .GIF {
            zoomImageView.progress = 0.01
            photo.requestImageData { data, info, _, _ in
                zoomImageView.progress = 1
                zoomImageView.image = UIImage.fwImage(with:data)
            }
        } else if photo.assetSubType == .livePhoto {
            zoomImageView.progress = 0.01
            photo.requestLivePhoto { livePhoto, info in
                zoomImageView.progress = 1
                zoomImageView.livePhoto = livePhoto
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    zoomImageView.progress = CGFloat(progress)
                }
            }
        } else if photo.assetType == .video {
            zoomImageView.progress = 0.01
            photo.requestPlayerItem { playerItem, info in
                zoomImageView.progress = 1
                zoomImageView.videoPlayerItem = playerItem
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    zoomImageView.progress = CGFloat(progress)
                }
            }
        } else {
            zoomImageView.progress = 0.01
            photo.requestPreviewImage { image, info in
                zoomImageView.progress = 1
                zoomImageView.image = image
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    zoomImageView.progress = CGFloat(progress)
                }
            }
        }
    }
}
