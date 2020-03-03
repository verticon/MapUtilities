//
//  TestController.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 1/12/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit

class TestController: UIViewController {

    class TestSubView : UIView {
        override func layoutSubviews() {
            //print("TestSubView - Laying out subviews, orientation = \(getOrientation()) (\(UIDevice.current.orientation))")
        }
    }

    class TestView : UIView {
        let subView = TestSubView()

        init() {
            super.init(frame: .zero)

            backgroundColor = .orange

            subView.backgroundColor = .brown
            addSubview(subView)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func calcSubViewFrame(in: CGRect) -> CGRect {
            let side = `in`.width/2
            let size = CGSize(width:side, height: side)
            let origin = CGPoint(x: `in`.midX - side/2, y: `in`.midY - side/2)
            let frame = CGRect(origin: origin, size: size)
            return frame
        }
    }

    class TransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
        func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return PresentingAnimator()
        }

        func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return nil
        }

        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return DismissingAnimator()
        }

        func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return nil
        }
    }

    class PresentingAnimator : NSObject, UIViewControllerAnimatedTransitioning {
        private let duration: TimeInterval = 2

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { return duration }

        // It seems that the essential steps that must be accomplished are:
        //  1) Place the toVC's view into the container
        //  2) Set the toVC view's frame
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard
                let toController = transitionContext.viewController(forKey: .to),
                let toControllerView = toController.view as? TestView
            else { return }

            let finalFrame = transitionContext.finalFrame(for: toController)
            let initialFrame = finalFrame.insetBy(dx: finalFrame.width/4, dy: finalFrame.height/4)
            
            toControllerView.frame = initialFrame
            toControllerView.subView.frame = toControllerView.calcSubViewFrame(in: toControllerView.bounds)
            transitionContext.containerView.addSubview(toControllerView)

            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .layoutSubviews,
                animations: {
                    toControllerView.frame = finalFrame
                    toControllerView.subView.frame = toControllerView.calcSubViewFrame(in: CGRect(origin: .zero, size: finalFrame.size))
                },
                completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) })
        }

        func animationEnded(_ transitionCompleted: Bool) {
            //print("Presentation animation ended")
        }
    }

    class DismissingAnimator : NSObject, UIViewControllerAnimatedTransitioning {
        private let duration: TimeInterval = 1

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { return duration }
          
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .layoutSubviews,
                animations: { },
                completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) })
        }
         
        func animationEnded(_ transitionCompleted: Bool) {
           // print("Dismissal animation ended")
        }
    }

    private var transitionDelegate: UIViewControllerTransitioningDelegate? = TransitioningDelegate()
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { return transitionDelegate }
        set { transitionDelegate = newValue }
    }

    override func loadView() {
        view = TestView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier {
                case layout
                case dismiss
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
                switch tool.id {
                case .layout: self?.view.setNeedsLayout()
                case .dismiss: self?.dismiss(animated: true, completion: nil)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .dismiss: tool.control.setNeedsDisplay()
                default: break
                }
            }
            
            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)

//            let layoutButton = UIButton(type: .system)
//            layoutButton.backgroundColor = .gray
//            _ = toolBar.add(control: layoutButton, id: .layout, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

        // ***************************************************************************
        
        var notificationObserver: NSObjectProtocol?
        notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            //print("Test Controller - orientation change notification: \(UIDevice.current.orientation)")

            if self == nil, let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
                notificationObserver = nil
            }
        }
    }

    override var modalTransitionStyle: UIModalTransitionStyle {
        get { return .coverVertical }
        set {}
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { return .fullScreen }
        set { }
    }
}

