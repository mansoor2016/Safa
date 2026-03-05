// MARK: - FlowLayout.swift
// PURPOSE: Reusable wrapping layout that places views left-to-right, wrapping on overflow
// DEPENDENCIES: SwiftUI

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return CGSize(width: totalWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let isRTL = subviews.layoutDirection == .rightToLeft
        var currentX: CGFloat = isRTL ? bounds.maxX : bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if isRTL {
                if currentX - size.width < bounds.minX, currentX < bounds.maxX {
                    currentX = bounds.maxX
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: currentX - size.width, y: currentY), proposal: .unspecified)
                currentX -= size.width + spacing
            } else {
                if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                    currentX = bounds.minX
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
                currentX += size.width + spacing
            }
            lineHeight = max(lineHeight, size.height)
        }
    }
}
