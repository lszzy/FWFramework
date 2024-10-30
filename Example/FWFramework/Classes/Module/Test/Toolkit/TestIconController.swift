//
//  TestIconController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestIconController: UIViewController, CollectionViewControllerProtocol {
    typealias CollectionElement = String

    private lazy var searchController: UISearchController = {
        let result = UISearchController(searchResultsController: resultController)
        result.searchResultsUpdater = resultController
        result.searchBar.sizeToFit()
        result.searchBar.placeholder = "搜索"
        return result
    }()

    private lazy var resultController: TestIconResultController = {
        let result = TestIconResultController()
        return result
    }()

    func setupNavbar() {
        navigationItem.searchController = searchController
        // 设置searchBar为tableHeaderView示例：
        // tableView.tableHeaderView = searchController.searchBar
        // 如果进入预编辑状态时searchBar消失，可添加如下代码：
        // definesPresentationContext = true
    }

    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }

    func setupCollectionLayout() {
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.app.layoutChain.edges(toSafeArea: .zero)
    }

    func setupSubviews() {
        collectionData = Array(MaterialIcons.iconMapper().keys)
        resultController.collectionData = collectionData
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestIconCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        let name = collectionData[indexPath.item]
        cell.imageView.app.themeImage = APP.iconImage(name, 60)?.app.themeImage
        cell.nameLabel.text = name
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let name = collectionData[indexPath.item]
        UIPasteboard.general.string = APP.safeString(name)
        app.showMessage(text: name)
    }
}

class TestIconResultController: UIViewController, CollectionViewControllerProtocol, UISearchResultsUpdating {
    typealias CollectionElement = String

    var searchData: [CollectionElement] = []

    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }

    func setupCollectionLayout() {
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.app.layoutChain.edges(toSafeArea: .zero)
    }

    func setupSubviews() {
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestIconCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        let name = searchData[indexPath.item]
        cell.imageView.app.themeImage = APP.iconImage(name, 60)?.app.themeImage
        cell.nameLabel.text = name
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let name = searchData[indexPath.item]
        UIPasteboard.general.string = name
        app.showMessage(text: name)
    }

    func updateSearchResults(for searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false

        var result: [CollectionElement] = []
        let text = searchController.searchBar.text ?? ""
        if text.count > 0 {
            result = collectionData.filter { icon in
                icon.lowercased().contains(text.lowercased())
            }
        }
        searchData = result
        collectionView.reloadData()
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
