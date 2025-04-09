//
//  ActivityViewController.swift
//  HH
//
//  Created by Isha Karankale on 08/03/25.
//

import UIKit

class ActivityViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Activities"

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        
        print("Hellow")
    }
    
    
    @IBAction func deleteButtonClicked(_ sender: UIButton) {
        print("Delete")
    }
    
    
    @IBAction func updateButtonClicked(_ sender: UIButton) {
        print("update")
    }
    
    
    @IBAction func viewAllButtonClicked(_ sender: UIButton) {
        print("view All")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
