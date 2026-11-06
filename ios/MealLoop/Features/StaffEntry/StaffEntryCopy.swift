#if DEMO_DATA
import Foundation

/// Interface copy for the shared staff entry flow, transcribed from the Figma exports
/// D01_role_selection, D02 / K00 / P01 / S00 What you do sheets and D03 password (design/audit/export_*).
/// This is wording, not data.
enum StaffEntryCopy {
    static let chooseRoleTitle = "Choose your role"
    static let chooseRoleSubtitle = "Select the role for this device."

    static func roleHint(_ role: Role) -> String {
        switch role {
        case .doorScanner: return "Scan entries at the door"
        case .passDesk: return "Check special passes"
        case .kitchenStaff: return "Cooking and waste"
        case .supervisor: return "Start and end the meal"
        default: return ""
        }
    }

    static func roleSymbol(_ role: Role) -> String {
        switch role {
        case .doorScanner: return "qrcode"
        case .passDesk: return "ticket"
        case .kitchenStaff: return "frying.pan"
        case .supervisor: return "checkmark.shield"
        default: return "person"
        }
    }

    struct WhatYouDoItem: Hashable {
        let symbol: String
        let title: String
        let detail: String
    }

    static let whatYouDoTitle = "What you do"
    static let continueTitle = "Continue"
    static let dontShowAgain = "Don't show this again"

    static func whatYouDo(_ role: Role) -> [WhatYouDoItem] {
        switch role {
        case .doorScanner:
            return [
                WhatYouDoItem(symbol: "qrcode", title: "Scan each student's QR", detail: "at the door"),
                WhatYouDoItem(symbol: "keyboard", title: "Can't scan?", detail: "Type the last 4 digits of the SRM ID"),
                WhatYouDoItem(symbol: "flag", title: "A problem at the door?", detail: "Report it in one tap"),
            ]
        case .passDesk:
            return [
                WhatYouDoItem(symbol: "ticket", title: "Check a student's pass",
                              detail: "Type the last 4 digits and match the code and colour on their phone"),
                WhatYouDoItem(symbol: "arrow.right", title: "Pass lost? Ask for a new one", detail: "The pass admin approves it"),
                WhatYouDoItem(symbol: "flag", title: "Problem or food short?", detail: "Report it in one tap"),
            ]
        case .kitchenStaff:
            return [
                WhatYouDoItem(symbol: "person.2", title: "Check the headcount before the meal", detail: "And watch entries during it"),
                WhatYouDoItem(symbol: "exclamationmark.triangle", title: "Running short? Report it in one tap",
                              detail: "Pick the dish and send it to the supervisor"),
                WhatYouDoItem(symbol: "frying.pan", title: "After the meal, record leftovers and plate waste",
                              detail: "You can edit it for 6 hours"),
            ]
        case .supervisor:
            return [
                WhatYouDoItem(symbol: "checkmark", title: "Start and close the meal", detail: "Entries open and stop with you"),
                WhatYouDoItem(symbol: "frying.pan", title: "Follow up shortages", detail: "Mark them resolved when fixed"),
                WhatYouDoItem(symbol: "exclamationmark.triangle", title: "Look after SOS alerts", detail: "Close a case once it is checked"),
            ]
        default:
            return []
        }
    }

    static let enterPasswordTitle = "Enter password"

    static func passwordSubtitle(_ role: Role) -> String {
        "The shared \(MLFormat.roleName(role)) password. Ask your supervisor."
    }

    static let passwordFooter = "Wrong password? You get 3 tries."

    static func wrongPassword(triesLeft: Int) -> String {
        triesLeft == 1 ? "Wrong password. 1 try left." : "Wrong password. \(triesLeft) tries left."
    }

    static let lockedTitle = "Ask your supervisor to reset it."

    static func lockedDetail(role: Role, resetBy: String?) -> String {
        let who = resetBy ?? "your supervisor"
        return "3 wrong tries. This phone cannot try again until \(who) resets the shared \(MLFormat.roleName(role)) password."
    }
}
#endif
