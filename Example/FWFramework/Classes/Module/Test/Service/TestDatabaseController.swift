//
//  TestDatabaseController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2023/7/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import FWFramework

class TestDatabaseModel: NSObject, DatabaseModel {
    @objc var id: Int = 0
    @objc var content: String = ""
    @objc var time: TimeInterval = Date.app.currentTime
    // var tag: String = ""
    
    static func tablePrimaryKey() -> String? {
        return "id"
    }
}

class TestDatabaseController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = TestDatabaseModel
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["新增一条数据", "获取当前版本号", "更新数据库版本", "清空所有数据", "删除数据库文件"], actionBlock: { index in
                if index == 0 {
                    self?.onAdd()
                } else if index == 1 {
                    self?.onVersion()
                } else if index == 2 {
                    self?.onUpdate()
                } else if index == 3 {
                    self?.onClear()
                } else if index == 4 {
                    self?.onDelete()
                }
            })
        }
    }
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableView.app.resetTableStyle()
        tableView.alwaysBounceVertical = true
        tableView.backgroundColor = AppTheme.tableColor
    }
    
    func setupSubviews() {
        tableData = DatabaseManager.query(TestDatabaseModel.self) as! [TestDatabaseModel]
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .subtitle)
        let model = tableData[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(model.id)\n" + model.content
        cell.detailTextLabel?.text = Date(timeIntervalSince1970: model.time).app.stringValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "删除"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let model = tableData[indexPath.row]
            DatabaseManager.delete(model)
            
            setupSubviews()
        }
    }
    
    func onAdd() {
        app.showPrompt(title: "请输入内容", message: nil) { [weak self] string in
            let content = string.app.trimString
            guard !content.isEmpty else { return }
            
            let model = TestDatabaseModel()
            model.content = content
            DatabaseManager.insert(model)
            
            self?.setupSubviews()
        }
    }
    
    func onVersion() {
        let versionString = DatabaseManager.version(withModel: TestDatabaseModel.self)
        if let versionString = versionString {
            app.showAlert(title: "当前版本号", message: versionString)
        } else {
            app.showAlert(title: "数据库不存在", message: nil)
        }
    }
    
    func onUpdate() {
        let versionString = DatabaseManager.version(withModel: TestDatabaseModel.self)
        guard let versionString = versionString else {
            app.showAlert(title: "数据库不存在", message: nil)
            return
        }
        
        let version = Int(versionString) ?? 0
        if version > 1 {
            app.showAlert(title: "数据库无需更新", message: nil)
            return
        }
    }
    
    func onClear() {
        DatabaseManager.clear(TestDatabaseModel.self)
        
        setupSubviews()
    }
    
    func onDelete() {
        DatabaseManager.removeModel(TestDatabaseModel.self)
        
        setupSubviews()
    }
    
}
