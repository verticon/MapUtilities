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

    private enum ToolBarButton : Int {
        case overviewDetail
        case tracks
    }

    private let map = MKMapView()
    private let toolBar = ToolBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the toolBar's buttons
            let overviewDetailButton = UIButton(type: .roundedRect)
            overviewDetailButton.setImage(#imageLiteral(resourceName: "MagnifyingGlass.png"), for: .normal)
            overviewDetailButton.addTarget(self, action: #selector(presentTool), for: .touchUpInside)
            overviewDetailButton.tintColor = .orange
            overviewDetailButton.tag = ToolBarButton.overviewDetail.rawValue
            toolBar.addArrangedSubview(overviewDetailButton)

            let tracksButton = UIButton(type: .roundedRect)
            tracksButton.backgroundColor = .brown
            //tracksButton.setImage(#imageLiteral(resourceName: "MagnifyingGlass.png"), for: .normal)
            tracksButton.addTarget(self, action: #selector(presentTool), for: .touchUpInside)
            tracksButton.tag = ToolBarButton.tracks.rawValue
            toolBar.addArrangedSubview(tracksButton)
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

                toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                toolBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
                toolBar.widthAnchor.constraint(equalToConstant: 35),
                toolBar.heightAnchor.constraint(equalToConstant: CGFloat(toolBar.arrangedSubviews.count) * 35)
            ])
        }

        _ = UserLocation.instance.addListener(self, handlerClassMethod: PresentingController.userLocationEventHandler)
    }

    @objc private func presentTool(_ button: UIButton) {
        switch ToolBarButton.init(rawValue: button.tag) {
        case .overviewDetail:
            self.present(OverviewDetailController(initialOverviewRegion: map.region), animated: true) { }
        case .tracks:
            self.present(TracksController(initialOverviewRegion: map.region), animated: true) { }
        case .none:
            print("Unknown toolbar button: \(button.tag)")
        }
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
