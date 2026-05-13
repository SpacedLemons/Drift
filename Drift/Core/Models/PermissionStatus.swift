//
//  PermissionStatus.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

enum PermissionStatus: String, Hashable, Sendable {
  case unknown
  case granted
  case denied
  case restricted
}
