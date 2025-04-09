//
//  AppDelegate.swift
//  TravelManager
//
//  Created by Hemin Patel on 3/31/25.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var managedObjectContext:NSManagedObjectContext?



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        managedObjectContext = self.persistentContainer.viewContext
        
        return true
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TravelManager")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle the error appropriately in a real app
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()


}

