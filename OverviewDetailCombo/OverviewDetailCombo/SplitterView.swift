//
//  SplitterView.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 10/1/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import Darwin

class SplitterView: UIView {

    // We want the splitter view to be thin. This makes it difficult to touch.
    // So, we use a transparant view that is constrained to be centered on the
    // splitter, is taller, and detects the touches. When the splitter is moved
    // the touch view moves with it.
    @IBOutlet weak var touchView: UIView!

    // The splitter's Y position is constrained to be at the center. We manipulate the
    // constarint's constant in order to move the splitter in accordance with the user's pan gesture.
    @IBOutlet weak var splitterPosition: NSLayoutConstraint!

    private var setupCompleted = false
    override func layoutSubviews() {
        guard !setupCompleted else { return }
        touchView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:))))
        setupCompleted = true
    }

    private var initialConstant: CGFloat?
    @objc func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            initialConstant = splitterPosition.constant
        case .changed: // The recognizer reports the current, total delta since the beginning of the pan gesture
            let maxOffset = superview!.bounds.height / 2 - touchView.bounds.height // Don't go too close to the edge.
            let newConstant = initialConstant! + recognizer.translation(in: self.superview).y
            splitterPosition.constant = abs(newConstant) < maxOffset ? newConstant : (newConstant > 0 ? maxOffset : -maxOffset)
        default: break
        }
    }
}

class TouchView : UIView {
    @IBOutlet weak var splitter: SplitterView!

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.black.cgColor)

        // Draw an upward and a downward pointing triangle above and below the splitter.

        let side: CGFloat = 5
        let separation: CGFloat = 1
        let height = splitter.bounds.height/2 + separation + side

        let startX = self.bounds.midX

        // Upward pointing triangle above splitter
        var startY = self.bounds.midY - height
        context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
        context.addLine(to: CGPoint(x: startX - side/2, y: startY + side)) // Down to the left
        context.addLine(to: CGPoint(x: startX + side/2, y: startY + side)) // Across to the right
        context.addLine(to: CGPoint(x: startX, y: startY)) // Back up to the apex
        context.fillPath()

        // Downward pointing triangle below splitter
        startY = self.bounds.midY + height
        context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
        context.addLine(to: CGPoint(x: startX - side/2, y: startY - side)) // Up to the left
        context.addLine(to: CGPoint(x: startX + side/2, y: startY - side)) // Across to the right
        context.addLine(to: CGPoint(x: startX, y: startY)) // Back down to the apex
        context.fillPath()
    }
}
