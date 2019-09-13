//
//  TypeViewController.swift
//  testShareExtension
//
//  Created by weidongfeng on 2019/09/13.
//  Copyright © 2019 weidongfeng. All rights reserved.
//

import UIKit

// *********************************************
// Type View Delegate
// *********************************************
protocol TypeViewDelegate {
    // Close self interface
    func hideTypeView(viewController: TypeViewController, selectedValue: String)
}

// *********************************************
// Type View
// *********************************************
class TypeViewController: UIViewController {
    
    // Table view
    var tableView: UITableView!
    
    // Selected value
    var selectedValue: String = ""
    
    // Data list
    var data: Array<String> = []
    
    // Delegate
    var delegate: TypeViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Table view instance
        tableView = UITableView()
        
        // Table view size
        let viewWidth: CGFloat = view.frame.width - 30
        let viewHeight: CGFloat = view.frame.height
        tableView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        
        // Delegate
        tableView.delegate = self
        tableView.dataSource = self
        
        // Link cell to table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Show nothing when data is empty
        tableView.tableFooterView = UIView(frame: .zero)
        
        // Show table
        view.addSubview(tableView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// *********************************************
// Table View Data Source
// *********************************************
extension TypeViewController: UITableViewDataSource {
    
    // ---------------------------------------------
    // Data source
    // ---------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    // ---------------------------------------------
    // Cell height
    // ---------------------------------------------
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    // ---------------------------------------------
    // Cell generator
    // ---------------------------------------------
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let text = data[indexPath.row]
        cell.textLabel?.text = text
        if text == selectedValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
}

// *********************************************
// Action definition
// *********************************************
extension TypeViewController: UITableViewDelegate {

    // Select row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = data[indexPath.row]
        delegate.hideTypeView(viewController: self, selectedValue: value)
    }
}
