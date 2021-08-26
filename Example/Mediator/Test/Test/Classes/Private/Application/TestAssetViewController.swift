//
//  TestAssetViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

class TestPlayerView: FWVideoPlayerView, FWVideoPlayerDelegate {
    weak var videoPlayer: FWVideoPlayer? {
        didSet {
            videoPlayer?.playerDelegate = self
        }
    }
    
    private lazy var closeButton: FWNavigationButton = {
        let result = FWNavigationButton(image: FWIcon.closeImage)
        result.tintColor = Theme.textColor
        result.fwAddTouch { sender in
            FWRouter.closeViewController(animated: true)
        }
        return result
    }()
    
    private lazy var playButton: FWNavigationButton = {
        let result = FWNavigationButton(image: FWIconImage("octicon-playback-play", 24))
        result.tintColor = Theme.textColor
        result.fwAddTouch { [weak self] sender in
            guard let player = self?.videoPlayer else { return }
            
            if player.playbackState == .playing {
                player.pause()
            } else if player.playbackState == .paused {
                player.playFromCurrentTime()
            } else {
                player.playFromBeginning()
            }
        }
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.backgroundColor
        
        addSubview(closeButton)
        addSubview(playButton)
        closeButton.fwLayoutChain.leftToSafeArea(8).topToSafeArea(8)
        playButton.fwLayoutChain.rightToSafeArea(8).topToSafeArea(8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playerPlaybackStateDidChange(_ player: FWVideoPlayer) {
        if player.playbackState == .playing {
            playButton.setImage(FWIconImage("octicon-playback-pause", 24), for: .normal)
        } else {
            playButton.setImage(FWIconImage("octicon-playback-play", 24), for: .normal)
        }
    }
}

@objcMembers class TestAssetViewController: TestViewController, FWTableViewController, FWPhotoBrowserDelegate {
    var albums: [FWAssetGroup] = []
    var photos: [FWAsset] = []
    var isAlbum: Bool = false
    var album: FWAssetGroup = FWAssetGroup()
    var mockProgress: Bool = false
    var systemPlayer: Bool = false
    
    private lazy var photoBrowser: FWPhotoBrowser = {
        let result = FWPhotoBrowser()
        result.delegate = self
        return result
    }()
    
    private lazy var videoPlayer: FWVideoPlayer = {
        let result = FWVideoPlayer()
        result.modalPresentationStyle = .fullScreen
        let playerView = TestPlayerView(frame: .zero)
        playerView.videoPlayer = result
        result.playerView = playerView
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
        fwSetRightBarItem("切换") { [weak self] sender in
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: "取消", actions: ["模拟进度", "取消模拟进度", "FWVideoPlayer", "系统播放器"], actionBlock: { index in
                if index == 0 {
                    self?.mockProgress = true
                } else if index == 1 {
                    self?.mockProgress = false
                } else if index == 2 {
                    self?.systemPlayer = false
                } else {
                    self?.systemPlayer = true
                }
            })
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
            let photo = photos[indexPath.row]
            if photo.assetType == .video {
                fwShowLoading()
                photo.requestPlayerItem(completion: { [weak self] playerItem, info in
                    self?.fwHideLoading()
                    guard let item = playerItem else { return }
                    if self?.systemPlayer ?? false {
                        if let viewController = UIApplication.fwPlayVideo(item) {
                            self?.present(viewController, animated: true, completion: {
                                viewController.player?.play()
                            })
                        }
                    } else if let video = self?.videoPlayer {
                        video.asset = item.asset
                        self?.present(video, animated: true)
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
        } else if !mockProgress {
            photoView.progress = 0.01
            photo.requestPreviewImage { image, info in
                photoView.progress = 1
                photoView.urlString = image
            } withProgressHandler: { progress, error, stop, info in
                DispatchQueue.main.async {
                    photoView.progress = CGFloat(progress)
                }
            }
        } else {
            let url = "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif?t=\(NSDate.fwCurrentTime)"
            photoView.progress = 0.01
            UIImage.fwDownloadImage(url) { image, error in
                photoView.progress = 1
                photoView.urlString = image
            } progress: { progress in
                photoView.progress = CGFloat(progress)
            }
        }
    }
    
    func photoBrowser(_ photoBrowser: FWPhotoBrowser, viewFor index: Int) -> Any? {
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
        return cell?.imageView
    }
}
