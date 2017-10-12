
import Foundation

public class C64Joystick {
    
    private enum Port: Int32 {
        case port1 = 0
        case port2 = 1
    }
    
    public enum Button: UInt8 {
        case up = 1
        case down = 2
        case left = 4
        case right = 8
        case button = 16
    }
    
    public static let inPort1 = C64Joystick(port: .port1)
    public static let inPort2 = C64Joystick(port: .port2)
    
    private let port: Port
    private var state: UInt8 = 0
    
    private init(port: Port) {
        self.port = port
    }

    public func isPressed(button: Button) -> Bool {
        return (state & button.rawValue) == button.rawValue
    }

    public func press(_ button: Button, commit: Bool = true) {
        state |= button.rawValue
        if commit {
            commitState()
        }
    }

    public func press(buttons: [Button], commit: Bool = true) {
        for button in buttons {
            state |= button.rawValue
        }
        if commit {
            commitState()
        }
    }
    
    public func release(_ button: Button, commit: Bool = true) {
        state &= ~button.rawValue
        if commit {
            commitState()
        }
    }
    
    public func release(buttons: [Button], commit: Bool = true) {
        for button in buttons {
            state &= ~button.rawValue
        }
        if commit {
            commitState()
        }
    }
    
    public func releaseAll() {
        state = 0
    }
    
    public func commitState() {
        joy_set_bits(port.rawValue, state)
    }
}
