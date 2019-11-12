//
//  Global+Log.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import XCGLogger
import Sentry

extension Global {

  // Global logger
  static let log: XCGLogger = {
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "synergy.logger", includeDefaultDestinations: false)

    log.add(destination: systemDestination)
    log.add(destination: fileDestination)
    if let sentryDestination = sentryDestination {
      log.add(destination: sentryDestination)
    }

    return log
  }()

  // Create a destination for the system console log (via NSLog)
  fileprivate static let systemDestination: AppleSystemLogDestination = {
    let systemDestination = AppleSystemLogDestination(identifier: "synergy.logger.syslog")

    // Set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = false
    systemDestination.showThreadName = false
    systemDestination.showLevel = true
    systemDestination.showFileName = false
    systemDestination.showLineNumber = false
    return systemDestination
  }()

  // Create a file log destination
  fileprivate static let fileDestination: AutoRotatingFileDestination = {
    let tmpDirURL = FileManager.default.temporaryDirectory
    let logFileURL = tmpDirURL.appendingPathComponent("app.log")
    print("Write log to: ", logFileURL.absoluteString)
    let fileDestination = AutoRotatingFileDestination(writeToFile: logFileURL, identifier: "synergy.logger.file", shouldAppend: true)

    // Set some configuration options
    fileDestination.outputLevel = .info
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true
    fileDestination.targetMaxLogFiles = 250

    // Process this destination in the background
    fileDestination.logQueue = XCGLogger.logQueue
    return fileDestination
  }()

  // Create a sentry log destination
  fileprivate static let sentryDestination: SentryDestination? = {
    let sentryDestination = SentryDestination(sentryClient: Client.shared!,
                                              queue: DispatchQueue(label: "com.synergy.ios.sentry", qos: .background))
    sentryDestination.outputLevel = .info
    sentryDestination.showLogIdentifier = false
    sentryDestination.showFunctionName = true
    sentryDestination.showThreadName = true
    sentryDestination.showLevel = true
    sentryDestination.showFileName = true
    sentryDestination.showLineNumber = true
    sentryDestination.showDate = true

    return sentryDestination
  }()
}

open class SentryDestination: BaseDestination {
  private let client: Client
  private let logQueue: DispatchQueue?

  public init(sentryClient: Client, queue: DispatchQueue? = nil) {
    self.client = sentryClient
    self.logQueue = queue
    super.init()
  }

  open override func output(logDetails: LogDetails, message: String) {
    let outputClosure = { [weak self] in
      guard let self = self,
      self.isEnabledFor(level: logDetails.level) else { return }

      var sentryLevel: SentrySeverity
      switch logDetails.level {
      case .debug:
        sentryLevel = .debug
      case .info:
        sentryLevel = .info
      case .warning:
        sentryLevel = .warning
      case .severe:
        sentryLevel = .fatal
      case .error:
        sentryLevel = .error
      default:
        return
      }

      let filename = logDetails.fileName.deletingPathExtension.lastPathComponent

      if sentryLevel == .error || sentryLevel == .fatal || sentryLevel == .warning {
        let errorEvent = Event(level: sentryLevel)
        errorEvent.message = logDetails.message
        errorEvent.tags = ["filename": filename,
                           "function": logDetails.functionName]
        errorEvent.extra = logDetails.userInfo
        self.client.appendStacktrace(to: errorEvent)
        self.client.send(event: errorEvent, completion: nil)
      } else {
        let breadcrumb = Breadcrumb(level: sentryLevel, category: filename)
        breadcrumb.message = "[\(logDetails.functionName):\(logDetails.lineNumber)] \(logDetails.message)"
        breadcrumb.data = logDetails.userInfo
        self.client.breadcrumbs.add(breadcrumb)
      }
    }

    if let logQueue = logQueue {
      logQueue.async(execute: outputClosure)
    } else {
      outputClosure()
    }
  }
}

// Send error report to Sentry
struct ErrorReporting {

  // Set current bitmark account number to sentry error report to be informative to debug
  // Set nil to remove user from current session
  public static func setUser(bitmarkAccountNumber: String?, alias: String? = nil) {
    var user: User?

    if let userId = bitmarkAccountNumber {
      user = User(userId: userId)
      user!.username = alias
    }

    Client.shared?.user = user
  }

  // Set current env information
  public static func setEnv() {
    Client.shared?.environment = Credential.valueForKey(keyName: "ENVIRONMENT")

    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      Client.shared?.dist = appVersion
    }
  }
}
