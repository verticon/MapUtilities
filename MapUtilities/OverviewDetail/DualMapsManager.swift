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
            var newBounds = dualMaps.mainMap.convert(dualMaps.detailMap.region, toRectTo: dualMaps.mainMap)
            newBounds.size = CGSize(width: max(newBounds.width, 20), height: max(newBounds.height, 20))
            bounds = newBounds
        }
    }

    private static let spanRatio = 10.0

    let mainMap: MKMapView
    let mainDelegate: MKMapViewDelegate?
    
    let detailMap = MKMapView()

    private let detailAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D.zero)

    private var observers = [NSKeyValueObservation]()

    init(mainMap: MKMapView) {
        self.mainMap = mainMap
        self.mainDelegate = mainMap.delegate

        super.init()

        func setup(_ map: MKMapView) {
            map.delegate = self
            observers.append(map.observe(\.bounds, options: [.new]) { [weak self] mapView, change in self?.updateAnnotation() })
        }

        setup(mainMap)
        setup(detailMap)

        detailMap.region = mainMap.region / DualMapsManager.spanRatio

        detailAnnotation.coordinate = detailMap.region.center
        mainMap.addAnnotation(detailAnnotation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers { observer.invalidate() }
        mainMap.removeAnnotation(detailAnnotation)
    }

    private func updateAnnotation() { // Update the annotation's center and bounds to match the detail view.
        detailAnnotation.coordinate = detailMap.region.center
        if let annotationView = mainMap.view(for: detailAnnotation) as? DetailAnnotationView { annotationView.updateBounds(self) }
    }

    @objc func longPressGestureHandler(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            guard let annotationView = mainMap.view(for: detailAnnotation) else { fatalError("Cannot get detail annotation's view") }
            detailMap.region.center = mainMap.convert(recognizer.location(in: annotationView), toCoordinateFrom: annotationView)
            //print("Detail map repositioned to \(detailMap.region.center)")
        default: break
        }
    }
}

extension DualMapsManager : MKMapViewDelegate {

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        print("Forwarding target for \(String(describing: aSelector))")
        return mainDelegate
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { updateAnnotation() }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mainMap.dequeueReusableAnnotationView(withIdentifier: DetailAnnotationView.reuseIdentifier) as? DetailAnnotationView
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
