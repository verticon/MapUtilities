//
//  TestController3.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 5/19/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
class TestController3: UIViewController {

    class Container : UIView {
        var map: MKMapView? = nil
    }

    private var container : Container { view as! Container }

    override func loadView() {
        view = Container()
        view.backgroundColor = .magenta
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private var isFirstTime = true
    @objc private func tapHandler(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if isFirstTime { addMap() }
            else { self.dismiss(animated: false, completion: nil) }
            isFirstTime = false
        default: break
        }
    }

    private func addMap() {
        let map = MKMapView()
        
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        NSLayoutConstraint.activate([
            map.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            map.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            map.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85, constant: 0),
            map.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85, constant: 0)
        ])

        let span: CLLocationDistance = 100000
        let location = CLLocationCoordinate2D(latitude: 55, longitude: 35)
        map.region = MKCoordinateRegion(center: location, latitudinalMeters: span, longitudinalMeters: span)

        map.delegate = self

        container.map = map
    }
}

extension TestController3 : MKMapViewDelegate {
}
