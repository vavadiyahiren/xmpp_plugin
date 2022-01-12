//
//  utilityFunctions.swift
//  xmpp_plugin
//
//  Created by xRStudio on 13/12/21.
//

import Foundation
import Flutter

//MARK:- Notifcation Observers
public func postNotification(Name:Notification.Name, withObject: Any? = nil, userInfo:[AnyHashable : Any]? = nil){
    NotificationCenter.default.post(name: Name, object: withObject, userInfo: userInfo)
}

public func getTimeStamp() -> Int64 {
  let value = NSDate().timeIntervalSince1970 * 1000
  return Int64(value)
}

public func getCurretTime() -> String {
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    return dateFormat.string(from: Date())
}

func printLog<T>(_ message : T) {
    print(message)
}

func addLogger(_ logType : LogType, _ value : Any) {
    var vMess : String = "Time: \(getCurretTime().description)\n"
    vMess += "Action: \(logType.rawValue)\n"
    
    switch logType {
    case .receiveFromFlutter:
        if let data = value as? FlutterMethodCall {
            vMess += "NativeMethod: \(data.method)\n"
            vMess += "Content: \(data.arguments.debugDescription)\n\n"
        }
    
    default:
        vMess += "Time: \(getTimeStamp().description)\n"
        vMess += "Action: \(logType.rawValue)\n"
        vMess += "Content: \(value)\n\n"        
    }
    printLog(vMess)
    
    
    //------------------------------------------------------
    //Add Logger in log-file
    guard let objLogger = APP_DELEGATE.objXMPPLogger else {
        printLog("\(#function) | Not initialize XMPPLogger")
        return
    }
    if !objLogger.isLogEnable {
        printLog("\(#function) | XMPP Logger Disable.")
    }
    AppLogger.log(vMess)
}

class AppLogger {
    static var logFile: URL? {
        guard let objLogger = APP_DELEGATE.objXMPPLogger else { return nil }
        let url = URL(fileURLWithPath: objLogger.logPath)
        return url
    }
    
    static func log(_ message: String) {
        AppLogger.createLogFile(withMessage : message)
    }
    
    private static func createLogFile(withMessage message : String) {
        guard let logFile = AppLogger.logFile else {
            return
        }
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else {
            return
        }
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
        else {
            do {
                try data.write(to: logFile, options: .atomicWrite)
            }
            catch let err {
                print("\(#function) | err: \(err.localizedDescription) | filePath: \(logFile.absoluteString)")
            }
        }
    }
    
    /*func deleteLogFile() {
        guard let logFile = AppLogger.logFile else { return }
        let isFileExists = FileManager.default.fileExists(atPath: logFile.path)
        if !isFileExists { return }
        try? FileManager.default.removeItem(at: logFile)
    }*/
}
