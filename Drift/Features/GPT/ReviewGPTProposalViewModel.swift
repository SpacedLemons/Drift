//
//  ReviewGPTProposalViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReviewGPTProposalViewModel {
  @ObservationIgnored
  private let proposalService: any GPTProposalService & Sendable

  private(set) var proposal: DriftProposal
  private(set) var isSaving = false
  private(set) var errorMessage: String?

  var title: String
  var body: String
  var summary: String
  var selectedDriftType: DriftType
  var selectedSpaceId: UUID?
  var tagsText: String

  init(
    proposal: DriftProposal,
    proposalService: any GPTProposalService & Sendable
  ) {
    self.proposal = proposal
    self.proposalService = proposalService
    title = proposal.title
    body = proposal.body
    summary = proposal.summary
    selectedDriftType = proposal.suggestedDriftType
    selectedSpaceId = proposal.suggestedSpaceIds.first ?? proposal.targetSpaceId
    tagsText = proposal.suggestedTags.joined(separator: ", ")
  }

  var editedProposal: DriftProposal {
    var updatedProposal = proposal
    updatedProposal.title = title.trimmedNonEmpty ?? proposal.title
    updatedProposal.body = body.trimmedNonEmpty ?? proposal.body
    updatedProposal.summary = summary.trimmedNonEmpty ?? proposal.summary
    updatedProposal.suggestedDriftType = selectedDriftType
    updatedProposal.suggestedSpaceIds = selectedSpaceId.map { [$0] } ?? []
    updatedProposal.targetSpaceId = selectedSpaceId
    updatedProposal.suggestedTags =
      tagsText
      .split(separator: ",")
      .compactMap { String($0).trimmedNonEmpty }
    updatedProposal.status = .edited
    return updatedProposal
  }

  func accept() async -> DriftProposal? {
    guard !isSaving else { return nil }

    isSaving = true
    errorMessage = nil
    defer { isSaving = false }

    do {
      let savedProposal = try await proposalService.acceptProposal(editedProposal)
      proposal = savedProposal
      return savedProposal
    } catch {
      errorMessage = "We could not save this GPT proposal."
      return nil
    }
  }

  func reject() async -> DriftProposal? {
    guard !isSaving else { return nil }

    isSaving = true
    errorMessage = nil
    defer { isSaving = false }

    do {
      let rejectedProposal = try await proposalService.rejectProposal(proposal)
      proposal = rejectedProposal
      return rejectedProposal
    } catch {
      errorMessage = "We could not reject this GPT proposal."
      return nil
    }
  }
}
