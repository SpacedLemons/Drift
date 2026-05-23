//
//  ContextPackService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol ContextPackService {
  func fetchContextPacks() async throws -> [ContextPack]
  func saveContextPack(_ contextPack: ContextPack) async throws
  func deleteContextPack(id: UUID) async throws
}

actor LocalContextPackService: ContextPackService {
  private var contextPacks: [ContextPack]

  init(contextPacks: [ContextPack] = []) {
    self.contextPacks = contextPacks
  }

  func fetchContextPacks() async throws -> [ContextPack] {
    contextPacks.sorted { $0.updatedAt > $1.updatedAt }
  }

  func saveContextPack(_ contextPack: ContextPack) async throws {
    contextPacks.removeAll { $0.id == contextPack.id }
    contextPacks.append(contextPack)
  }

  func deleteContextPack(id: UUID) async throws {
    contextPacks.removeAll { $0.id == id }
  }
}
