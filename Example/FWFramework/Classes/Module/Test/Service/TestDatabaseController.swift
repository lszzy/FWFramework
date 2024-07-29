//
//  TestDatabaseController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2023/7/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import FWFramework

class TestDatabaseModel: NSObject, DatabaseModel {
    // 用于模拟数据库结构更新
    nonisolated(unsafe) static var isLatest: Bool = false
    
    @objc var id: Int = 0
    @objc var content: String = ""
    @objc var time: TimeInterval = Date.app.currentTime
    @objc var tag: String = ""
    @objc var tags: [String] = []
    @objc var codings: [TestDatabaseCodingModel] = []
    @objc var archive: TestDatabaseArchivableModel?
    @objc var archives: [TestDatabaseArchivableModel] = []
    
    static func databaseVersion() -> String? {
        return isLatest ? "2.0" : nil
    }
    
    static func databaseMigration(_ versionString: String) {
        let version = versionString.app.safeDouble
        if version < 2.0 {
            DatabaseManager.update(TestDatabaseModel.self, value: "tag = '旧'", where: nil)
        }
        // if version < 3.0 { ... }
    }
    
    static func tablePrimaryKey() -> String? {
        return "id"
    }
    
    static func tablePropertyBlacklist() -> [String]? {
        return isLatest ? nil : ["tag"]
    }
}

class TestDatabaseCodingModel: NSObject, NSSecureCoding {
    @objc var id: Int = 0
    @objc var tag: String = ""
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init()
        id = coder.decodeInteger(forKey: "id")
        tag = coder.decodeObject(forKey: "tag").safeString
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(tag, forKey: "tag")
    }
}

class TestDatabaseArchivableModel: NSObject, Codable, AnyArchivable {
    var id: Int = 0
    var tag: String = ""
    
    required override init() {
        super.init()
    }
}

class TestDatabaseController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = TestDatabaseModel
    
    func didInitialize() {
        let version = DatabaseManager.version(with: TestDatabaseModel.self).safeDouble
        TestDatabaseModel.isLatest = version > 1
    }
    
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
        let count = DatabaseManager.count(TestDatabaseModel.self)
        navigationItem.title = "Database" + (count > 0 ? "-\(count)" : "")
        
        tableData = DatabaseManager.query(TestDatabaseModel.self)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .subtitle)
        cell.selectionStyle = .none
        let model = tableData[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        let tag = !model.tag.isEmpty ? " - [\(model.tag)]" : ""
        let tags = !model.tags.isEmpty ? " - [\(model.tags.joined(separator: ","))]" : ""
        let cods = !model.codings.isEmpty ? " - [\(model.codings.map({ $0.tag }).joined(separator: ","))]" : ""
        let arc = model.archive != nil ? " - [\(model.archive?.tag ?? "")]" : ""
        let arcs = !model.archives.isEmpty ? " - [\(model.archives.map({ $0.tag }).joined(separator: ","))]" : ""
        cell.textLabel?.text = "\(model.id)\(tag)\(tags)\(cods)\(arc)\(arcs)\n" + model.content
        cell.detailTextLabel?.text = Date(timeIntervalSince1970: model.time).app.stringValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = tableData[indexPath.row]
        app.showPrompt(title: "请编辑内容", message: nil) { textField in
            textField.text = model.content
        } confirmBlock: { [weak self] text in
            model.content = text
            DatabaseManager.update(model)
            
            self?.setupSubviews()
        }
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
            model.tag = "新"
            model.tags = ["标签"]
            
            let tagMode = [0, 1, 2].randomElement()!
            if tagMode == 0 {
                let codingModel = TestDatabaseCodingModel()
                codingModel.id = Int(arc4random() % 1000)
                codingModel.tag = "归档1"
                model.codings = [codingModel]
            } else if tagMode == 1 {
                let archivableModel = TestDatabaseArchivableModel()
                archivableModel.id = Int(arc4random() % 1000)
                archivableModel.tag = "归档2"
                model.archive = archivableModel
            } else {
                let archivableModel = TestDatabaseArchivableModel()
                archivableModel.id = Int(arc4random() % 1000)
                archivableModel.tag = "归档3"
                model.archives = [archivableModel]
            }
            
            DatabaseManager.insert(model)
            
            self?.setupSubviews()
        }
    }
    
    func onVersion() {
        let versionString = DatabaseManager.version(with: TestDatabaseModel.self)
        if let versionString = versionString {
            app.showAlert(title: "当前版本号", message: versionString)
        } else {
            app.showAlert(title: "数据库不存在", message: nil)
        }
    }
    
    func onUpdate() {
        let versionString = DatabaseManager.version(with: TestDatabaseModel.self)
        guard let versionString = versionString else {
            app.showAlert(title: "数据库不存在", message: nil)
            return
        }
        
        let version = Double(versionString) ?? 0
        if version > 1 {
            app.showAlert(title: "数据库无需更新", message: nil)
            return
        }
        
        // 数据库下次操作时会自动更新，无需手工调用
        TestDatabaseModel.isLatest = true
        app.showAlert(title: "数据库更新完成", message: nil)
        
        setupSubviews()
    }
    
    func onClear() {
        DatabaseManager.clear(TestDatabaseModel.self)
        
        setupSubviews()
    }
    
    func onDelete() {
        DatabaseManager.removeModel(TestDatabaseModel.self)
        TestDatabaseModel.isLatest = false
        
        setupSubviews()
    }
    
}
