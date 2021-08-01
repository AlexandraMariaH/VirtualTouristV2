//
//  AppDelegate.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 11.07.21.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      
        dataController.load()
        
        return true
    }

}

