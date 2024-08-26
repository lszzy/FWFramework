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
        searchBar.app.contentInset = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        searchBar.app.backgroundColor = AppTheme.barColor
        searchBar.app.textFieldBackgroundColor = AppTheme.tableColor
        searchBar.app.searchIconOffset = 16 - 6
        searchBar.app.searchTextOffset = 4
        searchBar.app.searchIconCenter = false
        searchBar.app.font = UIFont.systemFont(ofSize: 12)
        searchBar.app.textField.app.setCornerRadius(16)
        searchBar.app.textField.app.touchResign = true
        return searchBar
    }()

    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }

    func setupCollectionLayout() {
        view.addSubview(searchBar)
        searchBar.app.layoutChain
            .top(toSafeArea: .zero)
            .horizontal()
            .height(APP.navigationBarHeight)
        collectionView.app.layoutChain
            .edges(excludingEdge: .top)
            .top(toViewBottom: searchBar)
    }

    func setupSubviews() {
        var array = Array(iconClass.iconMapper().keys)
        let text = APP.safeString(searchBar.text?.app.trimString)
        if text.count > 0 {
            array.removeAll { icon in
                !icon.lowercased().contains(text.lowercased())
            }
        }
        collectionData = array
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.keyboardDismissMode = .onDrag
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestIconCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        let name = collectionData[indexPath.item] as? String
        cell.imageView.app.themeImage = APP.iconImage(name.safeValue, 60)?.app.themeImage
        cell.nameLabel.text = name
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let name = collectionData[indexPath.item] as? String
        UIPasteboard.general.string = APP.safeString(name)
        app.showMessage(text: name)
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
        result.font = APP.font(10)
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppTheme.cellColor
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        imageView.app.layoutChain.centerX().top().size(CGSize(width: 60, height: 60))
        nameLabel.app.layoutChain.edges(.zero, excludingEdge: .top)
            .top(toViewBottom: imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
