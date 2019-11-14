//
//  ViewController.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 11/13/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
import VerticonsToolbox

class ViewController: UIViewController {

    private let map = MKMapView()
    private let toolBar = ToolBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the toolBar's buttons
            var button = UIButton(type: .system)
            button.setTitle("1", for: .normal)
            button.addTarget(self, action: #selector(presentOverviewDetail), for: .touchUpInside)
            toolBar.addArrangedSubview(button)
            button = UIButton(type: .system)
            button.setTitle("2", for: .normal)
            toolBar.addArrangedSubview(button)
            button = UIButton(type: .system)
            button.setTitle("3", for: .normal)
            toolBar.addArrangedSubview(button)
        }

        do { // Add the subviews and their constarints
            map.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(map)
     
            toolBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(toolBar)

            NSLayoutConstraint.activate( [
                map.topAnchor.constraint(equalTo: view.topAnchor),
                map.rightAnchor.constraint(equalTo: view.rightAnchor),
                map.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                map.leftAnchor.constraint(equalTo: view.leftAnchor),

                toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                toolBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
                toolBar.widthAnchor.constraint(equalToConstant: 50),
                toolBar.heightAnchor.constraint(equalToConstant: CGFloat(toolBar.arrangedSubviews.count) * 25)
            ])
        }

        _ = UserLocation.instance.addListener(self, handlerClassMethod: ViewController.userLocationEventHandler)
    }

    @objc private func presentOverviewDetail(_ button: UIButton) {
        self.present(OverviewDetailController(initialOverviewRegion: map.region), animated: true) {  }
    }

    private var zoomedToUser = false
    private func userLocationEventHandler(event: UserLocationEvent) {

        switch event {
        case .locationUpdate(let userLocation):
            if !zoomedToUser {
                let initialSpan: CLLocationDistance = 100000
                map.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
                map.showsUserLocation = true

                zoomedToUser = true
            }
        case .authorizationUpdate(let authorization):
            switch authorization {
            case .restricted: fallthrough
            case .denied: alertUser(title: "Location Access Not Authorized", body: "\(applicationName) will not be able to provide location related functionality.")
            default: break
            }

        default: break
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle { toolBar.setNeedsDisplay() }
    }

}
