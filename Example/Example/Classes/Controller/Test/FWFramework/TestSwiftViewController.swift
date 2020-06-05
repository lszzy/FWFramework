//
//  TestSwiftViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestSwiftViewController: UIViewController, FWTableViewController {
    func renderView() {
        view.backgroundColor = UIColor.appColorBg()
    }
    
    func renderTableView() {
        tableView.backgroundColor = UIColor.appColorTable()
    }
    
    func renderData() {
        tableData.addObjects(from: [0, 1, 2])
    }
}

extension TestSwiftViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}
