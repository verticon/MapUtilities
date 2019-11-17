//
//  DismissButton.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 11/17/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class DismissButton: UIButton {

    private var controller: UIViewController!

    init(controller: UIViewController) {
        self.controller = controller

        super.init(frame: CGRect.zero)

        self.addTarget(self, action: #selector(dismiss(_ :)), for: .touchUpInside)
        self.backgroundColor = .gray
        self.layer.cornerRadius = 5.0
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func dismiss(_ button: UIButton) {
        controller.dismiss(animated: true) { }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) { // Draw a return symbol: an arrow consisting of a tip and a right angled shaft.
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let shaftThickness = min(self.bounds.width, self.bounds.height) / 4
        let tipHeight = shaftThickness
        let tipWidth = 2.5 * shaftThickness

        let tipPoint = CGPoint(x: 0, y: bounds.maxY - tipWidth/2)

        context.move(to: tipPoint)
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x + tipHeight, y: context.currentPointOfPath.y - tipWidth/2)) // Up and to the right
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: context.currentPointOfPath.y + (tipWidth/2 - shaftThickness/2))) // Down to the shaft
        context.addLine(to: CGPoint(x: bounds.maxX - shaftThickness, y: context.currentPointOfPath.y)) // Horizontal segment of shaft
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: bounds.minY)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - tipWidth/2 + shaftThickness/2)) // Vertical segment of shaft
        context.addLine(to: CGPoint(x: bounds.minX + tipHeight, y: context.currentPointOfPath.y)) // Horizontal segment of shaft
        context.addLine(to: CGPoint(x: context.currentPointOfPath.x, y: bounds.maxY))
        context.addLine(to: tipPoint)

        context.setAlpha(0.5)
        context.setLineWidth(2.0)
        context.setStrokeColor(self.traitCollection.userInterfaceStyle == .light ? UIColor.white.cgColor : UIColor.lightGray.cgColor)
        context.setFillColor(self.traitCollection.userInterfaceStyle == .light ? UIColor.lightGray.cgColor : UIColor.darkGray.cgColor)
        context.drawPath(using: .fillStroke)
    }
}
