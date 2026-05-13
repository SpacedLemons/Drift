//
//  FlowLayout.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct FlowLayout: Layout {
  var spacing: CGFloat = AppSpacing.xs

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) -> CGSize {
    let rows = makeRows(
      proposal: proposal,
      subviews: subviews
    )
    return CGSize(
      width: proposal.width ?? rows.map(\.width).max() ?? 0,
      height: rows.last.map { $0.y + $0.height } ?? 0
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    let rows = makeRows(
      proposal: ProposedViewSize(width: bounds.width, height: proposal.height),
      subviews: subviews
    )

    for row in rows {
      for item in row.items {
        subviews[item.index].place(
          at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
          proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
        )
      }
    }
  }

  private func makeRows(
    proposal: ProposedViewSize,
    subviews: Subviews
  ) -> [FlowRow] {
    let maxWidth = proposal.width ?? .greatestFiniteMagnitude
    var rows: [FlowRow] = []
    var currentItems: [FlowItem] = []
    var x: CGFloat = 0
    var rowHeight: CGFloat = 0
    var y: CGFloat = 0

    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let shouldWrap = x > 0 && x + size.width > maxWidth

      if shouldWrap {
        rows.append(FlowRow(y: y, width: x - spacing, height: rowHeight, items: currentItems))
        y += rowHeight + spacing
        currentItems = []
        x = 0
        rowHeight = 0
      }

      currentItems.append(FlowItem(index: index, x: x, size: size))
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }

    if !currentItems.isEmpty {
      rows.append(FlowRow(y: y, width: max(0, x - spacing), height: rowHeight, items: currentItems))
    }

    return rows
  }
}

private struct FlowRow {
  var y: CGFloat
  var width: CGFloat
  var height: CGFloat
  var items: [FlowItem]
}

private struct FlowItem {
  var index: Int
  var x: CGFloat
  var size: CGSize
}
