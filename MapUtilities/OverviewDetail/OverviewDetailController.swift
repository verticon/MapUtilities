//
//  ViewController.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 9/22/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
import Darwin
import VerticonsToolbox

class OverviewDetailController: UIViewController {

    class SplitView : UIView {

        let upper: UIView
        let splitter: Splitter
        let lower: UIView
        private var currentConstraints: [NSLayoutConstraint]?

        init(main: UIView, detail: UIView) {
            self.upper = main
            splitter = Splitter()
            self.lower = detail

            super.init(frame: .zero)

            backgroundColor = .orange

            main.translatesAutoresizingMaskIntoConstraints = false
            addSubview(main)

            splitter.translatesAutoresizingMaskIntoConstraints = false
            addSubview(splitter)

            detail.translatesAutoresizingMaskIntoConstraints = false
            addSubview(detail)
        }
        
        required init?(coder: NSCoder) { fatalError("OverviewDetailView - init(coder:) has not been implemented") }

        private lazy var potraitConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: self.rightAnchor),
           upper.bottomAnchor.constraint(equalTo: splitter.topAnchor),
           upper.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.leftAnchor.constraint(equalTo: self.leftAnchor),
           splitter.rightAnchor.constraint(equalTo: self.rightAnchor),
           splitter.centerYAnchor.constraint(equalTo: self.centerYAnchor),
           splitter.heightAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: splitter.bottomAnchor),
           lower.rightAnchor.constraint(equalTo: self.rightAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeRightConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: self.rightAnchor),
           upper.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           upper.leftAnchor.constraint(equalTo: splitter.rightAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: self.topAnchor),
           lower.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeLeftConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           upper.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           upper.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: self.topAnchor),
           lower.rightAnchor.constraint(equalTo: self.rightAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: splitter.rightAnchor),
        ]

        override func layoutSubviews() {
    
            if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }

            switch getOrientation() {
            case .portrait: currentConstraints =  potraitConstraints
            case .landscapeRight: currentConstraints =  landscapeRightConstraints
            case .landscapeLeft: currentConstraints =  landscapeLeftConstraints
            default: fatalError("This shouldn't happen")
            }

            updateSplitterPosition()

            NSLayoutConstraint.activate(currentConstraints!)
        }

        // The magnitude of the splitter's offset remains the same in portrait or in landscape; the splitter is always
        // moving through the device's longer dimension (y in portrait, x in landscape). The sign (+/-) might, however,
        // change when the orientation changes.

        func updateSplitterPosition() {
            func getSplitterCenterConstraint() -> NSLayoutConstraint {
                for constraint in  currentConstraints! {
                    if constraint.firstItem === splitter && (constraint.firstAttribute == .centerY || constraint.firstAttribute == .centerX) {
                        return constraint
                    }
                }
                fatalError("No center constraint???")
            }

            getSplitterCenterConstraint().constant = splitter.offset
        }
    }

    var dualMapsManager: DualMapsManager!
    private let dismissHandler: (OverviewDetailController) -> Void

    init(mainMap: MKMapView, dismissHandler: @escaping (OverviewDetailController) -> Void) {
        self.dismissHandler = dismissHandler
        dualMapsManager = DualMapsManager(mainMap: mainMap)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let splitView = SplitView(main: dualMapsManager.mainMap, detail: dualMapsManager.detailMap)
        splitView.splitter.percentOffset = 1
        view = splitView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Create the Toolbar.
            enum ToolIdentifier {
                case dismiss
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
                switch tool.id {
                case .dismiss:
                    guard let controller = self else { return }
                    controller.dismissHandler(controller)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .dismiss: tool.control.setNeedsDisplay()
                }
            }
            
            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

        do { // Respond to orientation changes

            // When coming out of portraitUpsideDown iOS does not perform layout (iOS 13). Feels odd ...
            var previousOrientation: UIDeviceOrientation = .unknown
            var notificationObserver: NSObjectProtocol?
            notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
                let newOrientation = UIDevice.current.orientation
                //print("OverviewDetailController - orientation change notification: \(getOrientation()) (\(newOrientation))")

                guard self != nil else  {
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                        notificationObserver = nil
                    }
                    return
                }

                if previousOrientation == .portraitUpsideDown { self!.view.setNeedsLayout() }
                previousOrientation = newOrientation
            }
        }
    }

    // I had A LOT of trouble getting the detail map's initial region to match that of the main map.
    override func viewDidAppear(_ animated: Bool) {
        let main = dualMapsManager.mainMap
        let detail = dualMapsManager.detailMap

        detail.centerCoordinate = main.centerCoordinate
        detail.region.span = Double(detail.bounds.height / main.bounds.height) * main.region.span
    }

    func showDetail(completion: (() -> ())? = nil) {
        animateSplitter(to: 0) {
            self.dualMapsManager.addAnnotation()
            self.dualMapsManager.zoomDetailMap(direction: .in) {
                self.dualMapsManager.pulseDetailMap() {
                    completion?()
                }
            }
        }
    }

    func hideDetail(completion: (() -> ())? = nil) {
        animateSplitter(to: 0, completion: {
            self.dualMapsManager.zoomDetailMap(direction: .out) {
                self.dualMapsManager.removeAnnotation()
                self.animateSplitter(to: 1) {
                    completion?()
                }
            }
        })
    }

    private func animateSplitter(to percentOffset: CGFloat, completion: (() -> ())? = nil) {
        guard  let splitView = view as? SplitView else { return }

        splitView.splitter.percentOffset = percentOffset
        splitView.updateSplitterPosition()
        UIView.animate(withDuration: 1,
            animations: { splitView.layoutIfNeeded() }, // The "magic" for animating constraint changes
            completion: { _ in completion?() }
        )
    }

    func presentSnapshot() {
        if let snapshot = self.view.snapshotView(afterScreenUpdates: false) { view = snapshot }
    }

    override var modalPresentationStyle: UIModalPresentationStyle {
        get { return .fullScreen }
        set {}
    }

    override var modalTransitionStyle: UIModalTransitionStyle {
        get { return .flipHorizontal }
        set {}
    }

}
