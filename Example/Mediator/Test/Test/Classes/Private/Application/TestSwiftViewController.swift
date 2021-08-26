//
//  TestSwiftViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework
import PhotosUI

@objcMembers class TestSwiftViewController: TestViewController, FWTableViewController {
    override func renderData() {
        tableData.addObjects(from: [
            "FWViewController",
            "FWCollectionViewController",
            "FWScrollViewController",
            "FWTableViewController",
            "FWWebViewController",
            "AVPlayerViewController",
        ])
        if #available(iOS 14, *) {
            tableData.add("PHPickerViewController")
        }
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
        var viewController: UIViewController? = nil
        switch indexPath.row {
        case 1:
            viewController = SwiftTestCollectionViewController()
        case 2:
            viewController = SwiftTestScrollViewController()
        case 3:
            viewController = SwiftTestTableViewController()
        case 4:
            viewController = SwiftTestWebViewController()
        case 5:
            viewController = UIApplication.fwPlayVideo("http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4")
            viewController?.fwVisibleStateChanged = { (vc, state) in
                if state == .didAppear {
                    (vc as? AVPlayerViewController)?.player?.play()
                }
            }
        case 6:
            if #available(iOS 14, *) {
                viewController = SwiftTestPickerViewController()
            }
        default:
            viewController = SwiftTestViewController()
        }
        viewController?.fwNavigationItem.title = tableData.object(at: indexPath.row) as? String
        navigationController?.pushViewController(viewController!, animated: true)
    }
}

@objcMembers class SwiftTestViewController: UIViewController, FWViewController {
    func renderState(_ state: FWViewControllerState, with object: Any?) {
        switch state {
        case .success:
            fwView.fwShowEmpty(withText: object as? String)
        case .failure:
            fwView.fwShowEmpty(withText: (object as? NSError)?.localizedDescription, detail: nil, image: nil, action: "重新加载") { [weak self] (sender) in
                self?.fwView.fwHideEmpty()
                
                self?.renderState(.loading, with: nil)
            }
        case .loading:
            fwView.fwShowLoading(withText: "开始加载")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.fwView.fwHideLoading()
                
                if [0, 1].randomElement() == 1 {
                    self?.renderState(.success, with: "加载成功")
                } else {
                    self?.renderState(.failure, with: NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "加载失败"]))
                }
            }
        case .ready:
            view.backgroundColor = Theme.backgroundColor
            renderState(.loading, with: nil)
        default:
            break;
        }
    }
}

@objcMembers class SwiftTestCollectionViewController: UIViewController, FWCollectionViewController, UICollectionViewDelegateFlowLayout {
    lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.layer.masksToBounds = true
        return contentView
    }()
    
    lazy var flowLayout: FWCollectionViewFlowLayout = {
        let flowLayout = FWCollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.scrollDirection = .horizontal
        flowLayout.columnCount = 4
        flowLayout.rowCount = 3
        return flowLayout
    }()
    
    func renderCollectionViewLayout() -> UICollectionViewLayout {
        return flowLayout
    }
    
    func renderCollectionView() {
        view.backgroundColor = Theme.backgroundColor
        collectionView.backgroundColor = Theme.tableColor
        collectionView.isPagingEnabled = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "view")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "view")
    }
    
    func renderCollectionLayout() {
        fwView.addSubview(contentView)
        contentView.fwLayoutChain.edges(excludingEdge: .bottom).height(200)
        
        collectionView.removeFromSuperview()
        contentView.addSubview(collectionView)
        collectionView.fwLayoutChain.edges(excludingEdge: .bottom).height(200)
    }
    
    func renderModel() {
        fwSetRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] (sender) in
            guard let self = self else { return }
            
            self.flowLayout.itemRenderVertical = !self.flowLayout.itemRenderVertical
            self.collectionView.reloadData()
        }
    }
    
    func renderData() {
        for _ in 0 ..< 18 {
            collectionData.add(UIColor.fwRandom)
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flowLayout.itemRenderCount(collectionData.count)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = collectionData.fwObject(at: indexPath.item) as? UIColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "view", for: indexPath)
        view.backgroundColor = UIColor.fwRandom
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (FWScreenWidth - 40) / 4, height: indexPath.item % 3 == 0 ? 80 : 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 40, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 40, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < collectionData.count {
            fwView.fwShowMessage(withText: "点击section: \(indexPath.section) item: \(indexPath.item)")
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetTotal = FWClamp(0, scrollView.fwContentOffsetX / FWScreenWidth, 3)
        let offsetPercent = offsetTotal - CGFloat(Int(offsetTotal))
        var contentHeight: CGFloat = 0
        if Int(offsetTotal) % 2 == 0 {
            contentHeight = 200 - (120 * offsetPercent)
        } else {
            contentHeight = 80 + (120 * offsetPercent)
        }
        contentView.fwLayoutChain.height(contentHeight)
    }
}

