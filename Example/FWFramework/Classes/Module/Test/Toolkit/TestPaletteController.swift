//
//  TestIconController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPaletteController: UIViewController, CollectionViewControllerProtocol {
    typealias CollectionElement = String

    private lazy var searchController: UISearchController = {
        let result = UISearchController(searchResultsController: resultController)
        result.searchResultsUpdater = resultController
        result.searchBar.sizeToFit()
        result.searchBar.placeholder = "搜索"
        return result
    }()

    private lazy var resultController: TestPaletteResultController = {
        let result = TestPaletteResultController()
        return result
    }()

    func setupNavbar() {
        navigationItem.searchController = searchController
        // 设置searchBar为tableHeaderView示例：
        // tableView.tableHeaderView = searchController.searchBar
        // 如果进入预编辑状态时searchBar消失，可添加如下代码：
        // definesPresentationContext = true
        
        app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            self?.app.showSheet(title: "请选择主题", message: nil, actions: ["默认蓝", "霞光紫", "清翠绿", "暖阳橙", "午夜蓝"]) { [weak self] index in
                if index == 0 {
                    Palette.lightTheme = Palette.lightPalette
                    Palette.darkTheme = Palette.darkPalette
                } else if index == 1 {
                    Palette.lightTheme = Palette.purplePalette
                    Palette.darkTheme = Palette.paletteTheme(light: Palette.purplePalette)
                } else if index == 2 {
                    Palette.lightTheme = Palette.greenPalette
                    Palette.darkTheme = Palette.paletteTheme(light: Palette.greenPalette)
                } else if index == 3 {
                    Palette.lightTheme = Palette.orangePalette
                    Palette.darkTheme = Palette.paletteTheme(light: Palette.orangePalette)
                } else if index == 4 {
                    Palette.lightTheme = Palette.bluePalette
                    Palette.darkTheme = Palette.paletteTheme(light: Palette.bluePalette)
                }
                self?.collectionView.reloadData()
            }
        }
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
        collectionData = Array(Palette.lightPalette.keys).sorted(by: { key1, key2 in
            if Palette.paletteExcludes.contains(key1) {
                return Palette.paletteExcludes.contains(key2) ? key1 < key2 : false
            } else if Palette.paletteExcludes.contains(key2) {
                return true
            } else {
                return key1 < key2
            }
        })
        resultController.collectionData = collectionData
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestPaletteCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        let name = collectionData[indexPath.item]
        cell.colorView.backgroundColor = Palette.themeColor(name)
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

class TestPaletteResultController: UIViewController, CollectionViewControllerProtocol, UISearchResultsUpdating {
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
        let cell = TestPaletteCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        let name = searchData[indexPath.item]
        cell.colorView.backgroundColor = Palette.themeColor(name)
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

class TestPaletteCell: UICollectionViewCell {
    lazy var colorView: UIView = {
        let result = UIView()
        result.app.setBorderColor(AppTheme.borderColor, width: UIScreen.app.pointHalf, cornerRadius: 8)
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
        contentView.addSubview(colorView)
        contentView.addSubview(nameLabel)
        colorView.app.layoutChain.centerX().top().size(CGSize(width: 60, height: 60))
        nameLabel.app.layoutChain.edges(.zero, excludingEdge: .top)
            .top(toViewBottom: colorView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
