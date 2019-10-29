//
//  SplitterView.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 10/1/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import Darwin

// We want the splitter view to be thin. This makes it difficult to touch.
// So, we use a transparant view that is constrained to be centered on the
// splitter, is thicker, and detects the touches. When the splitter is moved
// the touch view moves with it.

private let splitterThickness: CGFloat = 2 // Height in potrait or width in landscape
private let touchViewThickness: CGFloat = 40

private var currentConstraints: [NSLayoutConstraint]!

private func getCenterConstraint<T>(of: T) -> NSLayoutConstraint? where T : UIView {
    guard let constraints = currentConstraints else { return nil }
    for constraint in constraints {
        if type(of: constraint.firstItem!) == type(of: of) && (constraint.firstAttribute == .centerY || constraint.firstAttribute == .centerX) {
            return constraint
        }
    }
    return nil
}

class SplitterView: UIView {

    private var potraitConstraints: [NSLayoutConstraint]!
    private var landscapeConstraints: [NSLayoutConstraint]!
    private var touchView: TouchView!

    private var relativePosition: CGFloat?

    // We need the superview in order to complete the initializations; so we wait for it.
    override func didMoveToSuperview() {
        guard let superview = self.superview else { fatalError("No superview???") }

        touchView = TouchView()
        touchView.backgroundColor = .clear
        touchView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:))))
        touchView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(touchView)

        potraitConstraints = [
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            heightAnchor.constraint(equalToConstant: splitterThickness),

            touchView.leftAnchor.constraint(equalTo: leftAnchor),
            touchView.rightAnchor.constraint(equalTo: rightAnchor),
            touchView.centerYAnchor.constraint(equalTo: centerYAnchor),
            touchView.heightAnchor.constraint(equalToConstant: touchViewThickness)
        ]

        landscapeConstraints = [
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            widthAnchor.constraint(equalToConstant: splitterThickness),

            touchView.topAnchor.constraint(equalTo: topAnchor),
            touchView.bottomAnchor.constraint(equalTo: bottomAnchor),
            touchView.centerXAnchor.constraint(equalTo: centerXAnchor),
            touchView.widthAnchor.constraint(equalToConstant: touchViewThickness)
        ]
    }

    // Note: It was discovered that the superview is not guaranteed to have already been rotated
    // to the new orientation at the time of the orientation change notification. The main screen,
    // however, has been rotated prior to the notification.

    func adapt(from oldOrientation: UIDeviceOrientation?, to newOrientation: UIDeviceOrientation) {

        let newConstraints: [NSLayoutConstraint]
        switch newOrientation {
        case .portrait: newConstraints = potraitConstraints
        case .landscapeRight: fallthrough
        case .landscapeLeft: newConstraints = landscapeConstraints
        default: return
        }

        // Adjust the splitter's position so that in the new orientation it will have
        // the same position relative to the center that it had in the old orientation
        func adjustPosition(_ oldCenterConstraint: NSLayoutConstraint?, _ newCenterConstraint: NSLayoutConstraint) {
            guard let oldCenterConstraint = oldCenterConstraint, let relativePosition = relativePosition else {
                newCenterConstraint.constant = 0
                return
            }

            // Determine whether the newConstaint's offset from the center is positive or negative.
            // Example: If the old orientation was potrait and the splitter had been moved toward the top then the
            // value of its center constarint's constant would be negative (i.e. in the -y direction). To achieve
            // the same relative position in a landscape right orientation would require the splitter to be moved
            // to the right using a positive value for the constraint's constant (i.e. in the +x direction).
            let wasNegative = oldCenterConstraint.constant < 0
            var isNegative = wasNegative
            switch oldOrientation {
            case .portrait: fallthrough
            case .landscapeLeft: if newOrientation == .landscapeRight { isNegative = !wasNegative }
            case .landscapeRight: isNegative = !wasNegative
            default: break
            }

            newCenterConstraint.constant = (isNegative ? -1 : 1) * relativePosition * maximumOffset
        }

        let oldCenterConstraint = getCenterConstraint(of: self)

        if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }
        NSLayoutConstraint.activate(newConstraints)
        currentConstraints = newConstraints
 
        let newCenterConstraint = getCenterConstraint(of: self)
        adjustPosition(oldCenterConstraint, newCenterConstraint!)

        touchView.setNeedsDisplay() // Redraw the arrows; up/down vs left/right
    }

    // Reposition the slider; either top to bottom, or left to right.
    private var initialConstant: CGFloat?
    @objc func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {
        guard let centerConstraint = getCenterConstraint(of: self) else { return }

        switch recognizer.state {
        case .began: initialConstant = centerConstraint.constant

        case .changed: // The recognizer reports the current, total delta since the beginning of the pan gesture
            let panGestureDelta = recognizer.translation(in: self.superview)
            let newConstant = initialConstant! + (centerConstraint.firstAttribute == .centerY ? panGestureDelta.y : panGestureDelta.x)
            centerConstraint.constant = abs(newConstant) < maximumOffset ? newConstant : (newConstant > 0 ? maximumOffset : -maximumOffset)

            self.relativePosition = abs(centerConstraint.constant) / maximumOffset

        default: break
        }
    }

    // Whether in potrait or in landscape we are operating off of the maximum dimension.
    private var maximumOffset : CGFloat {
        let dimension = UIScreen.main.bounds.height > UIScreen.main.bounds.width  ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        return dimension/2 - touchViewThickness
    }
}

private class TouchView : UIView {

    override func draw(_ rect: CGRect) {

        superview!.bringSubviewToFront(self) // Touch view should be on top. This only needs to be called once; maybe there's a better spot?

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.black.cgColor)

        guard let currentPosition = getCenterConstraint(of: self) else { return }

        // Draw an upward and a downward pointing triangle above and below the splitter.

        let side: CGFloat = 5
        let separation: CGFloat = 1
        let apex = splitterThickness/2 + separation + side

        if currentPosition.firstAttribute == .centerY {
            let startX = self.bounds.midX

            // Upward pointing triangle above splitter
            var startY = self.bounds.midY - apex
            context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
            context.addLine(to: CGPoint(x: startX - side/2, y: startY + side)) // Down to the left
            context.addLine(to: CGPoint(x: startX + side/2, y: startY + side)) // Across to the right
            context.addLine(to: CGPoint(x: startX, y: startY)) // Up to the left; back to the apex
            context.fillPath()

            // Downward pointing triangle below splitter
            startY = self.bounds.midY + apex
            context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
            context.addLine(to: CGPoint(x: startX - side/2, y: startY - side)) // Up to the left
            context.addLine(to: CGPoint(x: startX + side/2, y: startY - side)) // Across to the right
            context.addLine(to: CGPoint(x: startX, y: startY)) // Down to the left; back to the apex
            context.fillPath()
        }
        else {
            let startY = self.bounds.midY

            // Left pointing triangle to left of splitter
            var startX = self.bounds.midX - apex
            context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
            context.addLine(to: CGPoint(x: startX + side, y: startY - side/2)) // Up to the right
            context.addLine(to: CGPoint(x: startX + side, y: startY + side/2)) // Down
            context.addLine(to: CGPoint(x: startX, y: startY)) // Up to the left; back to the apex
            context.fillPath()

            // Right pointing triangle to right splitter
            startX = self.bounds.midX + apex
            context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
            context.addLine(to: CGPoint(x: startX - side, y: startY - side/2)) // Up to the left
            context.addLine(to: CGPoint(x: startX - side, y: startY + side/2)) // Down
            context.addLine(to: CGPoint(x: startX, y: startY)) // Up to the right; back to the apex
            context.fillPath()
        }
    }
}
