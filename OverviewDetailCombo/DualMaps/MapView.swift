//
//  MapView.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/2/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
import VerticonsToolbox

class MapView: MKMapView {

    private class RegionView : MKAnnotationView {
        static let reuseIdentifier = "DualMap"

        func updateBounds(in: MapView) {
            bounds = `in`.convert(`in`.otherMap.region, toRectTo: `in`)
        }
    }

    var otherMap: MapView!

    private let annotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D.zero)
    private var boundsObserver: NSKeyValueObservation!

    init() {
        super.init(frame: CGRect.zero)

        self.delegate = self

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(_:)))
        //tapRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapRecognizer)

        boundsObserver = self.observe(\.bounds, options: [.new]) { mapView, change in
            self.otherMap.updateAnnotation()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isMain : Bool {
        get {
            return self.annotations.count > 0
        }
        set {
            if newValue {
                if !isMain {
                    otherMap.isMain = false
                    updateAnnotation()
                    self.addAnnotation(annotation)
                    self.region.center = annotation.coordinate
                }
                
            }
            else {
                if isMain {
                    self.removeAnnotation(annotation)
                }
            }
        }
    }

    private func updateAnnotation() {
        annotation.coordinate = otherMap.region.center
        if let regionView = self.view(for: annotation), regionView is RegionView { (regionView as! RegionView).updateBounds(in: self) }
    }

    @objc func tapGestureHandler(_ recognizer: UITapGestureRecognizer) {
        isMain = !isMain
    }
}

extension MapView : MKMapViewDelegate {
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        otherMap.updateAnnotation()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = dequeueReusableAnnotationView(withIdentifier: RegionView.reuseIdentifier)
        if annotationView == nil {
            let regionView = RegionView(annotation: nil, reuseIdentifier: RegionView.reuseIdentifier)
            regionView.backgroundColor = .white
            regionView.alpha = 0.1

            annotationView = regionView
        }

        if annotationView is RegionView { (annotationView as! RegionView).updateBounds(in: self) }

        return annotationView
    }
}
