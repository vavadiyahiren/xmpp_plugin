//
//  UtilityFunctions.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import UIKit

public func getTimeStamp() -> Int64 {
    let value = NSDate().timeIntervalSince1970 * 1000
    return Int64(value)
}

