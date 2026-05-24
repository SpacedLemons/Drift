//
//  ConnectedAccountState.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

enum ConnectedAccountState: String, Equatable, Codable, Sendable {
  case notConnected
  case preparing
  case connected
  case unavailable
  case error

  var displayName: String {
    switch self {
    case .notConnected: "Not Connected"
    case .preparing: "Preparing"
    case .connected: "Connected"
    case .unavailable: "Unavailable"
    case .error: "Needs Attention"
    }
  }
}

enum ConnectedAuthMethod: String, CaseIterable, Equatable, Codable, Sendable {
  case passkey
  case signInWithApple

  var displayName: String {
    switch self {
    case .passkey: "Passkey"
    case .signInWithApple: "Sign in with Apple"
    }
  }
}
