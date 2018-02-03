//
//  HelperAlert.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/2/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import Foundation
import UIKit

// MARK: -- Helper Alert Method
/***************************************************************/

extension UIViewController {
    
    // Mark: Alert Method
    func displayAlert(title:String, message:String?) {
        
        if let message = message {
            let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
