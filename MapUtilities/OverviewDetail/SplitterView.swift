//
//  SplitterView.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 10/1/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import Darwin
import VerticonsToolbox

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

        backgroundColor = .black

        touchView.translatesAutoresizingMaskIntoConstraints = false
        touchView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The touch view needs to be on top
    override func didMoveToSuperview() {
        superview?.addSubview(touchView)
    }


    // Note: The following two closures, handler and layout, each "capture" (close over) a set of variables.
    // These variables might have otherwise been implemented as member properties of the Splitter class. Closures
    // are used so as to limit the scop of those variables to the single code block that needs to access them.
    // Question: Is there a cost to using this scoping technique?


    // ****************************************************************************************************************
    // Reposition the slider, either top to bottom or left to right, by updating the center constraint's constant.
    // ****************************************************************************************************************

    var splitterPosition : CGFloat { // -1.0 -> 1.0
        get { centerConstraintConstant / maxOffset }
        set {
            var value = newValue
            if value < -1.0 { value = -1.0 }
            else if value > 1.0 { value = 1.0 }

            centerConstraintConstant = value * maxOffset
            getCenterConstraint().constant = centerConstraintConstant
        }
    }

    private var maxOffset : CGFloat { (superview!.bounds.height > superview!.bounds.width  ? superview!.bounds.height : superview!.bounds.width) / 2 }

    private lazy var handler: (UIPanGestureRecognizer) -> Void = {

        var initialConstant: CGFloat!

        return { recognizer in
            
            switch recognizer.state {
            case .began:
                initialConstant = self.centerConstraintConstant

            case .changed: // The recognizer reports the current, total delta since the beginning of the pan gesture

                let panGestureDelta = recognizer.translation(in: self.superview)

                let limit = self.maxOffset - 2*TouchView.thickness
                var newConstant = initialConstant + (self.getCenterConstraint().firstAttribute == .centerY ? panGestureDelta.y : panGestureDelta.x)
                newConstant = abs(newConstant) < limit ? newConstant : (newConstant > 0 ? limit : -limit)

                self.splitterPosition = newConstant / self.maxOffset

            default: break
            }
        }
    }()
    @objc private func panGestureHandler(_ recognizer: UIPanGestureRecognizer) { handler(recognizer) }

    // ****************************************************************************************************************
    // Adapt the splitter to the new orientation. It is assumed that new splitter constraints
    // (i.e. those appropriate to the new orientation) have already been put in place.
    // ****************************************************************************************************************

    private lazy var layout: (() -> Void) = {
        // The TouchView class is a part of the Splitter's implementation: its existence does not need to be known externally.
        // BUT, we need it to be on top so that it can be touched This Z ordering would normally be handled by the code that
        // is adding views to the root view. We do it here. It only happens once. It feels kludgey. Sigh ...
        self.superview?.bringSubviewToFront(self.touchView)


        var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
        var potraitConstraints: [NSLayoutConstraint] = [
            self.touchView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.touchView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.touchView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.touchView.heightAnchor.constraint(equalToConstant: TouchView.thickness),
        ]
        var landscapeConstraints: [NSLayoutConstraint] = [
            self.touchView.topAnchor.constraint(equalTo: self.topAnchor),
            self.touchView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.touchView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.touchView.widthAnchor.constraint(equalToConstant: TouchView.thickness),
        ]

        var previousOrientation: UIDeviceOrientation?
        return {
            // Determine whether, in the new orientation, the constaint's offset from the center is positive or negative.
            // Example: If the old orientation was potrait and the splitter had been moved toward the top then the
            // value of its center constarint's constant would be negative (i.e. in the -y direction). To achieve
            // the same relative position in a landscape right orientation would require the splitter to be moved
            // to the right using a positive value for the constraint's constant (i.e. in the +x direction).
            func updateSign(_ orientation: UIDeviceOrientation) {
                let wasNegative = self.centerConstraintConstant < 0
                var isNegative = wasNegative

                switch previousOrientation {
                case .portrait: fallthrough
                case .landscapeLeft: if orientation == .landscapeRight { isNegative = !wasNegative }

                case .landscapeRight: isNegative = !wasNegative

                default: break
                }
                self.centerConstraintConstant = (isNegative ? -1 : 1) * abs(self.centerConstraintConstant)

                self.getCenterConstraint().constant = self.centerConstraintConstant
            }

            func updateConstraints(_ orientation: UIDeviceOrientation) {
                if let current = currentConstraints {
                    NSLayoutConstraint.deactivate(current)
                    currentConstraints = nil
                }

                switch orientation {
                case .portrait: currentConstraints = potraitConstraints

                case .landscapeLeft: fallthrough
                case .landscapeRight: currentConstraints = landscapeConstraints
                default: return
                }

                NSLayoutConstraint.activate(currentConstraints!)
            }

            let orientation = getOrientation()
            //print("SplitterView - Laying out subviews, orientation = \(orientation) (\(UIDevice.current.orientation))")

            updateConstraints(orientation)
            updateSign(orientation)
            previousOrientation = orientation

            self.touchView.setNeedsDisplay()
        }
    }()
    override func layoutSubviews() { layout() }

    // ****************************************************************************************************************
    // Utilities
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
 
    // Add up and down, or left and right, pointing triangles to the splitter.
    override func draw(_ rect: CGRect) {
        //print("TouchView - Draw()")

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.black.cgColor)

        let side: CGFloat = 5
        let separation: CGFloat = 1
        let apex = SplitterView.thickness/2 + separation + side

        if getOrientation() == .portrait {
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
