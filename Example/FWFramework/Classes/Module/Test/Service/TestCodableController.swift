//
//  TestCodableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

struct TestCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
}

class TestCodableController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        app.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            ["CodableModel", "onCodableModel"],
        ])
    }
    
}

extension TestCodableController {
    
    @objc func onCodableModel() {
        let model: TestCodableModel? = TestCodableModel.decodeModel(from: [
            "id": 1,
            "name": NSNull(),
            "age": "2",
        ])
        
        var success: Bool = true
        success = success && (model != nil)
        success = success && (model?.id == 1)
        success = success && (model?.name == "")
        success = success && (model?.age == 2)
        
        app.showMessage(text: success ? "测试通过" : "测试失败")
    }
    
}
