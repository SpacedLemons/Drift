//
//  ReviewEntryViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReviewEntryViewModel {
  @ObservationIgnored
  private let draft: ReviewEntryDraft
  @ObservationIgnored
  private let journalRepository: any JournalRepository
  @ObservationIgnored
  private let spaceRepository: any SpaceRepository
  @ObservationIgnored
  private let audioPlaybackService: any AudioPlaybackService
  @ObservationIgnored
  let imageAttachmentService: any ImageAttachmentService
  @ObservationIgnored
  private let customThemeService: any CustomThemeService
  @ObservationIgnored
  private let dailyEntryLimitService: any DailyEntryLimitService
  @ObservationIgnored
  private let calendar: Calendar
  @ObservationIgnored
  private let now: () -> Date
  @ObservationIgnored
  private let fileManager: FileManager
  @ObservationIgnored
  private var playbackTimerTask: Task<Void, Never>?
  @ObservationIgnored
  private var moodHistoryDaysWithEntries: Set<Date> = []

  var title: String
  var transcript: String
  var selectedDriftType: DriftType
  var selectedMood: Mood
  var availableSpaces: [DriftSpace] = []
  var selectedSpaceIds: [UUID] = []
  var selectedThemes: [JournalTheme]
  var selectedCustomThemes: [CustomJournalTheme]
  var availableCustomThemes: [CustomJournalTheme] = []
  var tags: [String]
  var pendingTag = ""
  var pendingCustomThemeName = ""
  var imageAttachments: [JournalImageAttachment] = []
  var selectedDate: Date?
  var selectedMonth: Date
  var selectedMoodTrendRange: MoodTrendRange = .last7Days
  var isCalendarExpanded = false

  private(set) var isSaving = false
  private(set) var isLoadingCustomThemes = false
  private(set) var isLoadingReviewHistory = false
  private(set) var isProcessingImages = false
  private(set) var isPreparingPlayback = false
  private(set) var shouldShowPlaybackSection: Bool
  private(set) var isPlaybackAvailable = false
  private(set) var isPlayingAudio = false
  private(set) var playbackDuration: TimeInterval = 0
  private(set) var playbackCurrentTime: TimeInterval = 0
  private(set) var playbackErrorMessage: String?
  private(set) var errorMessage: String?
  private(set) var reviewHistoryErrorMessage: String?
  private(set) var moodHistoryEntries: [JournalEntry] = []
  private(set) var moodHistorySummary = InsightsSummary.empty
  private(set) var monthTransitionDirection: CalendarMonthTransitionDirection = .none

  init(
    draft: ReviewEntryDraft,
    journalRepository: any JournalRepository,
    spaceRepository: any SpaceRepository = LocalSpaceRepository(),
    audioPlaybackService: any AudioPlaybackService = PreviewAudioPlaybackService(),
    imageAttachmentService: any ImageAttachmentService = PreviewImageAttachmentService(),
    customThemeService: any CustomThemeService = PreviewCustomThemeService(),
    dailyEntryLimitService: any DailyEntryLimitService = PreviewDailyEntryLimitService(),
    preselectedSpaceIds: [UUID] = [],
    calendar: Calendar = .current,
    now: @escaping () -> Date = Date.init,
    fileManager: FileManager = .default
  ) {
    self.draft = draft
    self.journalRepository = journalRepository
    self.spaceRepository = spaceRepository
    self.audioPlaybackService = audioPlaybackService
    self.imageAttachmentService = imageAttachmentService
    self.customThemeService = customThemeService
    self.dailyEntryLimitService = dailyEntryLimitService
    self.calendar = calendar
    self.now = now
    self.fileManager = fileManager
    title = Self.makeInitialTitle(from: draft.transcript)
    transcript = draft.transcript
    selectedDriftType = .reflection
    selectedMood = draft.suggestedMood
    selectedThemes = draft.suggestedThemes
    selectedCustomThemes = []
    tags = draft.tags
    selectedSpaceIds = preselectedSpaceIds
    shouldShowPlaybackSection = draft.duration > 0
    selectedMonth = Self.startOfMonth(for: now(), calendar: calendar)
  }

  deinit {
    playbackTimerTask?.cancel()
  }

  var shouldShowPlaybackControls: Bool {
    isPlaybackAvailable
  }

  var visibleMoodHistoryEntries: [JournalEntry] {
    moodHistoryEntries
      .filter(matchesSelectedMoodHistoryDate)
      .sorted { $0.createdAt > $1.createdAt }
  }

  var dateStripDays: [Date] {
    let today = calendar.startOfDay(for: now())

    return (0..<7)
      .reversed()
      .compactMap { offset in
        calendar.date(byAdding: .day, value: -offset, to: today)
      }
  }

  var selectedMonthTitle: String {
    selectedMonth.formatted(.dateTime.month(.wide).year())
  }

  var selectedMonthID: String {
    Self.calendarIdentity(for: selectedMonth, calendar: calendar)
  }

  var weekdaySymbols: [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    guard !symbols.isEmpty else {
      return []
    }

    let firstIndex = (calendar.firstWeekday - 1 + symbols.count) % symbols.count
    return Array(symbols[firstIndex...] + symbols[..<firstIndex])
  }

  var calendarDays: [CalendarDayState] {
    guard
      let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth),
      let firstDayOfMonth = calendar.date(
        from: calendar.dateComponents([.year, .month], from: selectedMonth))
    else {
      return []
    }

    let monthID = Self.calendarIdentity(for: firstDayOfMonth, calendar: calendar)
    let leadingBlankCount =
      (calendar.component(.weekday, from: firstDayOfMonth) - calendar.firstWeekday + 7) % 7
    var days = (0..<leadingBlankCount).map { index in
      CalendarDayState.empty(id: "review-\(monthID)-leading-\(index)")
    }

    days += monthRange.compactMap { day -> CalendarDayState? in
      guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else {
        return nil
      }

      return CalendarDayState(
        id: "review-\(monthID)-day-\(day)",
        date: date,
        dayNumber: day,
        hasEntries: dateHasMoodHistoryEntries(date),
        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
        isToday: calendar.isDateInToday(date)
      )
    }

    let trailingBlankCount = (7 - (days.count % 7)) % 7
    days += (0..<trailingBlankCount).map { index in
      CalendarDayState.empty(id: "review-\(monthID)-trailing-\(index)")
    }

    return days
  }

  var shouldShowPlaybackLoadingState: Bool {
    shouldShowPlaybackSection && (isPreparingPlayback || playbackIsAwaitingMetadata)
  }

  var playbackProgress: Double {
    guard playbackDuration > 0 else { return 0 }
    return min(max(playbackCurrentTime / playbackDuration, 0), 1)
  }

  var playbackTimeText: String {
    "\(formatPlaybackTime(playbackCurrentTime)) / \(formatPlaybackTime(playbackDuration))"
  }

  var playbackButtonIcon: String {
    isPlayingAudio ? AppIcons.pause : AppIcons.play
  }

  var playbackButtonTitle: String {
    isPlayingAudio ? "Pause" : "Play"
  }

  func selectMood(_ mood: Mood) {
    selectedMood = mood
  }

  func selectDriftType(_ driftType: DriftType) {
    selectedDriftType = driftType
  }

  func loadReviewHistory() async {
    guard !isLoadingReviewHistory else { return }

    isLoadingReviewHistory = true
    reviewHistoryErrorMessage = nil
    defer { isLoadingReviewHistory = false }

    do {
      moodHistoryEntries = try await journalRepository.fetchEntries()
        .filter(InsightsViewModel.isMoodHistoryEligible)
        .sorted { $0.createdAt > $1.createdAt }
      moodHistoryDaysWithEntries = Set(
        moodHistoryEntries.map { calendar.startOfDay(for: $0.createdAt) }
      )
      refreshMoodHistorySummary()
    } catch {
      moodHistoryEntries = []
      moodHistoryDaysWithEntries = []
      moodHistorySummary = .empty
      reviewHistoryErrorMessage = "We could not load mood history right now."
    }
  }

  func selectDate(_ date: Date?) {
    if let date, selectedDate.map({ calendar.isDate($0, inSameDayAs: date) }) == true {
      selectedDate = nil
    } else {
      selectedDate = date
      if let date {
        updateSelectedMonth(Self.startOfMonth(for: date, calendar: calendar))
      }
    }

    refreshMoodHistorySummary()
  }

  func toggleCalendarExpansion() {
    isCalendarExpanded.toggle()
  }

  func moveSelectedMonth(by value: Int) {
    guard value != 0 else {
      monthTransitionDirection = .none
      return
    }

    if let month = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
      monthTransitionDirection = value > 0 ? .next : .previous
      selectedMonth = Self.startOfMonth(for: month, calendar: calendar)
    }
  }

  func dateHasMoodHistoryEntries(_ date: Date) -> Bool {
    moodHistoryDaysWithEntries.contains(calendar.startOfDay(for: date))
  }

  func selectMoodTrendRange(_ range: MoodTrendRange) {
    selectedMoodTrendRange = range
    refreshMoodHistorySummary()
  }

  func loadSpaces() async {
    do {
      availableSpaces = try await spaceRepository.fetchSpaces()
    } catch {
      errorMessage = "We could not load your Spaces."
    }
  }

  func toggleSpace(_ space: DriftSpace) {
    if selectedSpaceIds.contains(space.id) {
      selectedSpaceIds.removeAll { $0 == space.id }
    } else {
      selectedSpaceIds.append(space.id)
    }
  }

  func toggleTheme(_ theme: JournalTheme) {
    if selectedThemes.contains(theme) {
      selectedThemes.removeAll { $0 == theme }
    } else {
      selectedThemes.append(theme)
    }
  }

  func loadCustomThemes() async {
    guard !isLoadingCustomThemes else { return }

    isLoadingCustomThemes = true
    defer { isLoadingCustomThemes = false }

    do {
      availableCustomThemes = try await customThemeService.loadCustomThemes()
    } catch {
      errorMessage = "We could not load your custom themes."
    }
  }

  func loadPlayback() async {
    guard fileManager.fileExists(atPath: draft.audioURL.path) else {
      shouldShowPlaybackSection = false
      isPlaybackAvailable = false
      return
    }

    isPreparingPlayback = true
    shouldShowPlaybackSection = true
    defer { isPreparingPlayback = false }

    do {
      let metadata = try await audioPlaybackService.prepare(url: draft.audioURL)
      playbackDuration = metadata.duration
      playbackCurrentTime = 0
      isPlaybackAvailable = metadata.duration > 0
      shouldShowPlaybackSection = isPlaybackAvailable
      playbackErrorMessage = nil
    } catch let error as AudioPlaybackError {
      isPlaybackAvailable = false
      shouldShowPlaybackSection = true
      playbackErrorMessage = error.localizedDescription
    } catch {
      isPlaybackAvailable = false
      shouldShowPlaybackSection = true
      playbackErrorMessage = "We could not prepare this recording for playback."
    }
  }

  func togglePlayback() async {
    guard isPlaybackAvailable else { return }

    do {
      if isPlayingAudio {
        await audioPlaybackService.pause()
        isPlayingAudio = false
        stopPlaybackTimer()
      } else {
        try await audioPlaybackService.play()
        isPlayingAudio = true
        playbackErrorMessage = nil
        startPlaybackTimer()
      }
    } catch let error as AudioPlaybackError {
      playbackErrorMessage = error.localizedDescription
    } catch {
      playbackErrorMessage = "We could not play this recording."
    }
  }

  func stopPlayback() async {
    await audioPlaybackService.stop()
    isPlayingAudio = false
    playbackCurrentTime = 0
    stopPlaybackTimer()
  }

  func toggleCustomTheme(_ theme: CustomJournalTheme) {
    if selectedCustomThemes.contains(theme) {
      selectedCustomThemes.removeAll { $0 == theme }
    } else {
      selectedCustomThemes.append(theme)
    }
  }

  func createCustomTheme() async {
    let name = pendingCustomThemeName

    do {
      let theme = try await customThemeService.createCustomTheme(named: name)
      availableCustomThemes.append(theme)
      selectedCustomThemes.append(theme)
      pendingCustomThemeName = ""
      errorMessage = nil
    } catch let error as CustomThemeServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "We could not save your custom theme. Please try again."
    }
  }

  func deleteCustomTheme(_ theme: CustomJournalTheme) async {
    do {
      try await customThemeService.deleteCustomTheme(id: theme.id)
      availableCustomThemes.removeAll { $0.id == theme.id }
      selectedCustomThemes.removeAll { $0.id == theme.id }
    } catch {
      errorMessage = "We could not delete that custom theme. Please try again."
    }
  }

  func addPendingTag() {
    let tag = pendingTag.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tag.isEmpty else { return }
    guard !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else {
      pendingTag = ""
      return
    }

    tags.append(tag)
    pendingTag = ""
  }

  func removeTag(_ tag: String) {
    tags.removeAll { $0 == tag }
  }

  func addImageInputs(_ inputs: [ImageAttachmentInput]) async {
    guard !inputs.isEmpty else { return }

    isProcessingImages = true
    errorMessage = nil
    defer { isProcessingImages = false }

    do {
      for input in inputs {
        let attachment = try await imageAttachmentService.saveImageAttachment(input)
        imageAttachments.append(attachment)
      }
    } catch let error as ImageAttachmentServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "We could not save that image on this device. Please try again."
    }
  }

  func removeImageAttachment(_ attachment: JournalImageAttachment) async {
    imageAttachments.removeAll { $0.id == attachment.id }
    await imageAttachmentService.deleteAttachment(attachment)
  }

  func discardDraftAttachments() async {
    await stopPlayback()
    await cleanupTemporaryAudio()
    await imageAttachmentService.deleteAttachments(imageAttachments)
    imageAttachments = []
  }

  func save() async -> JournalEntry? {
    let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedTranscript.isEmpty else {
      errorMessage = "Add a transcript before saving."
      return nil
    }

    isSaving = true
    errorMessage = nil

    do {
      let limitResult = try await dailyEntryLimitService.evaluateNewEntryAccess(on: draft.createdAt)
      guard limitResult.canCreateEntry else {
        isSaving = false
        errorMessage = limitResult.message
        return nil
      }
    } catch {
      isSaving = false
      errorMessage = DailyEntryLimitError.calculationFailed.localizedDescription
      return nil
    }

    let entry = JournalEntry(
      id: draft.id,
      createdAt: draft.createdAt,
      updatedAt: Date(),
      transcript: cleanedTranscript,
      title: title.trimmedNonEmpty ?? makeTitle(from: cleanedTranscript),
      mood: selectedMood,
      moodConfidence: 0.68,
      themes: selectedThemes,
      customThemes: selectedCustomThemes,
      tags: tags,
      duration: draft.duration,
      source: .voice,
      imageAttachments: imageAttachments,
      driftType: selectedDriftType,
      spaceIds: selectedSpaceIds,
      aiVisibility: .privateLocalOnly,
      driftStatus: .active
    )

    do {
      try await journalRepository.saveEntry(entry)
      await cleanupTemporaryAudio()
      isSaving = false
      return entry
    } catch {
      isSaving = false
      errorMessage = "We could not save this Drift. Please try again."
      return nil
    }
  }

  private func makeTitle(from transcript: String) -> String {
    let firstSentence =
      transcript
      .components(separatedBy: CharacterSet(charactersIn: ".!?"))
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let firstSentence, !firstSentence.isEmpty else {
      return "\(selectedDriftType.displayName) Drift"
    }
    return String(firstSentence.prefix(48))
  }

  private func refreshMoodHistorySummary() {
    moodHistorySummary = InsightsViewModel.calculateSummary(
      from: visibleMoodHistoryEntries,
      range: selectedMoodTrendRange,
      calendar: calendar,
      now: now()
    )
  }

  private func matchesSelectedMoodHistoryDate(_ entry: JournalEntry) -> Bool {
    guard let selectedDate else { return true }
    return calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
  }

  private func updateSelectedMonth(_ month: Date) {
    if calendar.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
      monthTransitionDirection = .none
      selectedMonth = month
      return
    }

    monthTransitionDirection = month > selectedMonth ? .next : .previous
    selectedMonth = month
  }

  private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
  }

  private static func calendarIdentity(for date: Date, calendar: Calendar) -> String {
    let components = calendar.dateComponents([.year, .month], from: date)
    return "\(components.year ?? 0)-\(components.month ?? 0)"
  }

  private static func makeInitialTitle(from transcript: String) -> String {
    let firstSentence =
      transcript
      .components(separatedBy: CharacterSet(charactersIn: ".!?"))
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let firstSentence, !firstSentence.isEmpty else { return "" }
    return String(firstSentence.prefix(48))
  }

  private func startPlaybackTimer() {
    playbackTimerTask?.cancel()
    playbackTimerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 300_000_000)

        guard let self else { return }
        let time = await self.audioPlaybackService.currentTime()
        let isStillPlaying = await self.audioPlaybackService.isPlaying()

        await MainActor.run {
          self.playbackCurrentTime = time
          self.isPlayingAudio = isStillPlaying

          if !isStillPlaying {
            self.stopPlaybackTimer()
          }
        }
      }
    }
  }

  private func stopPlaybackTimer() {
    playbackTimerTask?.cancel()
    playbackTimerTask = nil
  }

  private var playbackIsAwaitingMetadata: Bool {
    !isPlaybackAvailable && playbackErrorMessage == nil
  }

  private func cleanupTemporaryAudio() async {
    await audioPlaybackService.stop()
    stopPlaybackTimer()
    isPlayingAudio = false

    let audioURL = draft.audioURL.standardizedFileURL
    let temporaryDirectoryPath = fileManager.temporaryDirectory.standardizedFileURL.path
    guard audioURL.path.hasPrefix(temporaryDirectoryPath) else { return }

    await Task.detached(priority: .utility) {
      guard FileManager.default.fileExists(atPath: audioURL.path) else { return }
      try? FileManager.default.removeItem(at: audioURL)
    }.value
  }

  private func formatPlaybackTime(_ time: TimeInterval) -> String {
    let totalSeconds = max(Int(time), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}
