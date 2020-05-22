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

    private class TransitionView : UIView {}

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

    private let transitionView = TransitionView()
    private let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()

        Settings.setup()

        view.backgroundColor = .lightGray

        transitionView.translatesAutoresizingMaskIntoConstraints = false
        //transitionView.backgroundColor = .orange
        view.addSubview(transitionView)
        let percentFill: CGFloat = 0.85
        NSLayoutConstraint.activate([
            transitionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transitionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            transitionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: percentFill, constant: 0),
            transitionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: percentFill, constant: 0)
        ])

        func makeConstraints(for: UIView) -> [NSLayoutConstraint] {
            return [
                `for`.centerXAnchor.constraint(equalTo: transitionView.centerXAnchor),
                `for`.centerYAnchor.constraint(equalTo: transitionView.centerYAnchor),
                `for`.heightAnchor.constraint(equalTo: transitionView.heightAnchor),
                `for`.widthAnchor.constraint(equalTo: transitionView.widthAnchor)
            ]
        }

        map.translatesAutoresizingMaskIntoConstraints = false
        transitionView.addSubview(map)
        let mapConstraints = makeConstraints(for: map)
        NSLayoutConstraint.activate(mapConstraints)

        map.delegate = self

        do { // Add the toolBar last so that it is on top.

            enum ToolIdentifier {
                case overviewDetail
                case tracks
                case test
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: transitionView)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .overviewDetail:

                    // removeFromSuperview() is suppossed to deactivate constraints but the debugger shows otherwise???

                    func removeMap() {
                        toolBar.isHidden = true
 
                        self.map.removeFromSuperview()
                        //NSLayoutConstraint.deactivate(self.map.constraints)
                    }

                    func restoreMap() {
                        self.map.removeFromSuperview()
                        //NSLayoutConstraint.deactivate(self.map.constraints)
                        self.transitionView.addSubview(self.map)
                        NSLayoutConstraint.activate(mapConstraints)

                        toolBar.isHidden = false
                        self.transitionView.bringSubviewToFront(toolBar)
                    }

                    // Snapshots are used to hide the hand off of the MapView from one controller to the other.
                    // During a flip horizontal transition, the from controller's view has a blnak area where
                    // where the map had been. The snapshot hides this..

                    if Settings.presentAsChild  {
                        var snapshot = self.map.snapshotView(afterScreenUpdates: false)

                        removeMap()

                        let overviewDetailController = OverviewDetailController(mainMap: self.map, snapshot: snapshot) { controller in
                            snapshot = controller.view.snapshotView(afterScreenUpdates: false)

                            controller.willMove(toParent: nil)
                            controller.view.removeFromSuperview()
                            controller.removeFromParent()

                            restoreMap()

                            if let snapshot = snapshot {
                                self.map.isHidden = true
                                self.transitionView.addSubview(snapshot)
                                snapshot.translatesAutoresizingMaskIntoConstraints = false
                                NSLayoutConstraint.activate(makeConstraints(for: snapshot))

                                // For some reason that I do not yet understand, the UIView.transition would not function quite right if executed directly here
                                // Also, during the flip, the super view (i.e.the TransitionView) is not being shown as I expect. This can be observed by setting
                                // the transition view's background color
                                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                                    UIView.transition(from: snapshot, to: self.map, duration: 1, options: [.transitionFlipFromLeft, .showHideTransitionViews])
                                }
                            }
                        }

                        self.addChild(overviewDetailController)
                        self.view.addSubview(overviewDetailController.view)
                        overviewDetailController.didMove(toParent: self)

                        overviewDetailController.view.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate(makeConstraints(for: overviewDetailController.view))
                    }
                    else {
                        let snapshot = self.view.snapshotView(afterScreenUpdates: false)
                        if snapshot != nil { self.view.addSubview(snapshot!) }

                        removeMap()

                        let overviewDetalController = OverviewDetailController(mainMap: self.map) { controller in
                            controller.presentSnapshot(nil)
                            restoreMap()
                            if snapshot != nil { snapshot!.removeFromSuperview() }
                            controller.dismiss(animated: true, completion: nil)
                        }
                        self.present(overviewDetalController, animated: true)
                    }

                case .tracks: self.present(TracksController(initialOverviewRegion: self.map.region), animated: true)

                case .test: self.present(TestController4(), animated: true)
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

extension PresentingController : MKMapViewDelegate {}
