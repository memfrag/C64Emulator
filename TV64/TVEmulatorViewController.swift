
import Foundation
import UIKit
import GameController

class TVEmulatorViewController: GCEventViewController, VICEApplicationProtocol {
    
    @IBOutlet var _viceView : VICEGLView!
    
    var dataFileURLString = ""
    var program = ""
    
    var _arguments = [String]()
    var _canTerminate = false
    var _dataFilePath = ""
    var _emulationRunning = false
    
    var joystick = C64Joystick.inPort2
    
    deinit {
        if (_emulationRunning) {
            theVICEMachine.stopMachine()
        }
    }
    
    override func viewDidLoad() {
        
        controllerUserInteractionEnabled = false
        
        _emulationRunning = false
        
        setUpGameControllers()

        dataFileURLString = Bundle.main.path(forResource: "Games/twister3", ofType: "prg") ?? ""
        //dataFileURLString = Bundle.main.path(forResource: "Games/Commando", ofType: "d64") ?? ""
        //dataFileURLString = Bundle.main.path(forResource: "Games/Super Cycle", ofType: "d64") ?? ""
        startVICEThread(files:[dataFileURLString], autostart: true)
    }

    func setUpGameControllers() {
        
        print(GCController.controllers().count)
        
        let joystick = self.joystick
        
        guard let gameController = GCController.controllers().first else {
            return
        }
        
        gameController.controllerPausedHandler = { (controller) in
        }
        
        if let microGamepad = gameController.microGamepad {
            microGamepad.reportsAbsoluteDpadValues = true
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = { (gamepad: GCControllerDirectionPad, x: Float, y: Float) in

                print("x \(x) y \(y)")
                
                let deadzone: Float = 0.5
                
                // Deadzone
                if sqrt(x * x + y * y) < deadzone {
                    print("Deadzone")
                    joystick.release(buttons: [.up, .down, .left, .right])
                    return
                }

                joystick.release(buttons: [.up, .down, .left, .right])
                
                if abs(x) < deadzone {
                    if y > 0 {
                        print("Up")
                        joystick.press(.up, commit: false)
                    } else {
                        print("Down")
                        joystick.press(.down, commit: false)
                    }
                } else if abs(y) < deadzone {
                    if x > 0 {
                        print("Right")
                        joystick.press(.right, commit: false)
                    } else {
                        print("Left")
                        joystick.press(.left, commit: false)
                    }
                } else {
                    if y > 0 {
                        print("Up")
                        joystick.press(.up, commit: false)
                    } else {
                        print("Down")
                        joystick.press(.down, commit: false)
                    }
                    
                    if x > 0 {
                        print("Right")
                        joystick.press(.right, commit: false)
                    } else {
                        print("Left")
                        joystick.press(.left, commit: false)
                    }
                }

                joystick.commitState()

            }
            microGamepad.buttonA.pressedChangedHandler = { (button, value, pressed) in
                print("A \(pressed ? "pressed" : "released")")
                if pressed {
                    let isWarpModeEnabled = theVICEMachine.toggleWarpMode()
                    print("Warp Mode: \(isWarpModeEnabled ? "Enabled" : "Disabled")")
                }
            }
            microGamepad.buttonX.pressedChangedHandler = { (button, value, pressed) in
                print("X \(pressed ? "pressed" : "released")")
                if pressed {
                    if !joystick.isPressed(button: .button) {
                        print("Press Button")
                        joystick.press(.button)
                    }
                } else {
                    if joystick.isPressed(button: .button) {
                        print("Release Button")
                        joystick.release(.button)
                    }
                }
            }
        }

        
        /*
        GameControllerManager.searchForGameControllers({ gameController in
            print("Found game controller!")
            gameController.controllerPausedHandler = { (controller) in
            }
            
            if let microGamepad = gameController.microGamepad {
                microGamepad.reportsAbsoluteDpadValues = true
                microGamepad.allowsRotation = true
                microGamepad.dpad.valueChangedHandler = { (gamepad: GCControllerDirectionPad, x: Float, y: Float) in
                    print("dpad x \(x) y \(y)")
                }
                microGamepad.buttonA.pressedChangedHandler = { (button, value, pressed) in
                    print("A pressed")
                }
                microGamepad.buttonX.pressedChangedHandler = { (button, value, pressed) in
                    print("X pressed")
                }
            }
            
            }, lostHandler: {
                gameController in
                print("Lost game controller!")
        })
         */
    }
    
    @IBAction func warpAction(_ sender: UIButton) {
        sender.isSelected = theVICEMachine.toggleWarpMode()
    }
    
    @IBAction func loadAction(_ sender: Any) {
        writeLine(text: "load \"*\",8,1")
    }
    
