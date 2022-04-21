//
//  ViewController.swift
//  PracticeTest
//
//  Created by Megan Mackay on 4/20/22.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tabBar: UITabBar!
    let contentManager = ContentManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        overrideUserInterfaceStyle = .light
        
        tableView.dataSource = contentManager
        tableView.delegate = contentManager
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        tabBar.selectedItem = tabBar.items?[0]
        
        contentManager.fetchContent {
            print("fetch content completion")
            self.tableView.reloadData()
        }
    }

}
