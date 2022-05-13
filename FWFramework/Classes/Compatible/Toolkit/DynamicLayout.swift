//
//  DynamicLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

extension Wrapper where Base: UITableViewCell {
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.__fw.cell(with: tableView, style: style, reuseIdentifier: reuseIdentifier) as! Base
    }
    
}
