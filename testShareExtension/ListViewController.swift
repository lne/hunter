//
//  ListViewController.swift
//  testShareExtension
//
//  Created by weidongfeng on 2019/07/08.
//  Copyright © 2019 weidongfeng. All rights reserved.
//

import UIKit

@objc(ListViewControllerDelegate)
protocol ListViewControllerDelegate {
    @objc optional func listViewController(sender: ListViewController, selectedValue: String)
}

class ListViewController: UITableViewController {
    
    struct TableViewValues {
        static let identifier = "Cell"
    }
    
    var itemList: [String] = []
    var selectedValue: String = ""
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: TableViewValues.identifier)
        tableView.backgroundColor = UIColor.clear
        
        self.itemList = ["1", "2", "3", "4", "5"]
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewValues.identifier, forIndexPath: indexPath as IndexPath) as UITableViewCell
        cell.backgroundColor = UIColor.clearColor()
        
        let text: String = self.itemList[indexPath.row]
        
        // 選択したアイテムにチェックマークをつける
        if text == selectedValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        cell.textLabel!.text = text
        
        return cell
    }
    
    var delegate: ListViewControllerDelegate?
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let theDelegate = delegate {
            theDelegate.listViewController!(self, selectedValue: self.itemList[indexPath.row])
        }
    }
}
