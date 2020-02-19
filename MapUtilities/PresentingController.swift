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
    private let middle = UIView()
    private let bottom = UIView()
    private let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the subviews and their constarints
            top.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(top)
            middle.translatesAutoresizingMaskIntoConstraints = false
            middle.backgroundColor = .white
            view.addSubview(middle)
            bottom.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottom)

            NSLayoutConstraint.activate( [
                top.topAnchor.constraint(equalTo: view.topAnchor),
                top.rightAnchor.constraint(equalTo: view.rightAnchor),
                top.leftAnchor.constraint(equalTo: view.leftAnchor),
                top.bottomAnchor.constraint(equalTo: middle.topAnchor),

                middle.leftAnchor.constraint(equalTo: view.leftAnchor),
                middle.rightAnchor.constraint(equalTo: view.rightAnchor),
                middle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                middle.heightAnchor.constraint(equalToConstant: 0.9 * UIScreen.main.bounds.height),

                bottom.topAnchor.constraint(equalTo: middle.bottomAnchor),
                bottom.rightAnchor.constraint(equalTo: view.rightAnchor),
                bottom.leftAnchor.constraint(equalTo: view.leftAnchor),
                bottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        map.delegate = self

        map.translatesAutoresizingMaskIntoConstraints = false
        middle.addSubview(map)
        let mapConstraints = [
            map.topAnchor.constraint(equalTo: middle.topAnchor),
            map.rightAnchor.constraint(equalTo: middle.rightAnchor),
            map.leftAnchor.constraint(equalTo: middle.leftAnchor),
            map.bottomAnchor.constraint(equalTo: middle.bottomAnchor),
        ]
        NSLayoutConstraint.activate(mapConstraints)

        do { // Add the toolBar last so that it is on top.

            enum ToolIdentifier {
                case overviewDetail
                case tracks
                case test
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            var overviewDetalController: OverviewDetailController!
            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .overviewDetail:
                    guard let button = tool.control as? UIButton else { fatalError("OverviewDetail tool is not a button???") }
                    button.isSelected = !button.isSelected
                    if button.isSelected  {
                        self.map.removeFromSuperview()
                        overviewDetalController = OverviewDetailController(mainMap: self.map)
                        self.addChild(overviewDetalController)
                        overviewDetalController.view.frame = self.middle.frame
                        self.view.addSubview(overviewDetalController.view)
                        self.view.bringSubviewToFront(toolBar)
                        overviewDetalController.didMove(toParent: self)
                    }
                    else {
                        self.map.removeFromSuperview()
                        overviewDetalController.willMove(toParent: nil)
                        overviewDetalController.view.removeFromSuperview()
                        overviewDetalController.removeFromParent()
                        overviewDetalController = nil
                        self.middle.addSubview(self.map)
                        NSLayoutConstraint.activate(mapConstraints)
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

extension PresentingController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("PresentingController: MapView Region Did Change Animated")
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        print("PresentingController: MapView Did Change Visible Region")
    }

}
