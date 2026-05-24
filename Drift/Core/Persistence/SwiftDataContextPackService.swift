//
//  SwiftDataContextPackService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataContextPackService: ContextPackService {
  func fetchContextPacks() async throws -> [ContextPack] {
    do {
      let descriptor = FetchDescriptor<ContextPackEntity>(
        sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
      )
      return try modelContext.fetch(descriptor).map(ContextPackMapper.model)
    } catch {
      throw ContextPackServiceError.fetchFailed
    }
  }

  func saveContextPack(_ contextPack: ContextPack) async throws {
    do {
      if let entity = try fetchEntity(id: contextPack.id) {
        try ContextPackMapper.update(entity, with: contextPack)
      } else {
        modelContext.insert(try ContextPackMapper.entity(from: contextPack))
      }

      try modelContext.save()
    } catch {
      throw ContextPackServiceError.saveFailed
    }
  }

  func deleteContextPack(id: UUID) async throws {
    do {
      guard let entity = try fetchEntity(id: id) else {
        throw ContextPackServiceError.packNotFound
      }

      modelContext.delete(entity)
      try modelContext.save()
    } catch let error as ContextPackServiceError {
      throw error
    } catch {
      throw ContextPackServiceError.deleteFailed
    }
  }

  private func fetchEntity(id: UUID) throws -> ContextPackEntity? {
    var descriptor = FetchDescriptor<ContextPackEntity>(
      predicate: #Predicate { entity in
        entity.id == id
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}

enum ContextPackServiceError: LocalizedError {
  case fetchFailed
  case saveFailed
  case deleteFailed
  case packNotFound

  var errorDescription: String? {
    switch self {
    case .fetchFailed: "We could not load Context Packs."
    case .saveFailed: "We could not save that Context Pack."
    case .deleteFailed: "We could not delete that Context Pack."
    case .packNotFound: "That Context Pack no longer exists."
    }
  }
}

private enum ContextPackMapper {
  static func entity(from contextPack: ContextPack) throws -> ContextPackEntity {
    ContextPackEntity(
      id: contextPack.id,
      name: contextPack.name,
      packDescription: contextPack.description,
      driftIdsData: try encode(contextPack.driftIds),
      spaceIdsData: try encode(contextPack.spaceIds),
      createdAt: contextPack.createdAt,
      updatedAt: contextPack.updatedAt,
      aiVisibilityRawValue: contextPack.aiVisibility.rawValue
    )
  }

  static func update(_ entity: ContextPackEntity, with contextPack: ContextPack) throws {
    entity.name = contextPack.name
    entity.packDescription = contextPack.description
    entity.driftIdsData = try encode(contextPack.driftIds)
    entity.spaceIdsData = try encode(contextPack.spaceIds)
    entity.createdAt = contextPack.createdAt
    entity.updatedAt = contextPack.updatedAt
    entity.aiVisibilityRawValue = contextPack.aiVisibility.rawValue
  }

  static func model(from entity: ContextPackEntity) -> ContextPack {
    ContextPack(
      id: entity.id,
      name: entity.name,
      description: entity.packDescription,
      driftIds: decode([UUID].self, from: entity.driftIdsData),
      spaceIds: decode([UUID].self, from: entity.spaceIdsData),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      aiVisibility: AIVisibility(rawValue: entity.aiVisibilityRawValue ?? "")
        ?? .privateLocalOnly
    )
  }

  private static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    try JSONEncoder().encode(value)
  }

  private static func decode<Value: Decodable>(_ type: [Value].Type, from data: Data) -> [Value] {
    (try? JSONDecoder().decode(type, from: data)) ?? []
  }
}
