//
//  TestPurchaseController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2025/7/2.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import FWFramework
import StoreKit

@available(iOS 15.0, *)
class TestPurchaseController: UIViewController, TableViewControllerProtocol {
    var products: [Product] = []
    var transactions: [Transaction] = []

    func setupNavbar() {
        PurchaseManager.shared.startListening { [weak self] _ in
            self?.reloadData()
        }

        app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["Restore", "Transactions", "Manage"], actionBlock: { [weak self] index in
                if index == 0 {
                    Task {
                        do {
                            let transactions = try await PurchaseManager.shared.restorePurchases()
                            var message = ""
                            for transaction in transactions {
                                message += "\(transaction)\n"
                            }
                            await self?.app.showAlert(title: "Restore", message: message)
                        } catch {
                            await self?.app.showMessage(error: error)
                        }
                    }
                } else if index == 1 {
                    Task {
                        var message = ""
                        for transaction in await PurchaseManager.shared.purchasedTransactions() {
                            message += "\(transaction)\n"
                        }
                        await self?.app.showAlert(title: "Transactions", message: message)
                    }
                } else {
                    Task {
                        do {
                            try await PurchaseManager.shared.manageSubscriptions()
                        } catch {
                            await self?.app.showMessage(error: error)
                        }
                    }
                }
            })
        }
    }

    func setupLayout() {
        Task {
            do {
                let productIds: [String] = ["pro_lifetime", "pro_consumable", "pro_monthly", "pro_yearly"]
                self.products = try await PurchaseManager.shared.products(productIds)

                self.reloadData()
            } catch {
                await self.app.showMessage(error: error)
            }
        }
    }

    func reloadData() {
        Task { @MainActor in
            self.transactions = await PurchaseManager.shared.purchasedTransactions()
            self.tableView.reloadData()
        }
    }

    deinit {
        PurchaseManager.shared.stopListening()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = products[indexPath.row]
        let transaction = transactions.first { $0.productID == product.id }
        let cell = UITableViewCell.app.cell(tableView: tableView, style: UITableViewCell.CellStyle.value1)
        cell.selectionStyle = .none
        cell.textLabel?.text = product.displayName + " (" + product.displayPrice + ")"
        cell.detailTextLabel?.text = transaction != nil ? "Purchased" : "Unpaid"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        app.showSheet(title: nil, message: nil, actions: ["Purchase", "Transaction", "Finish", "Refund"]) { [weak self] index in
            if index == 0 {
                Task {
                    do {
                        let result = try await PurchaseManager.shared.purchase(product)
                        await self?.app.showAlert(title: "Purchase", message: "\(result)")
                    } catch {
                        await self?.app.showMessage(error: error)
                    }
                }
            } else if index == 1 {
                Task {
                    if let transaction = await PurchaseManager.shared.latestTransaction(product.id) {
                        await self?.app.showAlert(title: "Transaction", message: "\(transaction)")
                    } else {
                        await self?.app.showMessage(text: "nil")
                    }
                }
            } else if index == 2 {
                Task {
                    if let transaction = await PurchaseManager.shared.finish(product.id) {
                        await self?.app.showAlert(title: "Finish", message: "\(transaction)")
                        self?.reloadData()
                    } else {
                        await self?.app.showMessage(text: "nil")
                    }
                }
            } else {
                Task {
                    do {
                        let result = try await PurchaseManager.shared.refund(product.id)
                        await self?.app.showAlert(title: "Refund", message: "\(result)")
                    } catch {
                        await self?.app.showMessage(error: error)
                    }
                }
            }
        }
    }
}
