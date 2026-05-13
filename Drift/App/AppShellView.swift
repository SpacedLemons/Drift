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
  @State private var captureCoordinator: CaptureCoordinator
  @State private var settingsCoordinator: SettingsCoordinator
  @State private var selectedTab: AppTab = .journal
  @State private var journalReloadToken = UUID()
  @State private var insightsReloadToken = UUID()

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
          onRecordTapped: coordinator.startCapture
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
      .tabItem { AppTab.journal.label }
      .tag(AppTab.journal)

      NavigationStack {
        InsightsView(
          viewModel: InsightsViewModel(
            journalRepository: environment.dependencies.journalRepository
          ),
          reloadToken: insightsReloadToken
        )
      }
      .tabItem { AppTab.insights.label }
      .tag(AppTab.insights)

      NavigationStack(path: $bindableSettingsCoordinator.path) {
        SettingsView(
          viewModel: SettingsViewModel(
            journalRepository: environment.dependencies.journalRepository,
            transcriptionService: environment.dependencies.transcriptionService,
            subscriptionService: environment.dependencies.subscriptionService,
            exportService: environment.dependencies.exportService,
            imageAttachmentService: environment.dependencies.imageAttachmentService,
            guideService: environment.dependencies.guideService
          ),
          coordinator: settingsCoordinator,
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
    case .appearance:
      AppearanceSettingsView(
        viewModel: AppearanceSettingsViewModel(
          customisationService: environment.dependencies.customisationService,
          subscriptionService: environment.dependencies.subscriptionService
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
        onRecordAgain: coordinator.addAnotherEntry,
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
          coordinator.addAnotherEntry()
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
    insightsReloadToken = UUID()
  }

  @MainActor
  private func handlePendingLaunchAction() {
    guard let action = launchActionStore.consumePendingAction() else { return }

    switch action {
    case .startJournalEntry:
      selectedTab = .journal
      guard coordinator.startCaptureFromReminder() else {
        launchActionStore.reportRoutingError()
        return
      }
    }
  }
}

#Preview {
  AppShellView(
    environment: .preview(),
    coordinator: AppCoordinator(),
    launchActionStore: AppLaunchActionStore()
  )
}
