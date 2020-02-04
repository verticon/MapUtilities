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

class DualMapsManager : NSObject {

    private class DetailAnnotationView : MKAnnotationView {
        static let reuseIdentifier = "Detail"

        private func setColors() {
            if self.traitCollection.userInterfaceStyle == .light {
                backgroundColor = UIColor.darkGray
                layer.borderColor = UIColor.black.cgColor
            }
            else {
                backgroundColor = UIColor.white
                layer.borderColor = UIColor.blue.cgColor
            }
        }

        init(annotation: MKAnnotation?) {
            super.init(annotation: annotation, reuseIdentifier: DetailAnnotationView.reuseIdentifier)
            alpha = 0.2
            layer.borderWidth = 1
            setColors()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle { setColors() }
        }

        func updateBounds(_ dualMaps: DualMapsManager) {
            var newBounds = dualMaps.overviewMap.convert(dualMaps.detailMap.region, toRectTo: dualMaps.overviewMap)
            newBounds.size = CGSize(width: max(newBounds.width, 20), height: max(newBounds.height, 20))
            bounds = newBounds
        }
    }

    private static let spanRatio = 10.0

    let overviewMap = MKMapView()
    let detailMap = MKMapView()

    private let detailAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D.zero)

    private var observers = [NSKeyValueObservation]()

    init(initialOverviewRegion: MKCoordinateRegion) {

        super.init()

        func setup(map: MKMapView) {
            map.delegate = self
            map.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(_:))))
            observers.append(map.observe(\.bounds, options: [.new]) { mapView, change in self.updateAnnotation() })
        }

        setup(map: overviewMap)
        setup(map: detailMap)

        overviewMap.region = initialOverviewRegion
        detailMap.region = initialOverviewRegion / DualMapsManager.spanRatio

        detailAnnotation.coordinate = detailMap.region.center
        overviewMap.addAnnotation(detailAnnotation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAnnotation() { // Update the annotation's center and bounds to match the detail view.
        detailAnnotation.coordinate = detailMap.region.center
        if let annotationView = overviewMap.view(for: detailAnnotation) as? DetailAnnotationView { annotationView.updateBounds(self) }
    }

    @objc func tapGestureHandler(_ recognizer: UITapGestureRecognizer) {
        guard let mapView = recognizer.view as? MKMapView else { return }
        
        if mapView == overviewMap { // Center both maps on the tap point
            let touchPoint = recognizer.location(in: overviewMap)
            let touchCoordinate = overviewMap.convert(touchPoint, toCoordinateFrom: overviewMap)
            overviewMap.region.center = touchCoordinate
            detailMap.region = overviewMap.region / DualMapsManager.spanRatio
        }
        else { // Center the Overview map on the Detail map
            overviewMap.region = DualMapsManager.spanRatio * detailMap.region
        }
    }

    @objc func longPressGestureHandler(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            guard let annotationView = overviewMap.view(for: detailAnnotation) else { fatalError("Cannot get detail annotation's view") }
            detailMap.region.center = overviewMap.convert(recognizer.location(in: annotationView), toCoordinateFrom: annotationView)
            //print("Detail map repositioned to \(detailMap.region.center)")
        default: break
        }
    }
}

extension DualMapsManager : MKMapViewDelegate {
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { updateAnnotation() }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = overviewMap.dequeueReusableAnnotationView(withIdentifier: DetailAnnotationView.reuseIdentifier) as? DetailAnnotationView
        if annotationView == nil {
            annotationView = DetailAnnotationView(annotation: nil)
            annotationView!.isDraggable = true
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureHandler))
            recognizer.allowableMovement = CGFloat.infinity
            recognizer.delegate = self
            annotationView!.addGestureRecognizer(recognizer)
        }
        annotationView!.updateBounds(self)
        return annotationView
    }
}

extension DualMapsManager : UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UILongPressGestureRecognizer && gestureRecognizer.delegate === self && otherGestureRecognizer is UILongPressGestureRecognizer
    }
}
