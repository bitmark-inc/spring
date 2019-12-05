//
//  CustomxAxisRender.swift
//  Synergy
//
//  Created by Anh Nguyen on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Charts

final class CustomxAxisRender: XAxisRendererHorizontalBarChart {
    @objc override func computeSize()
    {
        guard let
            xAxis = self.axis as? XAxis
            else { return }
        
        xAxis.labelWidth = 0
        xAxis.labelHeight = 0
        xAxis.labelRotatedWidth = 0
        xAxis.labelRotatedHeight = 0
    }
    
    override func renderAxisLabels(context: CGContext)
    {
        guard
            let xAxis = self.axis as? XAxis
            else { return }
        
        if !xAxis.isEnabled || !xAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = xAxis.xOffset
        
        drawLabels(context: context, pos: viewPortHandler.contentLeft + xoffset, anchor: CGPoint(x: 0.0, y: 0.5))
    }
    
    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint)
    {
        guard
            let xAxis = self.axis as? XAxis,
            let transformer = self.transformer
            else { return }

        let labelFont = xAxis.labelFont
        let labelTextColor = xAxis.labelTextColor
        let labelRotationAngleRadians = xAxis.labelRotationAngle * .pi / 180

        let centeringEnabled = xAxis.isCenterAxisLabelsEnabled

        // pre allocate to save performance (dont allocate in loop)
        var position = CGPoint(x: 0.0, y: 0.0)

        for i in stride(from: 0, to: xAxis.entryCount, by: 1)
        {
            // only fill x values

            position.x = 0.0

            if centeringEnabled
            {
                position.y = CGFloat(xAxis.centeredEntries[i])
            }
            else
            {
                position.y = CGFloat(xAxis.entries[i])
            }

            transformer.pointValueToPixel(&position)

            if viewPortHandler.isInBoundsY(position.y)
            {
                if let label = xAxis.valueFormatter?.stringForValue(xAxis.entries[i], axis: xAxis)
                {
                    drawLabel(
                        context: context,
                        formattedLabel: label,
                        x: pos - CGFloat(3.0),
                        y: position.y - CGFloat(12.0),
                        attributes: [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: labelTextColor],
                        anchor: anchor,
                        angleRadians: labelRotationAngleRadians)
                }
            }
        }
    }
}
