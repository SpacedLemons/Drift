//
//  AppShellView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct AppShellView: View {
  let environment: AppEnvironment
  let coordinator: AppCoordinator
  let launchActionStore: AppLaunchActionStore

  @State private var journalHomeViewModel: JournalHomeViewModel
  @State private var spacesViewModel: SpacesViewModel
  @State private var contextPacksViewModel: ContextPacksViewModel
  @State private var timelineViewModel: TimelineViewModel
  @State private var insightsViewModel: InsightsViewModel
  @State private var captureCoordinator: CaptureCoordinator
  @State private var settingsCoordinator: SettingsCoordinator
  @State private var selectedTab: AppTab = .capture
  @State private var timelinePath: [AppRoute] = []
  @State private var journalReloadToken = UUID()
  @State private var spacesReloadToken = UUID()
  @State private var timelineReloadToken = UUID()
  @State private var entryLimitAlert: EntryLimitAlert?

  init(
    environment: AppEnvironment,
    coordinator: AppCoordinator,
    launchActionStore: AppLaunchActionStore = AppLaunchActionStore()
  ) {
    self.environment = environment
    self.coordinator = coordinator
    self.launchActionStore = launchActionStore
    _journalHomeViewModel = State(
      initialValue: JournalHomeViewModel(
        journalRepository: environment.dependencies.journalRepository
      )
    )
    _spacesViewModel = State(
      initialValue: SpacesViewModel(
        spaceRepository: environment.dependencies.spaceRepository,
        driftRepository: environment.dependencies.driftRepository,
        contextPackService: environment.dependencies.contextPackService
      )
    )
    _contextPacksViewModel = State(
      initialValue: ContextPacksViewModel(
        driftRepository: environment.dependencies.driftRepository,
        spaceRepository: environment.dependencies.spaceRepository,
        contextPackService: environment.dependencies.contextPackService,
        contextExportService: environment.dependencies.contextExportService
      )
    )
    _timelineViewModel = State(
      initialValue: TimelineViewModel(
        journalRepository: environment.dependencies.journalRepository
      )
    )
    _insightsViewModel = State(
      initialValue: InsightsViewModel(
        journalRepository: environment.dependencies.journalRepository
      )
    )
    _captureCoordinator = State(
      initialValue: CaptureCoordinator(dependencies: environment.dependencies)
    )
    _settingsCoordinator = State(initialValue: SettingsCoordinator())
  }

  var body: some View {
    @Bindable var bindableCoordinator = coordinator
    @Bindable var bindableSettingsCoordinator = settingsCoordinator

    TabView(selection: $selectedTab) {
      NavigationStack(path: $bindableCoordinator.path) {
        JournalHomeView(
          viewModel: journalHomeViewModel,
          reloadToken: journalReloadToken,
          onEntrySelected: coordinator.showJournalEntry,
          onRecordTapped: {
            requestNewEntry {
              coordinator.startCapture()
            }
          }
        )
        .navigationDestination(for: AppRoute.self) { route in
          switch route {
          case .journalEntry(let id):
            EntryDetailView(
              viewModel: EntryDetailViewModel(
                entryID: id,
                journalRepository: environment.dependencies.journalRepository,
                imageAttachmentService: environment.dependencies.imageAttachmentService,
                customThemeService: environment.dependencies.customThemeService
              ),
              reloadToken: journalReloadToken,
              onEditRequested: {
                coordinator.editJournalEntry(id)
              },
              onEntryChanged: refreshJournalData,
              onEntryDeleted: {
                refreshJournalData()
                coordinator.backToJournal()
              }
            )
          case .editJournalEntry(let id):
            EditEntryView(
              viewModel: EntryDetailViewModel(
                entryID: id,
                journalRepository: environment.dependencies.journalRepository,
                imageAttachmentService: environment.dependencies.imageAttachmentService,
                customThemeService: environment.dependencies.customThemeService
              ),
              onCancel: {
                coordinator.backToEntryDetail(id)
              },
              onSaved: {
                refreshJournalData()
                coordinator.backToEntryDetail(id)
              }
            )
          case .capture(let captureRoute):
            captureDestination(captureRoute)
          }
        }
      }
      .tabItem { AppTab.capture.label }
      .tag(AppTab.capture)

      NavigationStack {
        SpacesView(
          viewModel: spacesViewModel,
          contextPacksViewModel: contextPacksViewModel,
          reloadToken: spacesReloadToken
        )
      }
      .tabItem { AppTab.spaces.label }
      .tag(AppTab.spaces)

      NavigationStack(path: $timelinePath) {
        TimelineView(
          viewModel: timelineViewModel,
          reloadToken: timelineReloadToken,
          moodGraphViewModel: insightsViewModel,
          moodGraphReloadToken: timelineReloadToken,
          onEntrySelected: { entry in
            timelinePath.append(.journalEntry(entry.id))
          }
        )
        .navigationDestination(for: AppRoute.self) { route in
          timelineDestination(route)
        }
      }
      .tabItem { AppTab.timeline.label }
      .tag(AppTab.timeline)

      NavigationStack(path: $bindableSettingsCoordinator.path) {
        SettingsView(
          viewModel: SettingsViewModel(
            journalRepository: environment.dependencies.journalRepository,
            subscriptionService: environment.dependencies.subscriptionService,
            exportService: environment.dependencies.exportService,
            imageAttachmentService: environment.dependencies.imageAttachmentService
          ),
          coordinator: settingsCoordinator,
          onShowPaywall: {
            coordinator.showDriftPlusPaywall()
          },
          onEntriesDeleted: refreshJournalData
        )
        .navigationDestination(for: SettingsRoute.self) { route in
          settingsDestination(route)
        }
      }
      .tabItem { AppTab.settings.label }
      .tag(AppTab.settings)
    }
    .preferredColorScheme(.dark)
    .tint(AppColors.accent)
    .task {
      handlePendingLaunchAction()
    }
    .onChange(of: launchActionStore.pendingAction) {
      handlePendingLaunchAction()
    }
    .alert(
      "Reminder",
      isPresented: Binding(
        get: { launchActionStore.routingErrorMessage != nil },
        set: { if !$0 { launchActionStore.clearRoutingError() } }
      )
    ) {
      Button(
        role: .cancel,
        action: {
          launchActionStore.clearRoutingError()
        },
        label: {
          Text("OK")
        }
      )
    } message: {
      Text(launchActionStore.routingErrorMessage ?? "")
    }
    .alert(
      "Drift Limit",
      isPresented: Binding(
        get: { entryLimitAlert != nil },
        set: { if !$0 { entryLimitAlert = nil } }
      )
    ) {
      Button(
        role: .cancel,
        action: {
          entryLimitAlert = nil
        },
        label: {
          Text("OK")
        }
      )
    } message: {
      Text(entryLimitAlert?.message ?? "")
    }
    .fullScreenCover(
      item: $bindableCoordinator.fullScreenRoute,
      onDismiss: {
        coordinator.dismissFullScreenRoute()
      },
      content: { route in
        switch route {
        case .driftPlus:
          DriftPlusPaywallView(
            viewModel: DriftPlusPaywallViewModel(
              subscriptionService: environment.dependencies.subscriptionService,
              reasonMessage: coordinator.paywallReasonMessage
            )
          )
        }
      }
    )
  }

  @ViewBuilder
  private func settingsDestination(_ route: SettingsRoute) -> some View {
    switch route {
    case .reminders:
      ReminderSettingsView(
        viewModel: ReminderSettingsViewModel(
          reminderService: environment.dependencies.reminderService
        )
      )
    case .voiceTranscription:
      VoiceTranscriptionSettingsView(
        viewModel: VoiceTranscriptionSettingsViewModel(
          transcriptionService: environment.dependencies.transcriptionService,
          audioRecordingService: environment.dependencies.audioRecordingService
        )
      )
    case .appearance:
      AppearanceSettingsView(
        viewModel: AppearanceSettingsViewModel(
          customisationService: environment.dependencies.customisationService,
          subscriptionService: environment.dependencies.subscriptionService
        )
      )
    case .backupRestore:
      BackupSettingsView(
        viewModel: BackupSettingsViewModel(
          backupService: environment.dependencies.backupService
        )
      )
    case .privacy:
      PrivacySettingsView()
    case .about:
      AboutView()
    }
  }

  @ViewBuilder
  private func captureDestination(_ route: CaptureRoute) -> some View {
    switch route {
    case .recording:
      RecordingView(
        viewModel: captureCoordinator.makeRecordingViewModel(),
        onCancel: coordinator.backToJournal,
        onFinished: coordinator.showProcessing
      )
    case .processing(let result):
      ProcessingView(
        viewModel: captureCoordinator.makeProcessingViewModel(recordingResult: result),
        onCancel: coordinator.backToJournal,
        onRecordAgain: {
          requestNewEntry {
            coordinator.addAnotherEntry()
          }
        },
        onPrepared: coordinator.showReview
      )
    case .review(let draft):
      ReviewEntryView(
        viewModel: captureCoordinator.makeReviewEntryViewModel(draft: draft),
        onCancel: coordinator.backToJournal,
        onSaved: { entry in
          refreshJournalData()
          coordinator.showSaved(entry)
        }
      )
    case .saved(let entry):
      SavedEntryView(
        viewModel: captureCoordinator.makeSavedEntryViewModel(entry: entry),
        onViewEntry: {
          refreshJournalData()
          coordinator.viewSavedEntry(entry)
        },
        onAddAnother: {
          refreshJournalData()
          requestNewEntry {
            coordinator.addAnotherEntry()
          }
        },
        onBackToJournal: {
          refreshJournalData()
          coordinator.backToJournal()
        }
      )
    }
  }

  private func refreshJournalData() {
    journalReloadToken = UUID()
    spacesReloadToken = UUID()
    timelineReloadToken = UUID()
  }

  @ViewBuilder
  private func timelineDestination(_ route: AppRoute) -> some View {
    switch route {
    case .journalEntry(let id):
      EntryDetailView(
        viewModel: EntryDetailViewModel(
          entryID: id,
          journalRepository: environment.dependencies.journalRepository,
          imageAttachmentService: environment.dependencies.imageAttachmentService,
          customThemeService: environment.dependencies.customThemeService
        ),
        reloadToken: timelineReloadToken,
        onEditRequested: {
          timelinePath.append(.editJournalEntry(id))
        },
        onEntryChanged: refreshJournalData,
        onEntryDeleted: {
          refreshJournalData()
          timelinePath.removeAll()
        }
      )
    case .editJournalEntry(let id):
      EditEntryView(
        viewModel: EntryDetailViewModel(
          entryID: id,
          journalRepository: environment.dependencies.journalRepository,
          imageAttachmentService: environment.dependencies.imageAttachmentService,
          customThemeService: environment.dependencies.customThemeService
        ),
        onCancel: {
          backToTimelineEntryDetail(id)
        },
        onSaved: {
          refreshJournalData()
          backToTimelineEntryDetail(id)
        }
      )
    case .capture(_):
      EmptyView()
    }
  }

  private func backToTimelineEntryDetail(_ id: UUID) {
    if let detailIndex = timelinePath.lastIndex(of: .journalEntry(id)) {
      timelinePath = Array(timelinePath.prefix(through: detailIndex))
    } else {
      timelinePath = [.journalEntry(id)]
    }
  }

  @MainActor
  private func handlePendingLaunchAction() {
    guard let action = launchActionStore.consumePendingAction() else { return }

    switch action {
    case .startJournalEntry:
      selectedTab = .capture
      requestNewEntry {
        guard coordinator.startCaptureFromReminder() else {
          launchActionStore.reportRoutingError()
          return
        }
      }
    }
  }

  private func requestNewEntry(onAllowed: @escaping @MainActor () -> Void) {
    Task {
      await openNewEntryIfAllowed(onAllowed: onAllowed)
    }
  }

  @MainActor
  private func openNewEntryIfAllowed(onAllowed: @escaping @MainActor () -> Void) async {
    do {
      let result = try await environment.dependencies.dailyEntryLimitService
        .evaluateNewEntryAccess()

      guard result.canCreateEntry else {
        showEntryLimit(result)
        return
      }

      onAllowed()
    } catch let error as DailyEntryLimitError {
      entryLimitAlert = EntryLimitAlert(
        message: error.localizedDescription
      )
    } catch {
      entryLimitAlert = EntryLimitAlert(
        message: DailyEntryLimitError.calculationFailed.localizedDescription
      )
    }
  }

  private func showEntryLimit(_ result: DailyEntryLimitResult) {
    if result.shouldOfferUpgrade {
      coordinator.showDriftPlusPaywall(reasonMessage: result.message)
    } else {
      entryLimitAlert = EntryLimitAlert(
        message: result.message
      )
    }
  }
}

private struct EntryLimitAlert: Identifiable, Equatable {
  let id = UUID()
  let message: String
}

#Preview {
  AppShellView(
    environment: .preview(),
    coordinator: AppCoordinator(),
    launchActionStore: AppLaunchActionStore()
  )
}
