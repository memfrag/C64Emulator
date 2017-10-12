//
//  Copyright © 2015 Apparata AB. All rights reserved.
//

import Foundation
import GameController

public final class GameControllerManager {
    
    private static let sharedInstance = GameControllerManager()
    
    private var gameControllers: [GCController] = []
    
    private var notificationQueue: OperationQueue?
    
    private var foundGameControllerHandler: ((GCController) -> Void)?
    
    private var lostGameControllerHandler: ((GCController) -> Void)?
    
    public static func searchForGameControllers(_ foundHandler:((GCController) -> Void)?, lostHandler:((GCController) -> Void)?) {
        self.sharedInstance.searchForGameControllers(foundHandler, lostHandler: lostHandler)
    }
    
    private func searchForGameControllers(_ foundHandler:((GCController) -> Void)?, lostHandler:((GCController) -> Void)?) {
        let notificationCenter = NotificationCenter.default
        notificationQueue = OperationQueue()
        
        foundGameControllerHandler = foundHandler
        lostGameControllerHandler = lostHandler
        
        notificationCenter.removeObserver(self)
        
        notificationCenter.addObserver(forName: .GCControllerDidConnect, object: nil, queue: notificationQueue) {
            [weak self] notification in
            if let weakSelf = self {
                weakSelf.setupControllers()
            }
            if let foundHandler = self?.foundGameControllerHandler {
                if let gameController: GCController = notification.object as? GCController {
                    foundHandler(gameController)
                }
            }
        }
        
        notificationCenter.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: notificationQueue) {
            [weak self] notification in
            if let weakSelf = self {
                weakSelf.setupControllers()
            }
            if let lostHandler = self?.foundGameControllerHandler {
                if let gameController: GCController = notification.object as? GCController {
                    lostHandler(gameController)
                }
            }
        }
        
        print("[GameControllerManager] Looking for wireless controllers.")
        GCController.startWirelessControllerDiscovery() {
            // TODO: Probably do something interesting here at some point.
            print("[GameControllerManager] Completed wireless controller discovery")
        }
    }
    
    private func setupControllers() {
        gameControllers = GCController.controllers() as [GCController]
        
        if gameControllers.count == 0 {
            return
        }
        
        print("[GameControllerManager] Found \(gameControllers.count) controllers.")
        
        var availableIndices: [GCControllerPlayerIndex] = [.index1, .index2, .index3, .index4]
        
        // Remove used indices
        for controller in gameControllers {
            if controller.playerIndex != GCControllerPlayerIndex.indexUnset {
                print("[GameControllerManager] Player index already set to \(controller.playerIndex).")
                availableIndices = availableIndices.filter({$0 != controller.playerIndex})
            }
        }
        
        for controller in gameControllers {
            if controller.playerIndex == GCControllerPlayerIndex.indexUnset {
                controller.playerIndex = availableIndices.remove(at: 0)
                print("[GameControllerManager] New controller, assigning player index \(controller.playerIndex)");
            }
        }
        
    }
}
