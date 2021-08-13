//
//  TestAssetViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestAssetViewController: TestViewController, FWTableViewController, FWPhotoBrowserDelegate {
    var albums: [FWAssetGroup] = []
    var photos: [FWAsset] = []
    var isAlbum: Bool = false
    var album: FWAssetGroup = FWAssetGroup()
    
    private lazy var photoBrowser: FWPhotoBrowser = {
        let result = FWPhotoBrowser()
        result.delegate = self
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
                        self?.photoBrowser.picturesCount = self?.photos.count ?? 0
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
    
    func photoBrowser(_ photoBrowser: FWPhotoBrowser, asyncUrlFor index: Int, completionHandler: @escaping (Any?) -> Void) {
        let photo = photos[index]
        photo.requestPreviewImage(completion: { image, info in
            completionHandler(image)
        }, withProgressHandler: nil)
    }
    
    func photoBrowser(_ photoBrowser: FWPhotoBrowser, viewFor index: Int) -> Any? {
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
        return cell?.imageView
    }
}
