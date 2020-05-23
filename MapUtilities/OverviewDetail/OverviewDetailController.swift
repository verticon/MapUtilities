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

    class TransistionView : UIView {}

    var dualMapsManager: DualMapsManager!
    private let dismissHandler: (OverviewDetailController) -> Void
    private let snapshot: UIView?
    private let splitView: SplitView

    init(mainMap: MKMapView, snapshot: UIView? = nil, dismissHandler: @escaping (OverviewDetailController) -> Void) {
        dualMapsManager = DualMapsManager(mainMap: mainMap)
        self.snapshot = snapshot
        self.dismissHandler = dismissHandler

        splitView = SplitView(upper: dualMapsManager.mainMap, lower: dualMapsManager.detailMap)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        if let snapshot = snapshot {
            view = TransistionView()

            snapshot.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(snapshot)
            NSLayoutConstraint.activate([
                snapshot.leftAnchor.constraint(equalTo: view.leftAnchor),
                snapshot.rightAnchor.constraint(equalTo: view.rightAnchor),
                snapshot.topAnchor.constraint(equalTo: view.topAnchor),
                snapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            splitView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(splitView)
            NSLayoutConstraint.activate([
                splitView.leftAnchor.constraint(equalTo: view.leftAnchor),
                splitView.rightAnchor.constraint(equalTo: view.rightAnchor),
                splitView.topAnchor.constraint(equalTo: view.topAnchor),
                splitView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            splitView.isHidden = true
        }
        else {
            view = splitView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Respond to orientation changes

            // When moving into or out of portraitUpsideDown iOS does not perform layout (iOS 13). Feels odd ...
            var previousOrientation: UIDeviceOrientation = .unknown
            var notificationObserver: NSObjectProtocol?
            notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
                guard let controller = self else  {
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                        notificationObserver = nil
                    }
                    return
                }

                let newOrientation = UIDevice.current.orientation
                print("OverviewDetailController - orientation changed from \(previousOrientation) to: \(newOrientation))")

                if previousOrientation == .portraitUpsideDown {
                    print("Previous orientation was upside down; layout needed")
                    controller.splitView.splitter.setNeedsLayout()
                }

                previousOrientation = newOrientation
            }
        }
    }

    // Had to wait for Did instead of Will to ensure that the split view's
    // bounds had been set prior to any attempts to alter the splitter's position.
    private var isFirstTime = true
    override func viewDidLayoutSubviews() {
        guard isFirstTime else { return }
        isFirstTime = false
        splitView.splitter.percentOffset = 1
        setDetailRegion()
    }

    // I had A LOT of trouble getting the detail map's initial region to match that of the main map.
    // As the splitter is animated up the detail should match the main. Then the detail is zoomed.

    private func setDetailRegion() {
        let main = dualMapsManager.mainMap
        let detail = dualMapsManager.detailMap

        var region = main.region
        region.span.latitudeDelta = Double(detail.bounds.height / main.bounds.height) * main.region.span.latitudeDelta
        region.span.longitudeDelta = Double(detail.bounds.width / main.bounds.width) * main.region.span.longitudeDelta

        detail.setRegion(region, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        showDetail()

//        Timer.scheduledTimer(withTimeInterval: 2.25, repeats: false) { _ in
//            UIView.animate(withDuration: 0.5, animations: { setDetailRegion() }, completion: { _ in self.showDetail() })
//        }
    }

    private var toolBar: UIView? = nil
    private func addToolbar() {
        enum ToolIdentifier {
            case dismiss
        }

        let toolBar = ToolBar<ToolIdentifier>(parent: view)

        let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
            switch tool.id {
            case .dismiss:
                guard let controller = self else { return }
                controller.hideDetail() { controller.dismissHandler(controller) }
            }
        }

        let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
            switch tool.id {
            case .dismiss: tool.control.setNeedsDisplay()
            }
        }
        
        _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)

        self.toolBar = toolBar
    }

    private func showDetail(completion: (() -> ())? = nil) {
        let isUserLocationVisible = dualMapsManager.mainMap.isUserLocationVisible
        self.dualMapsManager.mainMap.showsUserLocation = false

        func finish() {
            animateSplitter(to: 0) {
                self.dualMapsManager.addAnnotation()
                self.dualMapsManager.zoomDetailMap(direction: .in) {
                    self.dualMapsManager.pulseDetailMap() {
                        self.addToolbar()
                        completion?()
                        self.dualMapsManager.mainMap.showsUserLocation = isUserLocationVisible
                    }
                }
            }
        }

        if let transition = snapshot {
            UIView.transition(from: transition, to: splitView, duration: 1, options: [.transitionFlipFromRight, .showHideTransitionViews]) { _ in finish() }
        }
        else { finish() }
    }

    private func hideDetail(completion: (() -> ())? = nil) {
        if let toolBar = toolBar { toolBar.removeFromSuperview() }

        dualMapsManager.removeDetailAnnotation() {
            let position: CGFloat = getOrientation() == .landscapeRight ? -1 : 1
            self.animateSplitter(to: position) {
                completion?()
            }
        }
    }

    private func animateSplitter(to percentOffset: CGFloat, completion: (() -> ())? = nil) {
        splitView.splitter.percentOffset = percentOffset
        UIView.animate(withDuration: 1,
            animations: { self.splitView.layoutIfNeeded() }, // The "magic" for animating constraint changes
            completion: { _ in completion?() }
        )
    }

    func presentSnapshot(_ snapshot: UIView?) {
        if let snapshot = snapshot ?? self.view.snapshotView(afterScreenUpdates: false) {
             view = snapshot
        }
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
