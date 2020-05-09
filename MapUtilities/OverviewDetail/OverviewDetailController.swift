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
        view = SplitView(upper: dualMapsManager.mainMap, lower: dualMapsManager.detailMap)
    }

    private var splitView: SplitView { return view as! SplitView }
    
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
                    let splitView = controller.view as! SplitView
                    splitView.splitter.setNeedsLayout()
                    //splitView.setNeedsLayout()
                }

                previousOrientation = newOrientation
            }
        }
    }

    private var isFirstTime = true
    override func viewWillLayoutSubviews() {
        guard isFirstTime else { return }
        isFirstTime = false

        splitView.splitter.percentOffset = 1
    }

    // I had A LOT of trouble getting the detail map's initial region to match that of the main map.
    // The difficulty seems to be caused by the fact that the detail map's initial frame is very
    // small; not sure, it is confusing. The viewDidAppear code is working but I feel shakey about it;
    // like a change to the app (say in the timing of things) could break it.
    override func viewDidAppear(_ animated: Bool) {

        func setDetailRegion() {
            let main = dualMapsManager.mainMap
            let detail = dualMapsManager.detailMap

            var region = main.region
            region.span.latitudeDelta = Double(detail.bounds.height / main.bounds.height) * main.region.span.longitudeDelta

            detail.setRegion(region, animated: true)
        }

        setDetailRegion()

        showDetail()

//        Timer.scheduledTimer(withTimeInterval: 2.25, repeats: false) { _ in
//            UIView.animate(withDuration: 0.5, animations: { setDetailRegion() }, completion: { _ in self.showDetail() })
//        }

        self.addToolbar()
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
        animateSplitter(to: 0) {
            self.dualMapsManager.addAnnotation()
            self.dualMapsManager.zoomDetailMap(direction: .in) {
                self.dualMapsManager.pulseDetailMap() {
                    self.addToolbar() 
                    completion?()
                }
            }
        }
    }

    private func hideDetail(completion: (() -> ())? = nil) {
        if let toolBar = toolBar { toolBar.removeFromSuperview() }

        dualMapsManager.removeDetailAnnotation() {
            self.animateSplitter(to: 1) {
                completion?()
            }
        }
    }

    private func animateSplitter(to percentOffset: CGFloat, completion: (() -> ())? = nil) {
        guard  let splitView = view as? SplitView else { return }

        splitView.splitter.percentOffset = percentOffset
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
