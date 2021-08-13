//
//  TestAssetViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestAssetViewController: TestViewController, FWTableViewController {
    var albums: [FWAssetGroup] = []
    var photos: [FWAsset] = []
    var isAlbum: Bool = false
    var album: FWAssetGroup = FWAssetGroup()
    
    private lazy var photoBrowser: FWPhotoBrowser = {
        let result = FWPhotoBrowser()
        return result
    }()
    
    private lazy var videoPlayer: FWVideoPlayer = {
        let result = FWVideoPlayer()
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
        fwShowLoading()
        DispatchQueue.global().async { [weak self] in
            self?.album.enumerateAssets { asset in
                if let photo = asset {
                    self?.photos.append(photo)
                } else {
                    DispatchQueue.main.async {
                        self?.fwHideLoading()
                        self?.tableView.reloadData()
                    }
                }
            }
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
                    cell.imageView?.image = image
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
            let photo = photos[indexPath.row]
            if photo.assetType == .video {
                fwShowLoading()
                photo.requestPlayerItem(completion: { [weak self] playerItem, info in
                    self?.fwHideLoading()
                    if let item = playerItem, let video = self?.videoPlayer {
                        video.modalPresentationStyle = .fullScreen
                        video.asset = item.asset
                        video.view.backgroundColor = Theme.backgroundColor
                        let button = FWNavigationButton(image: CoreBundle.imageNamed("close"))
                        button.tintColor = Theme.textColor
                        button.fwAddTouch { sender in
                            FWRouter.closeViewController(animated: true)
                        }
                        video.view.addSubview(button)
                        button.fwLayoutChain.leftToSafeArea(8).topToSafeArea(8)
                        self?.present(video, animated: true, completion: nil)
                    }
                }, withProgressHandler: nil)
            } else {
                fwShowLoading()
                photo.requestPreviewImage(completion: { [weak self] aImage, info in
                    self?.fwHideLoading()
                    if let image = aImage {
                        self?.photoBrowser.pictureUrls = [image]
                        self?.photoBrowser.currentIndex = 0
                        self?.photoBrowser.show()
                    }
                }, withProgressHandler: nil)
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
}
