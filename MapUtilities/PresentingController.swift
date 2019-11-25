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
            enum ToolIdentifier {
                case overviewDetail
                case tracks
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { manager in
                switch manager.id {
                case .overviewDetail: self.present(OverviewDetailController(initialOverviewRegion: self.map.region), animated: true)
                case .tracks: self.present(TracksController(initialOverviewRegion: self.map.region), animated: true)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { manager in

                let originalImage = manager.userData as! UIImage

                let newImage: UIImage
                switch self.traitCollection.userInterfaceStyle {
                case .dark:
                    guard let image = originalImage.lighten(degree: 0.5, maintainTransparency: true) else { return }
                    newImage = image
                case .light:
                    newImage = originalImage//.darken(degree: 0.5, maintainTransparency: true)
                default: return
                }

                let button = manager.tool as! UIButton
                button.setImage(newImage.withRenderingMode(.alwaysOriginal), for: .normal)
            }
               
            let overviewDetailButton = UIButton(type: .system)
            let overviewDetailImage = UIImage(#imageLiteral(resourceName: "Magnify.png"))
            overviewDetailButton.setImage(overviewDetailImage.withRenderingMode(.alwaysOriginal), for: .normal)
            let overviewDetaiTool = toolBar.add(tool: overviewDetailButton, id: .overviewDetail, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
            overviewDetaiTool.userData = overviewDetailImage

            let tracksButton = UIButton(type: .system)
            let tracksButtonImage = UIImage(#imageLiteral(resourceName: "Polyline"))
            tracksButton.setImage(tracksButtonImage.withRenderingMode(.alwaysOriginal), for: .normal)
            let tracksButtonTool = toolBar.add(tool: tracksButton, id: .tracks, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
            tracksButtonTool.userData = tracksButtonImage
        }

        _ = UserLocation.instance.addListener(self, handlerClassMethod: PresentingController.userLocationEventHandler)
    }

    private func userLocationEventHandler(event: UserLocationEvent) {

        var zoomedToUser = false
        let performInitialZoom = { (userLocation: CLLocation) in
            guard !zoomedToUser else { return }

            let initialSpan: CLLocationDistance = 100000
            self.map.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
            self.map.showsUserLocation = true

            zoomedToUser = true
        }

        switch event {
        case .locationUpdate(let userLocation): performInitialZoom(userLocation)
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
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            print("Presenting VC: User interface style changed to \(String(describing: self.traitCollection.userInterfaceStyle))")
        }
    }
}
