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

class PresentingController: UIViewController {

    private let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the subviews and their constarints
            map.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(map)
     
            NSLayoutConstraint.activate( [
                map.topAnchor.constraint(equalTo: view.topAnchor),
                map.rightAnchor.constraint(equalTo: view.rightAnchor),
                map.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                map.leftAnchor.constraint(equalTo: view.leftAnchor),
            ])
        }

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier : Int, CaseIterable {
                case overviewDetail
                case tracks
            }

            let toolBar = ToolBar(parent: view) { (identifier: ToolIdentifier) in
                switch identifier {
                case .overviewDetail: self.present(OverviewDetailController(initialOverviewRegion: self.map.region), animated: true) { }
                case .tracks: self.present(TracksController(initialOverviewRegion: self.map.region), animated: true) { }
                }
            }

            let overviewDetailButton = toolBar.getButton(for: .overviewDetail)
            let magnifyImage = UIImage(#imageLiteral(resourceName: "Magnify.png")).withRenderingMode(.alwaysOriginal)
            overviewDetailButton.setImage(magnifyImage, for: .normal)
            overviewDetailButton.alpha = 0.75

            let tracksButton = toolBar.getButton(for: .tracks)
            let polylineImage = UIImage(#imageLiteral(resourceName: "Polyline")).withRenderingMode(.alwaysOriginal)
            tracksButton.setImage(polylineImage, for: .normal)
            tracksButton.alpha = 0.75
        }

        _ = UserLocation.instance.addListener(self, handlerClassMethod: PresentingController.userLocationEventHandler)
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
}
