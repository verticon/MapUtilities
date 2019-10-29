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

    private let overviewMap = MKMapView()
    private let splitter = SplitterView()
    private let detailMap = MKMapView()

    private var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
    private lazy var potraitConstraints: [NSLayoutConstraint] = {
        return [
            overviewMap.topAnchor.constraint(equalTo: view.topAnchor),
            overviewMap.rightAnchor.constraint(equalTo: view.rightAnchor),
            overviewMap.bottomAnchor.constraint(equalTo: splitter.topAnchor),
            overviewMap.leftAnchor.constraint(equalTo: view.leftAnchor),

            detailMap.topAnchor.constraint(equalTo: splitter.bottomAnchor),
            detailMap.rightAnchor.constraint(equalTo: view.rightAnchor),
            detailMap.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailMap.leftAnchor.constraint(equalTo: view.leftAnchor)
        ]
    }()
    private lazy var landscapeRightConstraints: [NSLayoutConstraint] = {
        return [
            overviewMap.topAnchor.constraint(equalTo: view.topAnchor),
            overviewMap.rightAnchor.constraint(equalTo: view.rightAnchor),
            overviewMap.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overviewMap.leftAnchor.constraint(equalTo: splitter.rightAnchor),

            detailMap.topAnchor.constraint(equalTo: view.topAnchor),
            detailMap.rightAnchor.constraint(equalTo: splitter.leftAnchor),
            detailMap.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailMap.leftAnchor.constraint(equalTo: view.leftAnchor)
        ]
    }()
    private lazy var landscapeLeftConstraints: [NSLayoutConstraint] = {
        return [
            overviewMap.topAnchor.constraint(equalTo: view.topAnchor),
            overviewMap.rightAnchor.constraint(equalTo: splitter.leftAnchor),
            overviewMap.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overviewMap.leftAnchor.constraint(equalTo: view.leftAnchor),

            detailMap.topAnchor.constraint(equalTo: view.topAnchor),
            detailMap.rightAnchor.constraint(equalTo: view.rightAnchor),
            detailMap.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailMap.leftAnchor.constraint(equalTo: splitter.rightAnchor)
        ]
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        overviewMap.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overviewMap)

        splitter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitter)

        detailMap.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailMap)


        if let currentLocation = UserLocation.instance.currentLocation?.coordinate {
            let initialSpan: CLLocationDistance = 10000
            detailMap.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
            overviewMap.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 10 * initialSpan, longitudinalMeters: 10 * initialSpan)
        }
        else { print("Cannot get current location") }


        var previousOrientation: UIDeviceOrientation?
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { notification in

            switch UIDevice.current.orientation { // Only act upon these three
            case .portrait: break
            case .landscapeRight: break
            case .landscapeLeft: break
            default: return
            }

            self.adapt(from: previousOrientation, to: UIDevice.current.orientation)
            previousOrientation = UIDevice.current.orientation
        }
    }

    private func adapt(from: UIDeviceOrientation?, to: UIDeviceOrientation) {
        
        let newConstraints: [NSLayoutConstraint]

        switch to {
        case .portrait: newConstraints = potraitConstraints
        case .landscapeRight: newConstraints = landscapeRightConstraints
        case .landscapeLeft: newConstraints = landscapeLeftConstraints
        default: return
        }

        if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }
        NSLayoutConstraint.activate(newConstraints)
        currentConstraints = newConstraints

        splitter.adapt(from: from, to: to)
    }


    private func deviceOrientation() -> String {
        let orientation: String
        switch UIDevice.current.orientation {
        case .faceUp: orientation = "faceup"
        case .faceDown: orientation = "facedown"
        case .landscapeLeft: orientation = "landscapeLeft"
        case .landscapeRight: orientation = "landscapeRight"
        case .portrait: orientation = "portrait"
        case .portraitUpsideDown: orientation = "portraitUpsideDown"
        case .unknown: orientation = "facedown"
        default: orientation = "<future>"
        }
        return orientation
    }
}

