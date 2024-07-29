//
//  TestEncodeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

enum TestEncodeEnum: Int {
    case `default` = 1
}

struct TestEncodeOption: OptionSet {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let `default`: TestEncodeOption = .init(rawValue: 1 << 0)
}

struct TestEncodeStruct {
    var id: Int = 1
    var name: String = "name"
}

class TestEncodeClass {
    var id: Int = 1
    var name: String = "name"
}

class TestEncodeObject: NSObject, @unchecked Sendable {
    var id: Int = 1
    var name: String = "name"
    var closure: () -> Void = {}
    
    @objc func testFunction() {}
}

class TestEncodeController: UIViewController, TableViewControllerProtocol {
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
   
    func setupSubviews() {
        let encodeList: [[Any]] = [
            ["String", "1", "1"],
            ["Int", "1", 1],
            ["Double", "1.0", 1.0],
            ["NSString", "NSString(string: \"name\")", NSString(string: "name")],
            ["NSNumber", "NSNumber(value: 1)", NSNumber(value: 1)],
            ["NSNull", "NSNull()", NSNull()],
            ["Enum", "TestEncodeEnum.default", TestEncodeEnum.default],
            ["OptionSet", "TestEncodeOption.default", TestEncodeOption.default],
            ["Struct", "TestEncodeStruct()", TestEncodeStruct()],
            ["Class", "TestEncodeClass()", TestEncodeClass()],
            ["NSObject", "TestEncodeObject()", TestEncodeObject()],
            ["AnyClass", "TestEncodeObject.self", TestEncodeObject.self],
            ["Function", "TestEncodeObject.testFunction", TestEncodeObject.testFunction],
            ["Closure", "TestEncodeObject().closure", TestEncodeObject().closure],
            ["Selector", "#selector(TestEncodeObject.testFunction)", #selector(TestEncodeObject.testFunction)],
            ["Struct.Type", "TestEncodeStruct.self", TestEncodeStruct.self],
            ["Class.Type", "TestEncodeClass.self", TestEncodeClass.self],
            ["NSObject.Type", "TestEncodeObject.self", TestEncodeObject.self],
        ]
        tableData.append(contentsOf: encodeList)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowData = tableData[indexPath.row] as! [Any]
        var text = (rowData[0] as! String) + ": " + (rowData[1] as! String)
        text += "\nsafeString: \(APP.safeString(rowData[2]))"
        text += "\nsafeNumber: \(APP.safeNumber(rowData[2]))"
        
        let cell = UITableViewCell.app.cell(tableView: tableView)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = text
        return cell
    }
    
}
