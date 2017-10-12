//
//  AppDelegate.swift
//  C64Emulator
//
//  Created by Andy Qua on 10/08/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import UIKit

let Notif_GamesUpdated = Notification.Name("Notif_GamesUpdated")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print( "Requested to open URL - \(url)")
        
        let diskName = url.lastPathComponent

        let destPath = getUserGamesDirectory().appendingPathComponent(diskName)

        // Move file to user games folder
        let fm = FileManager.default
        do {
            try fm.moveItem(at: url, to: URL(fileURLWithPath: destPath))
            let d64 = D64Image()
            d64.readDiskDirectory(destPath)
            
            DatabaseManager.sharedInstance.addDisk(diskName: diskName)
            
            NotificationCenter.default.post(name: Notif_GamesUpdated, object: nil)
        
            if let rnc = window?.rootViewController as? UINavigationController,
                let rvc = rnc.topViewController as? DiskViewController {
                rvc.showDisk( diskPath:destPath )
            }
        } catch let error {
            print( "Can't move file as it already exists - \(diskName) - \(error)")
            
            try? fm.removeItem(at: url)
            return false
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}

    
    func removeAllGames() {
        DatabaseManager.clearDatabase()
        
        // Remove contents of games folder
        let path = getUserGamesDirectory()
        FileManager.default.clearFolderAtPath(path: path)
    }

}