@objcMembers class SwiftTestScrollViewController: UIViewController, FWScrollViewController {
    func renderScrollView() {
        let view = UIView()
        view.backgroundColor = UIColor.fwRandom
        contentView.addSubview(view)
        view.fwLayoutMaker { (make) in
            make.edges().height(1000).width(FWScreenWidth)
        }
    }
}

@objcMembers class SwiftTestTableViewController: UIViewController, FWTableViewController {
    func renderTableView() {
        view.backgroundColor = Theme.backgroundColor
        tableView.backgroundColor = Theme.tableColor
    }
    
    func renderData() {
        tableData.addObjects(from: [0, 1, 2])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}

@objcMembers class SwiftTestWebViewController: UIViewController, FWWebViewController {
    var webItems: NSArray? = {
        return [
            FWIcon.backImage as Any,
            FWIcon.closeImage as Any
        ]
    }()
    
    func renderWebView() {
        webRequest = "http://kvm.wuyong.site/test.php"
    }
}

@available(iOS 14, *)
class SwiftTestPickerViewController: UIViewController, PHPickerViewControllerDelegate {

    // MARK: - PHPickerViewController
    
    @objc func pickPhotos()
    {
        var config = PHPickerConfiguration()
        config.selectionLimit = 3
        config.filter = PHPickerFilter.any(of: [.images, .videos, .livePhotos])
        
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    // MARK: PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        let imv = self.newImageView(image: image)
                        self.imageViews.append(imv)
                        self.scrollView.addSubview(imv)
                        self.view.setNeedsLayout()
                    }
                }
            })
        }
    }
    
    // MARK: - View Setup
    
    lazy var scrollView:UIScrollView = {
        let s = UIScrollView()
        s.backgroundColor = UIColor(white: 0.98, alpha: 1)
        return s
    }()
    
    lazy var button:UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Select Photos", for: .normal)
        b.addTarget(self, action: #selector(pickPhotos), for: .touchUpInside)
        b.sizeToFit()
        return b
    }()
    
    var imageViews = [UIImageView]()
    
    func newImageView(image:UIImage?) -> UIImageView {
        let imv = UIImageView()
        imv.backgroundColor = .black
        imv.image = image
        return imv
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.view.addSubview(self.scrollView)
        self.view.addSubview(self.button)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = self.view.bounds.size
        let safeArea = self.view.safeAreaInsets
        let padding:CGFloat = 10
        
        button.frame = {
            var f = CGRect.zero
            f.size.width = min(size.width - (padding * 2), 250)
            f.size.height = 40
            f.origin.x = (size.width - f.width) * 0.5
            f.origin.y = size.height - (safeArea.bottom + padding + f.size.height)
            return f
        }()
        
        scrollView.frame = {
            var f = CGRect.zero
            f.origin.y = safeArea.top + padding
            f.size.width = size.width - (padding * 2)
            f.size.height = (button.frame.minY - 20) - f.origin.y
            f.origin.x = (size.width - f.width) * 0.5
            return f
        }()
        
        var y:CGFloat = 10
        for imageView in imageViews {
            imageView.frame = {
                var f = CGRect.zero
                f.origin.y = y
                f.size.width = min(scrollView.bounds.width - (padding * 2), 300)
                f.size.height = min(f.width * 0.75, 250)
                f.origin.x = (scrollView.bounds.width - f.size.width) * 0.5
                y += f.size.height + padding
                return f
            }()
        }
        scrollView.contentSize = CGSize(width: 0, height: y)
    }
}
