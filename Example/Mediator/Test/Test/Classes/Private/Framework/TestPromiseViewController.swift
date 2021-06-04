//
//  TestPromiseViewController.swift
//  Example
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit

@objcMembers class TestPromiseViewController: TestViewController, FWTableViewController {
    func renderTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fwCell(with: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fwPerform(NSSelectorFromString(rowData[1]))
    }
}

extension TestPromiseViewController {
    override func renderData() {
        tableData.addObjects(from: [
            ["then", "onThen"],
            ["await", "onAwait"],
            ["all", "onAll"],
            ["any", "onAny"],
            ["race", "onRace"],
        ])
    }
    
    private static func successPromise(_ value: Int = 0) -> FWPromise {
        return FWPromise { resolve, reject in
            delay(1) {
                resolve(value + 1)
            }
        }
    }
    
    private static func failurePromise() -> FWPromise {
        return FWPromise { completion in
            delay(1) {
                completion(NSError(domain: "test", code: 0, userInfo: nil))
            }
        }
    }
    
    private static func delay(_ time: TimeInterval, block: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            block()
        }
    }
    
    private static func showMessage(_ text: String) {
        DispatchQueue.main.async {
            UIWindow.fwMain?.fwShowMessage(withText: text)
        }
    }
    
    private static var isLoading: Bool = false {
        didSet {
            if isLoading {
                DispatchQueue.main.async {
                    UIWindow.fwMain?.fwShowLoading()
                }
            } else {
                DispatchQueue.main.async {
                    UIWindow.fwMain?.fwHideLoading()
                }
            }
        }
    }
    
    @objc func onThen() {
        Self.isLoading = true
        Self.successPromise().then { value in
            return Self.successPromise(value.fwAsInt)
        }.map({ value in
            return value.fwAsInt + 1
        }).done { value in
            Self.showMessage("done: 3 => \(value.fwAsInt)")
        } catch: { error in
            Self.showMessage("error: \(error)")
        } finally: {
            Self.isLoading = false
        }
    }
    
    @objc func onAwait() {
        Self.isLoading = true
        fw_async {
            var value = try fw_await(Self.successPromise())
            value = try fw_await(Self.successPromise(value.fwAsInt))
            return value
        }.done { value in
            Self.isLoading = false
            Self.showMessage("value: 2 => \(value.fwAsString)")
        }
    }
    
    @objc func onAll() {
        Self.isLoading = true
        FWPromise.all([Self.successPromise(), Self.successPromise(1), [0, 1].randomElement() == 1 ? Self.successPromise(2) : Self.failurePromise()])
            .done { value in
                Self.showMessage("value: 6 => \(value.fwAsString)")
            } catch: { error in
                Self.showMessage("error: \(error)")
            } finally: {
                Self.isLoading = false
            }
    }
    
    @objc func onAny() {
        Self.isLoading = true
        FWPromise.any([Self.successPromise(), Self.successPromise(1), Self.failurePromise()].shuffled())
            .done { value in
                Self.showMessage("value: \(value.fwAsString)")
            } catch: { error in
                Self.showMessage("error: \(error)")
            } finally: {
                Self.isLoading = false
            }
    }
    
    @objc func onRace() {
        Self.isLoading = true
        FWPromise.race([Self.successPromise(), Self.successPromise(1), Self.failurePromise()].shuffled())
            .done { value in
                Self.showMessage("value: \(value.fwAsString)")
            } catch: { error in
                Self.showMessage("error: \(error)")
            } finally: {
                Self.isLoading = false
            }
    }
}
