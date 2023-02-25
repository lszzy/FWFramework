//
//  TableView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UITableView {
    public var tableDelegate: TableViewDelegate {
        return base.fw_tableDelegate
    }
    
    public static func tableView() -> Base {
        return Base.fw_tableView()
    }
    
    public static func tableView(_ style: UITableView.Style) -> Base {
        return Base.fw_tableView(style)
    }
}
