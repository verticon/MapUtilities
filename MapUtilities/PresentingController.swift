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

    private let top = UIView()
    private let map = MKMapView()
    private let bottom = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the subviews and their constarints
            top.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(top)
            map.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(map)
            bottom.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottom)

            NSLayoutConstraint.activate( [
                top.topAnchor.constraint(equalTo: view.topAnchor),
                top.rightAnchor.constraint(equalTo: view.rightAnchor),
                top.leftAnchor.constraint(equalTo: view.leftAnchor),
                top.bottomAnchor.constraint(equalTo: map.topAnchor),

                map.leftAnchor.constraint(equalTo: view.leftAnchor),
                map.rightAnchor.constraint(equalTo: view.rightAnchor),
                map.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                map.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height/3),

                bottom.topAnchor.constraint(equalTo: map.bottomAnchor),
                bottom.rightAnchor.constraint(equalTo: view.rightAnchor),
                bottom.leftAnchor.constraint(equalTo: view.leftAnchor),
                bottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier {
                case overviewDetail
                case tracks
                case test
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .overviewDetail:
                    let child = true
                    if child  {
                        let controller = OverviewDetailController(initialOverviewRegion: self.map.region)
                        self.addChild(controller)
                        controller.view.frame = self.map.frame
                        self.view.addSubview(controller.view)
                        controller.didMove(toParent: self)
                    }
                    else {
                        self.present(OverviewDetailController(initialOverviewRegion: self.map.region), animated: true)
                    }
                    
                case .tracks: self.present(TracksController(initialOverviewRegion: self.map.region), animated: true)
                case .test: self.present(TestController(), animated: true)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in

                guard let originalImage = tool.userData as? UIImage else { return }

                let newImage: UIImage
                switch self.traitCollection.userInterfaceStyle {
                case .dark:
                    guard let image = originalImage.lighten(degree: 0.5, maintainTransparency: true) else { return }
                    newImage = image
                case .light:
                    newImage = originalImage//.darken(degree: 0.5, maintainTransparency: true)
                default: return
                }

                let button = tool.control as! UIButton
                button.setImage(newImage.withRenderingMode(.alwaysOriginal), for: .normal)
            }


            let overviewDetailButton = UIButton(type: .system)
            let overviewDetailImage = UIImage(#imageLiteral(resourceName: "Magnify.png"))
            overviewDetailButton.setImage(overviewDetailImage.withRenderingMode(.alwaysOriginal), for: .normal)
            let overviewDetaiTool = toolBar.add(control: overviewDetailButton, id: .overviewDetail, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
            overviewDetaiTool.userData = overviewDetailImage

            let tracksButton = UIButton(type: .system)
            let tracksButtonImage = UIImage(#imageLiteral(resourceName: "Polyline"))
            tracksButton.setImage(tracksButtonImage.withRenderingMode(.alwaysOriginal), for: .normal)
            let tracksButtonTool = toolBar.add(control: tracksButton, id: .tracks, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
            tracksButtonTool.userData = tracksButtonImage

            let testButton = UIButton(type: .system)
            testButton.backgroundColor = .gray
            _ = toolBar.add(control: testButton, id: .test, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

        _ = UserLocation.instance.addListener(self, handlerClassMethod: PresentingController.userLocationEventHandler)
    }

    private var initialSetupCompleted = false
    private func userLocationEventHandler(event: UserLocationEvent) {

        switch event {
        case .locationUpdate(let userLocation):
            if !self.initialSetupCompleted {
                let initialSpan: CLLocationDistance = 100000
                self.map.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
                self.map.showsUserLocation = true

                self.initialSetupCompleted = true
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
