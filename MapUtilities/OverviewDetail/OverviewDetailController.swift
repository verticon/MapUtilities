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

        private let upper: UIView
        private let splitter = SplitterView()
        private let lower: UIView
        private var currentConstraints: [NSLayoutConstraint]?

        init(overview: UIView, detail: UIView) {
            self.upper = overview
            self.lower = detail
            super.init(frame: .zero)

            overview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(overview)

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
           splitter.heightAnchor.constraint(equalToConstant: SplitterView.thickness),

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
           splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

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
           splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

           lower.topAnchor.constraint(equalTo: self.topAnchor),
           lower.rightAnchor.constraint(equalTo: self.rightAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: splitter.rightAnchor),
        ]

        override func layoutSubviews() {
            let orientation = getOrientation()
            print("OverviewDetailView - Laying out subviews, orientation = \(orientation) (\(UIDevice.current.orientation))")

            if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }

            switch orientation {
            case .portrait: currentConstraints = potraitConstraints
            case .landscapeRight: currentConstraints = landscapeRightConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints
            default: fatalError("This shouldn't happen")
            }

            NSLayoutConstraint.activate(currentConstraints!)
        }
    }

    private enum ToolIdentifier : Int, CaseIterable {
        case dismiss
    }

    private let dualMapsManager: DualMapsManager

    init(mainMap: MKMapView) {
        dualMapsManager = DualMapsManager(mainMap: mainMap)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = SplitView(overview: dualMapsManager.mainMap, detail: dualMapsManager.detailMap)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
//            enum ToolIdentifier {
//                case dismiss
//            }
//
//            let toolBar = ToolBar<ToolIdentifier>(parent: view)
//
//            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
//                switch tool.id {
//                case .dismiss: self?.dismiss(animated: true, completion: nil)
//                }
//            }
//
//            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
//                switch tool.id {
//                case .dismiss: tool.control.setNeedsDisplay()
//                }
//            }
//
//            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

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
