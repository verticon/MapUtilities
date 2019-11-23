//
//  DismissButton.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 11/17/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class DismissButton: UIButton {

    init() {

        super.init(frame: CGRect.zero)

        self.backgroundColor = .clear
        self.layer.cornerRadius = 2.0
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) { // Draw a return symbol: an arrow consisting of a tip and a right angled shaft.
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let shaftThickness = min(self.bounds.width, self.bounds.height) / 5
        let tipHeight = shaftThickness
        let tipWidth = 2.5 * shaftThickness

        let drawingRect = self.bounds.insetBy(dx: 4, dy: 4)

        let tipPoint = CGPoint(x: drawingRect.minX, y: drawingRect.maxY - tipWidth/2)

        context.move(to: tipPoint)
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x + tipHeight, y: context.currentPointOfPath.y - tipWidth/2)) // Up and to the right
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: context.currentPointOfPath.y + (tipWidth/2 - shaftThickness/2))) // Down to the shaft
        context.addLine(to: CGPoint(x: drawingRect.maxX - shaftThickness, y: context.currentPointOfPath.y)) // Horizontal segment of shaft
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: drawingRect.minY)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.minY)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY - tipWidth/2 + shaftThickness/2)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: drawingRect.minX + tipHeight, y: context.currentPointOfPath.y)) // Horizontal segment of shaft
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: drawingRect.maxY))
        context.addLine(to: tipPoint)

        context.setAlpha(0.5)
        context.setLineWidth(2.0)
        context.setStrokeColor(self.traitCollection.userInterfaceStyle == .light ? UIColor.black.cgColor : UIColor.lightGray.cgColor)
        context.setFillColor(self.traitCollection.userInterfaceStyle == .light ? UIColor.darkGray.cgColor : UIColor.darkGray.cgColor)
        context.drawPath(using: .fillStroke)
    }
}
