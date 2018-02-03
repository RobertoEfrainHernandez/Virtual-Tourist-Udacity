//
//  GCDBlackBox.swift
//  Virtual-Tourist-Udacity
//
//  Created by Roberto Hernandez on 2/2/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import Foundation

// MARK: -- Perform UI Updates on Main
/***************************************************************/

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
