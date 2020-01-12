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

    private enum ToolIdentifier : Int, CaseIterable {
        case dismiss
    }

    private let dualMapsManager: DualMapsManager
    private var splitter = SplitterView()

    private var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
    private lazy var potraitConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: splitter.topAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.leftAnchor.constraint(equalTo: view.leftAnchor),
        splitter.rightAnchor.constraint(equalTo: view.rightAnchor),
        splitter.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        splitter.heightAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: splitter.bottomAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: view.leftAnchor),
    ]
    private lazy var landscapeRightConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: splitter.rightAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: view.leftAnchor),
    ]
    private lazy var landscapeLeftConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: splitter.rightAnchor),
    ]

    init(initialOverviewRegion: MKCoordinateRegion) {
        dualMapsManager = DualMapsManager(initialOverviewRegion: initialOverviewRegion)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("Deinit") }

    override func viewDidLoad() {
        super.viewDidLoad()

        dualMapsManager.overview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dualMapsManager.overview)

        splitter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitter)

        dualMapsManager.detail.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dualMapsManager.detail)

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier {
                case dismiss
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
                switch tool.id {
                case .dismiss: self?.dismiss(animated: true, completion: nil)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .dismiss: tool.control.setNeedsDisplay()
                }
            }
            
            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

        var previousOrientation: UIDeviceOrientation?
        var notificationObserver: NSObjectProtocol?
        notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            print("Orientation change notification: \(UIDevice.current.orientation)")

            guard let controller = self else {
                if let observer = notificationObserver { NotificationCenter.default.removeObserver(observer) }
                return
            }

            let newOrientation = UIDevice.current.orientation
            guard newOrientation != previousOrientation else { return }
            
            switch newOrientation { // Only act upon these three
            case .portrait: break
            case .landscapeRight: break
            case .landscapeLeft: break
            default: return
            }

            previousOrientation = newOrientation

            if let current = controller.currentConstraints { NSLayoutConstraint.deactivate(current) }
            controller.currentConstraints = nil // The new constraints will be set in viewDidLayoutSubviews(); see the comments there.

            // When the device's orientation changes between portrait, landscape left, and landscape right iOS performs
            // view layout (viewWillLayoutSubviews() is called). However, when the device passes through the upside down
            // position, on its way to landscape left or lanscape right, then layout does not occur (tested on iOS 13).
            controller.view.setNeedsLayout()
        }
        print("Initial orientation: \(UIDevice.current.orientation)")
    }

    // Wait until viewWillLayoutSubviews to put the new constraints in place.
    // Doing so ensures that the root view's bounds will have been updated to
    // match the new orientation and thus there will be no conflicts between
    // the root view and the new constarints.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // It is initially nil, and the orientationDidChangeNotification handler (see viewDidLoad()) sets it to nil
        if currentConstraints == nil {

            switch UIDevice.current.orientation {
            case .unknown: fallthrough
            case .faceUp: fallthrough
            case .portraitUpsideDown: fallthrough
            case .faceDown: fallthrough
            case .portrait: currentConstraints = potraitConstraints

            case .landscapeRight: currentConstraints = landscapeRightConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints

            @unknown default:
                print("A new device orientation has been added")
                return
            }

            NSLayoutConstraint.activate(currentConstraints)

            splitter.adapt(to: UIDevice.current.orientation)
        }
    }
}
