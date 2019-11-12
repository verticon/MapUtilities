//
//  ViewController.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 9/22/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
import VerticonsToolbox

class ViewController: UIViewController {

    private let mapA = MapView()
    private var splitter: SplitterView!
    private let mapB = MapView()
    private let toolBar = ToolBar()

    private let extraSpace: CGFloat = 10
    private var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
    private lazy var potraitConstraints: [NSLayoutConstraint] = [
        mapA.topAnchor.constraint(equalTo: view.topAnchor),
        mapA.rightAnchor.constraint(equalTo: view.rightAnchor),
        mapA.bottomAnchor.constraint(equalTo: splitter.topAnchor),
        mapA.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.leftAnchor.constraint(equalTo: view.leftAnchor),
        splitter.rightAnchor.constraint(equalTo: view.rightAnchor),
        splitter.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        splitter.heightAnchor.constraint(equalToConstant: SplitterView.thickness),

        mapB.topAnchor.constraint(equalTo: splitter.bottomAnchor),
        mapB.rightAnchor.constraint(equalTo: view.rightAnchor),
        mapB.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        mapB.leftAnchor.constraint(equalTo: view.leftAnchor),

        toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        toolBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -extraSpace),
        toolBar.widthAnchor.constraint(equalToConstant: toolBar.bounds.width),
        toolBar.heightAnchor.constraint(equalToConstant: toolBar.bounds.height)
    ]
    private lazy var landscapeRightConstraints: [NSLayoutConstraint] = [
        mapA.topAnchor.constraint(equalTo: view.topAnchor),
        mapA.rightAnchor.constraint(equalTo: view.rightAnchor),
        mapA.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        mapA.leftAnchor.constraint(equalTo: splitter.rightAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        mapB.topAnchor.constraint(equalTo: view.topAnchor),
        mapB.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        mapB.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        mapB.leftAnchor.constraint(equalTo: view.leftAnchor),

        toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: extraSpace),
        toolBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        toolBar.widthAnchor.constraint(equalToConstant: toolBar.bounds.width),
        toolBar.heightAnchor.constraint(equalToConstant: toolBar.bounds.height)
    ]
    private lazy var landscapeLeftConstraints: [NSLayoutConstraint] = [
        mapA.topAnchor.constraint(equalTo: view.topAnchor),
        mapA.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        mapA.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        mapA.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        mapB.topAnchor.constraint(equalTo: view.topAnchor),
        mapB.rightAnchor.constraint(equalTo: view.rightAnchor),
        mapB.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        mapB.leftAnchor.constraint(equalTo: splitter.rightAnchor),

        toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: extraSpace),
        toolBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        toolBar.widthAnchor.constraint(equalToConstant: toolBar.bounds.width),
        toolBar.heightAnchor.constraint(equalToConstant: toolBar.bounds.height)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        mapA.otherMap = mapB
        mapB.otherMap = mapA

        mapA.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapA)

        splitter = SplitterView()
        splitter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitter)

        mapB.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapB)

        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBar)

        _ = UserLocation.instance.addListener(self, handlerClassMethod: ViewController.userLocationEventHandler)

        var previousOrientation: UIDeviceOrientation?
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { notification in

            let newOrientation = UIDevice.current.orientation
            guard newOrientation != previousOrientation else { return }
            
            switch newOrientation { // Only act upon these three
            case .portrait: break
            case .landscapeRight: break
            case .landscapeLeft: break
            default: return
            }

            previousOrientation = newOrientation

            if let current = self.currentConstraints { NSLayoutConstraint.deactivate(current) }
            self.currentConstraints = nil // The new constraints will be set in viewDidLayoutSubviews(); see the comments there.

            // When the device's orientation changes between portrait, landscape left, and landscape right iOS performs
            // view layout (viewDidLayoutSubviews() is called). However, when the device passes through the upside down
            // position, on its way to landscape left or lanscape right, then layout does not occur (tested on iOS 13).
            self.view.setNeedsLayout()
        }
    }

    // Wait until viewWillLayoutSubviews to put the new constraints in place.
    // Doing so ensures that the root view's bounds will have been updated to
    // match the new orientation and thus there will be no conflicts between
    // the root view and the new constarints.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if currentConstraints == nil { // The orientationDidChangeNotification handler (see viewDidLoad()) sets it to nil

            switch UIDevice.current.orientation {
            case .portrait: currentConstraints = potraitConstraints
            case .landscapeRight: currentConstraints = landscapeRightConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints
            default: return
            }

            NSLayoutConstraint.activate(currentConstraints)

            splitter.adapt(to: UIDevice.current.orientation)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle { toolBar.setNeedsDisplay() }
    }

    private func userLocationEventHandler(event: UserLocationEvent) {

        switch event {

        case .authorizationUpdate(let authorization):
            switch authorization {
            case .authorizedAlways: fallthrough
            case .authorizedWhenInUse:
                guard let currentLocation = UserLocation.instance.currentLocation?.coordinate else { fatalError("No current location?") }
                let initialSpan: CLLocationDistance = 10000
                mapB.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
                mapA.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 10 * initialSpan, longitudinalMeters: 10 * initialSpan)

            default:
                alertUser(title: "Location Access Not Authorized", body: "\(applicationName) will not be able to provide location related functionality.")
            }

        default: break

        }
    }
}
