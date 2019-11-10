//
//  SplitterView.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 10/1/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import Darwin

// Note: It was discovered that the superview is not guaranteed to have already been rotated
// to the new orientation at the time of the orientation change notification. The main screen,
// however, will have been rotated prior to the notification.

class SplitterView: UIView {

    static let thickness: CGFloat = 2 // Height in potrait or width in landscape

    // The magnitude of the offset remains the same in portrait of in landscape; the splitter is always
    // moving through the longer dimension (y in portrait, x in landscape). The sign (+/-) might, however,
    // change when the orientation changes.
    private var centerConstraintConstant: CGFloat = 0

    private let touchView = TouchView()

    init() {
        super.init(frame: CGRect.zero)

        // The touch view needs to be on top
        touchView.translatesAutoresizingMaskIntoConstraints = false
        touchView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        superview?.addSubview(touchView)
    }

    // ****************************************************************************************************************

    // Reposition the slider, either top to bottom or left to right, by updating the center constraint's constant.
    private var initialConstant: CGFloat!
    @objc func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {
        case .began:
            initialConstant = centerConstraintConstant

        case .changed:
            let centerConstraint = getCenterConstraint()

            // The recognizer reports the current, total delta since the beginning of the pan gesture
            let panGestureDelta = recognizer.translation(in: self.superview)
            let newConstant = initialConstant + (centerConstraint.firstAttribute == .centerY ? panGestureDelta.y : panGestureDelta.x)

            // Whether in potrait or in landscape we are operating off of the maximum dimension.
            let maxDimension = UIScreen.main.bounds.height > UIScreen.main.bounds.width  ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
            let maxOffset = maxDimension/2 - TouchView.thickness

            centerConstraintConstant = abs(newConstant) < maxOffset ? newConstant : (newConstant > 0 ? maxOffset : -maxOffset)
            centerConstraint.constant = centerConstraintConstant

        default: break
        }
    }

    // ****************************************************************************************************************

    private var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
    private lazy var potraitConstraints: [NSLayoutConstraint] = [
        touchView.leftAnchor.constraint(equalTo: self.leftAnchor),
        touchView.rightAnchor.constraint(equalTo: self.rightAnchor),
        touchView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        touchView.heightAnchor.constraint(equalToConstant: TouchView.thickness),
    ]
    private lazy var landscapeRightConstraints: [NSLayoutConstraint] = [
        touchView.topAnchor.constraint(equalTo: self.topAnchor),
        touchView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        touchView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        touchView.widthAnchor.constraint(equalToConstant: TouchView.thickness),
    ]
    private lazy var landscapeLeftConstraints: [NSLayoutConstraint] = [
        touchView.topAnchor.constraint(equalTo: self.topAnchor),
        touchView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        touchView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        touchView.widthAnchor.constraint(equalToConstant: TouchView.thickness),
    ]

    private var currentOrientation: UIDeviceOrientation?

    // This method assumes that new splitter constraints (i.e. those
    // appropriate to the new orientation) have already been put in place.
    func adapt(to newOrientation: UIDeviceOrientation) {

        // Determine whether, in the new orientation, the constaint's offset from the center is positive or negative.
        // Example: If the old orientation was potrait and the splitter had been moved toward the top then the
        // value of its center constarint's constant would be negative (i.e. in the -y direction). To achieve
        // the same relative position in a landscape right orientation would require the splitter to be moved
        // to the right using a positive value for the constraint's constant (i.e. in the +x direction).
        func updateSign() {
            let wasNegative = centerConstraintConstant < 0
            var isNegative = wasNegative
            switch currentOrientation {
            case .portrait: fallthrough
            case .landscapeLeft: if newOrientation == .landscapeRight { isNegative = !wasNegative }
            case .landscapeRight: isNegative = !wasNegative
            default: break
            }
            centerConstraintConstant = (isNegative ? -1 : 1) * abs(centerConstraintConstant)

            getCenterConstraint().constant = centerConstraintConstant
        }

        func updateConstraints() {
            if let current = currentConstraints {
                NSLayoutConstraint.deactivate(current)
                currentConstraints = nil
            }

            switch newOrientation {
            case .portrait: currentConstraints = potraitConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints
            case .landscapeRight: currentConstraints = landscapeRightConstraints
            default: return
            }

            NSLayoutConstraint.activate(currentConstraints!)
        }

        updateSign()
        updateConstraints()
        currentOrientation = newOrientation

        touchView.adapt(to: newOrientation)
    }

    // ****************************************************************************************************************

    private func getCenterConstraint() -> NSLayoutConstraint {
        for constraint in superview!.constraints {
            if constraint.firstItem! === self && (constraint.firstAttribute == .centerY || constraint.firstAttribute == .centerX) {
                return constraint
            }
        }
        fatalError("No center constraint???")
    }

}

// We want the splitter view to be thin. This makes it difficult to touch.
// So, we use a transparant view that is constrained to be centered on the
// splitter, is thicker, and detects the touches. When the splitter is moved
// the touch view moves with it.
private class TouchView : UIView {

    static let thickness: CGFloat = 40 // Height in potrait or width in landscape

    init() {
        super.init(frame: CGRect.zero)

        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    func adapt(to newOrientation: UIDeviceOrientation) {
        setNeedsDisplay() // Redraw the arrows; up/down vs left/right
    }

    // Add up and down, or left and right, pointing triangles to the splitter.
    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.black.cgColor)

        let side: CGFloat = 5
        let separation: CGFloat = 1
        let apex = SplitterView.thickness/2 + separation + side

        if UIDevice.current.orientation == .portrait {
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

            // Right pointing triangle to right of splitter
            startX = self.bounds.midX + apex
            context.move(to: CGPoint(x: startX, y: startY)) // Start at the apex
            context.addLine(to: CGPoint(x: startX - side, y: startY - side/2)) // Up to the left
            context.addLine(to: CGPoint(x: startX - side, y: startY + side/2)) // Down
            context.addLine(to: CGPoint(x: startX, y: startY)) // Up to the right; back to the apex
            context.fillPath()
        }
    }
}
