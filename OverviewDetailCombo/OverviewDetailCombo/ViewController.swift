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

    @IBOutlet weak var detailMap: MKMapView!
    @IBOutlet weak var overviewMap: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let currentLocation = UserLocation.instance.currentLocation?.coordinate {
            let initialSpan: CLLocationDistance = 10000
            detailMap.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)
            overviewMap.region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 10 * initialSpan, longitudinalMeters: 10 * initialSpan)
        }
    }
}

