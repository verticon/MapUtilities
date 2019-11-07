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
    // We want the splitter view to be thin. This makes it difficult to touch.
    // So, we use a transparant view that is constrained to be centered on the
    // splitter, is thicker, and detects the touches. When the splitter is moved
    // the touch view moves with it.
    private let touchView = TouchView()
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

        touchView.leftAnchor.constraint(equalTo: splitter.leftAnchor),
        touchView.rightAnchor.constraint(equalTo: splitter.rightAnchor),
        touchView.centerYAnchor.constraint(equalTo: splitter.centerYAnchor),
        touchView.heightAnchor.constraint(equalToConstant: TouchView.thickness),

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

        touchView.topAnchor.constraint(equalTo: splitter.topAnchor),
        touchView.bottomAnchor.constraint(equalTo: splitter.bottomAnchor),
        touchView.centerXAnchor.constraint(equalTo: splitter.centerXAnchor),
        touchView.widthAnchor.constraint(equalToConstant: TouchView.thickness),

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

        touchView.topAnchor.constraint(equalTo: splitter.topAnchor),
        touchView.bottomAnchor.constraint(equalTo: splitter.bottomAnchor),
        touchView.centerXAnchor.constraint(equalTo: splitter.centerXAnchor),
        touchView.widthAnchor.constraint(equalToConstant: TouchView.thickness),

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

        splitter = SplitterView(touchView: touchView)
        splitter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitter)

        mapB.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapB)

        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBar)

        // The touch view needs to be on top
        touchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(touchView)

        if let currentLocation = UserLocation.instance.currentLocation?.coordinate {
            let initialSpan: CLLocationDistance = 10000
            mapB.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
            mapA.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 10 * initialSpan, longitudinalMeters: 10 * initialSpan)
        }
        else { print("Cannot get current location") }


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
            // view layout (viewDidLayoutSubviews() is called). However, iwhen the devices passes through the upside down
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
            touchView.adapt(to: UIDevice.current.orientation)
        }
    }

    private func printInfo() {
        func orientation() -> String {
            switch UIDevice.current.orientation {
            case .portrait: return "Portrait"
            case .landscapeRight: return "LandscapeRight"
            case .landscapeLeft: return "LandscapeLeft"
            default: return "Unsupported"
            }
        }
        print("Orientation: \(orientation()), View: W \(view.bounds.width), H \(view.bounds.height) ")
    }
}
