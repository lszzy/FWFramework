//
//  TableView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UITableView {
    public var tableDelegate: TableViewDelegate {
        get { base.fw_tableDelegate }
        set { base.fw_tableDelegate = newValue }
    }
    
    public static func tableView() -> Base {
        return Base.fw_tableView()
    }
    
    public static func tableView(_ style: UITableView.Style) -> Base {
        return Base.fw_tableView(style)
    }
}
