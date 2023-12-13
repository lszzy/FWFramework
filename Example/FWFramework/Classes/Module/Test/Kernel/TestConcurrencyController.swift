//
//  TestConcurrencyController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestConcurrencyController: UIViewController, TableViewControllerProtocol {
    
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
            ["Request(Success)", "onRequestSuccess"],
            ["Request(Failure)", "onRequestFailure"],
            ["Request(Cancel)", "onRequestCancel"],
        ])
    }
    
}

extension TestConcurrencyController {
    
    @objc func onRequestSuccess() {
        Task.init {
            let request = TestModelRequest()
            request.autoShowLoading = true
            request.autoShowError = true
            
            let result = try await request.safeResponseModel()
            DispatchQueue.app.mainAsync {
                self.app.showMessage(text: result.name)
            }
        }
    }
    
    @objc func onRequestFailure() {
        Task.init {
            let request = TestModelRequest()
            request.autoShowLoading = true
            request.autoShowError = true
            request.testFailed = true
            
            let result = try await request.safeResponseModel()
            DispatchQueue.app.mainAsync {
                self.app.showMessage(text: result.name)
            }
        }
    }
    
    @objc func onRequestCancel() {
        let task = Task.init {
            let request = TestModelRequest()
            request.autoShowLoading = true
            request.autoShowError = true
            request.requestCancelledBlock { [weak self] _ in
                DispatchQueue.app.mainAsync {
                    self?.app.showMessage(text: "Request Cancelled")
                }
            }
            
            let result = try await request.safeResponseModel()
            DispatchQueue.app.mainAsync {
                self.app.showMessage(text: result.name)
            }
        }
        task.cancel()
    }
    
}