    @IBAction func runAction(_ sender: Any) {
        writeLine(text: "run")
    }
    
    @IBAction func fireButtonAction(_ sender: UIButton) {
        C64Joystick.inPort1.press(.button)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            C64Joystick.inPort1.release(.button)
        }
    }
    
    @IBAction func fireButton2Action(_ sender: UIButton) {
        C64Joystick.inPort2.press(.button)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            C64Joystick.inPort2.release(.button)
        }
    }
    
    func write(text: String) {
        var i = 0
        for character in text.characters {
            i = i + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5, execute: { [weak self] in
                self?._viceView.insertText(String(character))
            })
        }
    }

    func writeLine(text: String) {
        let line = text + "\r"
        write(text: line)
    }

    // ----------------------------------------------------------------------------
    func startVICEThread(files:[String]?, autostart: Bool = false)
        // ----------------------------------------------------------------------------
    {
        guard let files = files else { return }
        if files.count == 0 {
            return
        }
        
        _canTerminate = false;
        
        // Just pick the first one for now, later on, we might do some better guess by looking
        // at the end of the filenames for _0 or _A or something.
        
        let rootPath = Bundle.main.resourcePath!.appending("/x64")
        
        _dataFilePath = files[0]
        if self.program != "" {
            _dataFilePath = _dataFilePath + ":\(self.program.lowercased())"
            _arguments = [rootPath, "-8", _dataFilePath, "-autostart", _dataFilePath]
        } else {
            if autostart {
                _arguments = [rootPath, "-8", _dataFilePath, "-autostart", _dataFilePath]
            } else {
                _arguments = [rootPath]
            }
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsPathCString = documentsPath.cString(using: String.Encoding.utf8)
        setenv("HOME", documentsPathCString, 1);
        
        
        let viceMachine = VICEMachine.sharedInstance()!
        viceMachine.setMediaFiles(files)
        viceMachine.setAutoStartPath(_dataFilePath)
        
        if self.program == "" && self._dataFilePath != "" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) { [weak self] in
                guard let `self` = self else { return }
                theVICEMachine.machineController().attachDiskImage(8, path: self._dataFilePath)
            }
        }
        
        Thread.detachNewThreadSelector(#selector(VICEMachine.start(_:)), toTarget: viceMachine, with: self)
        
        _emulationRunning = true        
    }
    
    
    
    // ----------------------------------------------------------------------------
    func isRunning() -> Bool
        // ----------------------------------------------------------------------------
    {
        return _emulationRunning;
    }
    
    
    // ----------------------------------------------------------------------------
    func dismiss()
        // ----------------------------------------------------------------------------
    {
        if (!self.isBeingDismissed) {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    //MARK VICE Application Protocol implementation
    // ----------------------------------------------------------------------------
    func arguments() -> [Any]! {
        return _arguments
    }
    
    func viceView() -> VICEGLView! {
        return _viceView
    }
    
    
    func setMachine(_ aMachineObject: Any!) {
    }
    
    
    func machineDidStop() {
        _canTerminate = true
        _emulationRunning = false
        
        self.dismiss()
    }
    
    
    func createCanvas(_ canvasPtr: Data!, with size: CGSize) {
    }
    
    func destroyCanvas(_ canvasPtr: Data!) {
    }
    
    
    func resizeCanvas(_ canvasPtr: Data!, with size: CGSize) {
        /*
        if INTERFACE_IS_PHONE()
        {
            if (UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)) {
                self.setPortraitViceViewFrame(duration: 0.1, animCurve: .linear, canvasSize: size)
            } else if (UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)) {
                self.setLandscapeViceViewFrame(duration: 0.1, animCurve: .linear, canvasSize: size)
            }
        }*/
    }
    
    func reconfigureCanvas(_ canvasPtr: Data!) {
    }
    
    func beginLineInput(withPrompt prompt: String!) {
    }
    
    func endLineInput() {
    }
    
    func postRemoteNotification(_ array: [Any]!) {
        let notificationName = array[0] as! String
        let userInfo = array[1] as! [NSObject:AnyObject]
        
        // post notification in our UI thread's default notification center
        NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: self, userInfo: userInfo)
    }
    
    
    func runErrorMessage(_ message: String!) {
        //NSLog(@"ERROR: %@", message);
    }
    
    
    func runWarningMessage(_ message: String!) {
        //NSLog(@"WARNING: %@", message);
    }
    
    
    func runCPUJamDialog(_ message: String!) -> Int32 {
        //self.clickDoneButton(self)
        
        return 0;
    }
    
    
    func runExtendImageDialog() -> Bool {
        return false;
    }
    
    
    func getOpenFileName(_ title: String!, types: [Any]!) -> String! {
        return nil;
    }

}
