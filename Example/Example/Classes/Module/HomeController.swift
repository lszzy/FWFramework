//
//  HomeController.swift
//  Example
//
//  Created by wuyong on 2022/3/23.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

class HomeController: UITableViewController {
    
    // MARK: - Accessor
    private var style: Int = 0 {
        didSet {
            renderStyle()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupConstraints()
        
        renderData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        style = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        style = 0
    }
    
}

// MARK: - Setup
private extension HomeController {
    
    private func setupNavbar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem.fw.item(with: "home.btnStyle".fw.localized, target: self, action: #selector(leftItemClicked(_:)))
        
        let isChinese = Bundle.fw.currentLanguage?.hasPrefix("zh") ?? false
        navigationItem.rightBarButtonItem = UIBarButtonItem.fw.item(with: isChinese ? "中文" : "English", target: self, action: #selector(rightItemClicked(_:)))
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupConstraints() {
        
    }
}

// MARK: - UITableView
extension HomeController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = HomeCell.fw.cell(with: tableView)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableCellSelected(indexPath)
    }
    
}

// MARK: - Action
@objc private extension HomeController {
    
    func leftItemClicked(_ sender: Any) {
        style = style >= 2 ? 0 : style + 1
    }
    
    func rightItemClicked(_ sender: Any) {
        let isChinese = Bundle.fw.currentLanguage?.hasPrefix("zh") ?? false
        Bundle.fw.localizedLanguage = isChinese ? "en" : "zh-Hans"
        
        navigationItem.leftBarButtonItem?.title = "home.btnStyle".fw.localized
        if let buttonItem = sender as? UIBarButtonItem {
            buttonItem.title = isChinese ? "English" : "中文"
        }
        
        renderData()
    }
    
    func tableCellSelected(_ indexPath: IndexPath) {
        FWRouter.openURL(AppRouter.testUrl)
    }
    
}

// MARK: - Private
private extension HomeController {
    
    func renderData() {
        #if APP_PRODUCTION
        let envTitle = "home.envProduction".fw.localized
        #elseif APP_STAGING
        let envTitle = "home.envStaging".fw.localized
        #elseif APP_TESTING
        let envTitle = "home.envTesting".fw.localized
        #else
        let envTitle = "home.envDevelopment".fw.localized
        #endif
        title = "FWFramework - \(envTitle)"
    }
    
    func renderStyle() {
        switch style {
        case 0:
            navigationController?.navigationBar.fw.isTranslucent = false
            navigationController?.navigationBar.fw.backgroundColor = UIColor.fw.themeLight(.fw.color(withHex: 0xFAFAFA), dark: .fw.color(withHex: 0x121212))
        case 1:
            navigationController?.navigationBar.fw.isTranslucent = true
            navigationController?.navigationBar.fw.backgroundColor = UIColor.fw.themeLight(.fw.color(withHex: 0xFAFAFA, alpha: 0.5), dark: .fw.color(withHex: 0x121212, alpha: 0.5))
        default:
            navigationController?.navigationBar.fw.isTranslucent = false
            navigationController?.navigationBar.fw.backgroundTransparent = true
        }
    }
    
}

// MARK: - HomeCell
private class HomeCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .fw.randomColor
        
        let testLabel = UILabel()
        testLabel.textColor = .white
        testLabel.text = "test.title".fw.localized
        contentView.addSubview(testLabel)
        testLabel.fw.layoutMaker { make in
            make.edges(UIEdgeInsets(top: 45, left: 15, bottom: 45, right: 15))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
