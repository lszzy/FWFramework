//
//  TestIconController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestIconController: UIViewController, CollectionViewControllerProtocol, UISearchBarDelegate {
    
    private var iconClass: Icon.Type = MaterialIcons.self
        
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.tintColor = AppTheme.textColor
        searchBar.fw.contentInset = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        searchBar.fw.backgroundColor = AppTheme.barColor
        searchBar.fw.textFieldBackgroundColor = AppTheme.tableColor
        searchBar.fw.searchIconOffset = 16 - 6
        searchBar.fw.searchTextOffset = 4
        searchBar.fw.searchIconCenter = false
        
        let textField = searchBar.fw.textField
        textField?.font = UIFont.systemFont(ofSize: 12)
        textField?.fw.setCornerRadius(16)
        textField?.fw.touchResign = true
        return searchBar
    }()
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }
    
    func setupCollectionLayout() {
        view.addSubview(searchBar)
        searchBar.fw.layoutChain
            .top(toSafeArea: .zero)
            .horizontal()
            .height(FW.navigationBarHeight)
        collectionView.fw.layoutChain
            .edges(excludingEdge: .top)
            .top(toViewBottom: searchBar)
    }
    
    func setupSubviews() {
        var array = Array(iconClass.iconMapper().keys)
        let text = FW.safeString(searchBar.text?.fw.trimString)
        if text.count > 0 {
            array.removeAll { icon in
                return !icon.lowercased().contains(text.lowercased())
            }
        }
        collectionData.setArray(array)
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.keyboardDismissMode = .onDrag
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestIconCell.fw.cell(collectionView: collectionView, indexPath: indexPath)
        let name = collectionData.object(at: indexPath.item) as? String
        cell.imageView.fw.themeImage = FW.iconImage(name.safeValue, 60)?.fw.themeImage
        cell.nameLabel.text = name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let name = collectionData.object(at: indexPath.item) as? String
        UIPasteboard.general.string = FW.safeString(name)
        fw.showMessage(text: name)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        setupSubviews()
    }
    
}

class TestIconCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    lazy var nameLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.font = FW.font(10)
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppTheme.cellColor
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        imageView.fw.layoutChain.centerX().top().size(CGSize(width: 60, height: 60))
        nameLabel.fw.layoutChain.edges(.zero, excludingEdge: .top)
            .top(toViewBottom: imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
