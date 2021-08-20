//
//  TestIconViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

class TestIconCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    lazy var nameLabel: UILabel = {
        let result = UILabel()
        result.textColor = Theme.textColor
        result.font = FWFontSize(10)
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Theme.cellColor
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        imageView.fwLayoutChain.centerX().top().size(CGSize(width: 60, height: 60))
        nameLabel.fwLayoutChain.edges(.zero, excludingEdge: .top)
            .topToBottomOfView(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers class TestIconViewController: TestViewController, FWCollectionViewController, UISearchBarDelegate {
    private var iconClass: FWIcon.Type = Octicons.self
        
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.tintColor = Theme.textColor
        searchBar.fwContentInset = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        searchBar.fwBackgroundColor = Theme.barColor
        searchBar.fwTextFieldBackgroundColor = Theme.tableColor
        searchBar.fwSearchIconOffset = 16 - 6
        searchBar.fwSearchTextOffset = 4
        searchBar.fwSearchIconCenter = false
        
        let textField = searchBar.fwTextField
        textField?.font = UIFont.systemFont(ofSize: 12)
        textField?.fwSetCornerRadius(16)
        textField?.fwTouchResign = true
        return searchBar
    }()
    
    override func renderView() {
        collectionView.backgroundColor = Theme.backgroundColor
        collectionView.fwKeyboardDismissOnDrag = true
    }
    
    func renderCollectionViewLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }
    
    func renderCollectionLayout() {
        fwView.addSubview(searchBar)
        searchBar.fwLayoutChain
            .edges(excludingEdge: .bottom)
            .height(FWNavigationBarHeight)
        collectionView.fwLayoutChain
            .edges(excludingEdge: .top)
            .topToBottomOfView(searchBar)
    }
    
    override func renderData() {
        fwSetRightBarItem(NSStringFromClass(iconClass)) { [weak self] sender in
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: "取消", actions: ["Octicons", "MaterialIcons", "FontAwesome", "FoundationIcons", "IonIcons"], actionBlock: { index in
                if index == 0 {
                    self?.iconClass = Octicons.self
                } else if index == 1 {
                    self?.iconClass = MaterialIcons.self
                } else if index == 2 {
                    self?.iconClass = FontAwesome.self
                } else if index == 3 {
                    self?.iconClass = FoundationIcons.self
                } else {
                    self?.iconClass = IonIcons.self
                }
                self?.renderData()
            })
        }
        
        var array = Array(iconClass.iconMapper().keys)
        let text = FWSafeString(searchBar.text?.fwTrimString)
        if text.count > 0 {
            array.removeAll { icon in
                return !icon.lowercased().contains(text.lowercased())
            }
        }
        collectionData.setArray(array)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestIconCell.fwCell(with: collectionView, indexPath: indexPath)
        let name = collectionData.fwObject(at: indexPath.item) as? String
        cell.imageView.fwThemeImage = FWIconImage(name.fwSafeValue, 60)?.fwTheme
        cell.nameLabel.text = name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let name = collectionData.fwObject(at: indexPath.item) as? String
        UIPasteboard.general.string = FWSafeString(name)
        fwShowMessage(withText: name)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        renderData()
    }
}
