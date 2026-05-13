//
//  TestFixtures.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

func fixtureUUID(_ rawValue: String) -> UUID {
  UUID(uuidString: rawValue) ?? UUID()
}

func fixtureTimeZone(secondsFromGMT: Int) -> TimeZone {
  TimeZone(secondsFromGMT: secondsFromGMT) ?? .gmt
}

func fixtureDate(
  calendar: Calendar,
  year: Int,
  month: Int,
  day: Int,
  hour: Int? = nil,
  minute: Int? = nil
) -> Date {
  calendar.date(
    from: DateComponents(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    )
  ) ?? Date(timeIntervalSince1970: 0)
}
