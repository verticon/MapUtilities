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

    private class Settings {
        struct Keys {
            static let child = "ChildPreference"
        }

        static var presentAsChild = false

        static func setup() {
            _ = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) {  _ in
                presentAsChild = UserDefaults.standard.bool(forKey: Settings.Keys.child)
            }
        }
    }

    private let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        Settings.setup()

        func getConstraints(for: UIView) -> [NSLayoutConstraint] {
            let percentInset: CGFloat = 0.85
            return [
                `for`.centerXAnchor.constraint(equalToSystemSpacingAfter: view.centerXAnchor, multiplier: 1),
                `for`.centerYAnchor.constraint(equalToSystemSpacingBelow: view.centerYAnchor, multiplier: 1),
                `for`.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: percentInset),
                `for`.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: percentInset)
            ]
        }

        map.delegate = self
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        let mapConstraints = getConstraints(for: map)
        NSLayoutConstraint.activate(mapConstraints)


        do { // Add the toolBar last so that it is on top.

            enum ToolIdentifier {
                case overviewDetail
                case tracks
                case test
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: map)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .overviewDetail:

                    func removeMap() {
                        toolBar.removeFromSuperview()
                        self.map.removeFromSuperview() // Constraints are deactivated
                    }

                    func restoreMap() {
                        self.map.removeFromSuperview() // Constraints are deactivated
                        self.view.addSubview(self.map)
                        NSLayoutConstraint.activate(mapConstraints)
                        toolBar.add(to: self.map)
                    }

                    removeMap()
                    if Settings.presentAsChild  {
                        var overviewDetalController: OverviewDetailController!
                        overviewDetalController = OverviewDetailController(mainMap: self.map) { controller in
                            controller.hideDetail {
                                overviewDetalController.willMove(toParent: nil)
                                overviewDetalController.view.removeFromSuperview()
                                overviewDetalController.removeFromParent()
                                overviewDetalController = nil

                                restoreMap()
                           }
                        }
                        self.addChild(overviewDetalController)
                        self.view.addSubview(overviewDetalController.view)
                        overviewDetalController.didMove(toParent: self)

                        overviewDetalController.view.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate(getConstraints(for: overviewDetalController.view))
                    }
                    else {
                        let snapshot = self.view.snapshotView(afterScreenUpdates: false)
                        if snapshot != nil { self.view.addSubview(snapshot!) }
                        let controller = OverviewDetailController(mainMap: self.map) { controller in
                            controller.hideDetail() {
                                controller.presentSnapshot()
                                restoreMap()
                                if let snapshot = snapshot { snapshot.removeFromSuperview() }
                                controller.dismiss(animated: true, completion: nil)
                            }
                        }
                        self.present(controller, animated: true) { controller.showDetail() }
                    }

                case .tracks: self.present(TracksController(initialOverviewRegion: self.map.region), animated: true)

                case .test: self.present(TestController2(), animated: true)
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

//            let tracksButton = UIButton(type: .system)
//            let tracksButtonImage = UIImage(#imageLiteral(resourceName: "Polyline"))
//            tracksButton.setImage(tracksButtonImage.withRenderingMode(.alwaysOriginal), for: .normal)
//            let tracksButtonTool = toolBar.add(control: tracksButton, id: .tracks, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
//            tracksButtonTool.userData = tracksButtonImage

//            let testButton = UIButton(type: .system)
//            testButton.backgroundColor = .gray
//            _ = toolBar.add(control: testButton, id: .test, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
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
}
