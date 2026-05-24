//
//  SwiftDataSpaceRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataSpaceRepository: SpaceRepository {
  private static let defaultSpacesSeededKey = "defaultSpaces"

  func fetchSpaces() async throws -> [DriftSpace] {
    do {
      try seedDefaultSpacesIfNeeded()
      let descriptor = FetchDescriptor<DriftSpaceEntity>(
        sortBy: [
          SortDescriptor(\.updatedAt, order: .reverse)
        ]
      )
      return sortSpaces(try modelContext.fetch(descriptor).map(DriftSpaceMapper.model))
    } catch {
      throw SpaceRepositoryError.fetchFailed
    }
  }

  func fetchSpace(id: UUID) async throws -> DriftSpace? {
    do {
      return try fetchEntity(id: id).map(DriftSpaceMapper.model)
    } catch {
      throw SpaceRepositoryError.fetchFailed
    }
  }

  func saveSpace(_ space: DriftSpace) async throws {
    do {
      if let entity = try fetchEntity(id: space.id) {
        DriftSpaceMapper.update(entity, with: space)
      } else {
        modelContext.insert(DriftSpaceMapper.entity(from: space))
      }

      try modelContext.save()
    } catch {
      throw SpaceRepositoryError.saveFailed
    }
  }

  func updateSpace(_ space: DriftSpace) async throws {
    do {
      guard let entity = try fetchEntity(id: space.id) else {
        throw SpaceRepositoryError.spaceNotFound
      }

      DriftSpaceMapper.update(entity, with: space)
      try modelContext.save()
    } catch let error as SpaceRepositoryError {
      throw error
    } catch {
      throw SpaceRepositoryError.saveFailed
    }
  }

  func deleteSpace(id: UUID) async throws {
    do {
      guard let entity = try fetchEntity(id: id) else {
        throw SpaceRepositoryError.spaceNotFound
      }

      modelContext.delete(entity)
      try modelContext.save()
    } catch let error as SpaceRepositoryError {
      throw error
    } catch {
      throw SpaceRepositoryError.deleteFailed
    }
  }

  private func seedDefaultSpacesIfNeeded() throws {
    guard try fetchSeedState(key: Self.defaultSpacesSeededKey) == nil else { return }

    var descriptor = FetchDescriptor<DriftSpaceEntity>()
    descriptor.fetchLimit = 1
    guard try modelContext.fetch(descriptor).isEmpty else {
      modelContext.insert(
        DefaultSeedStateEntity(key: Self.defaultSpacesSeededKey, createdAt: Date())
      )
      try modelContext.save()
      return
    }

    DriftSpace.defaultSpaces
      .map(DriftSpaceMapper.entity)
      .forEach(modelContext.insert)
    modelContext.insert(
      DefaultSeedStateEntity(key: Self.defaultSpacesSeededKey, createdAt: Date())
    )
    try modelContext.save()
  }

  private func fetchSeedState(key: String) throws -> DefaultSeedStateEntity? {
    var descriptor = FetchDescriptor<DefaultSeedStateEntity>(
      predicate: #Predicate { entity in
        entity.key == key
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchEntity(id: UUID) throws -> DriftSpaceEntity? {
    var descriptor = FetchDescriptor<DriftSpaceEntity>(
      predicate: #Predicate { entity in
        entity.id == id
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func sortSpaces(_ spaces: [DriftSpace]) -> [DriftSpace] {
    spaces.sorted {
      if $0.isPinned != $1.isPinned {
        return $0.isPinned && !$1.isPinned
      }

      return $0.updatedAt > $1.updatedAt
    }
  }
}

private enum DriftSpaceMapper {
  static func entity(from space: DriftSpace) -> DriftSpaceEntity {
    DriftSpaceEntity(
      id: space.id,
      name: space.name,
      spaceDescription: space.description,
      icon: space.icon,
      accentColorHex: space.accentColorHex,
      createdAt: space.createdAt,
      updatedAt: space.updatedAt,
      isPinned: space.isPinned,
      aiVisibilityRawValue: space.aiVisibility.rawValue
    )
  }

  static func update(_ entity: DriftSpaceEntity, with space: DriftSpace) {
    entity.name = space.name
    entity.spaceDescription = space.description
    entity.icon = space.icon
    entity.accentColorHex = space.accentColorHex
    entity.createdAt = space.createdAt
    entity.updatedAt = space.updatedAt
    entity.isPinned = space.isPinned
    entity.aiVisibilityRawValue = space.aiVisibility.rawValue
  }

  static func model(from entity: DriftSpaceEntity) -> DriftSpace {
    DriftSpace(
      id: entity.id,
      name: entity.name,
      description: entity.spaceDescription,
      icon: entity.icon,
      accentColorHex: entity.accentColorHex,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPinned: entity.isPinned,
      aiVisibility: AIVisibility(rawValue: entity.aiVisibilityRawValue ?? "")
        ?? .privateLocalOnly
    )
  }
}
