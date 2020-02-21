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

    private class DetailMapViewDelegate : NSObject, MKMapViewDelegate {

        weak var manager: DualMapsManager!

        init(manager: DualMapsManager) {
            self.manager = manager
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { manager.updateAnnotation() }
    }

    private class MainMapViewDelegate : DetailMapViewDelegate {

        override func forwardingTarget(for selector: Selector!) -> Any? {
            guard let manager = manager else { return super.forwardingTarget(for: selector) }

            let target: Any? = super.forwardingTarget(for: selector) ?? manager.originalDelegate
            //print("DualMapsManager: Forwarding target for \(String(describing: selector)) = \(type(of: target))")
            return target
        }

        override func responds(to selector: Selector!) -> Bool {
            guard let manager = manager else { return super.responds(to: selector) }

            let result = super.responds(to: selector) || manager.originalDelegate?.responds(to: selector) ?? false
            //print("DualMapsManager: Responds to \(String(describing: selector))? \(result ? "Yes" : "No")")
            return result
        }

        override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            super.mapViewDidChangeVisibleRegion(mapView)
            manager.originalDelegate?.mapViewDidChangeVisibleRegion?(mapView)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is DetailAnnotation else {
                return manager.originalDelegate?.mapView?(mapView, viewFor: annotation)
            }

            let annotationView = manager.makeAnnotationView()
            annotationView.updateBounds(manager)
            return annotationView
        }
    }

    private class DetailAnnotation : MKPointAnnotation {
    }

    private class DetailAnnotationView : MKAnnotationView {

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
            super.init(annotation: annotation, reuseIdentifier: nil)
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
    private var mainMapDelegate: MKMapViewDelegate?
    private var originalDelegate: MKMapViewDelegate?

    let detailMap = MKMapView()
    private var detailMapDelegate: MKMapViewDelegate?

    private let detailAnnotation = DetailAnnotation(__coordinate: CLLocationCoordinate2D.zero)

    private var observers = [NSKeyValueObservation]()

    init(mainMap: MKMapView) {
        self.mainMap = mainMap

        super.init()

        originalDelegate = mainMap.delegate
        mainMapDelegate = MainMapViewDelegate(manager: self)
        mainMap.delegate = mainMapDelegate
        observers.append(mainMap.observe(\.bounds, options: [.new]) { [weak self] mapView, change in self?.updateAnnotation() })

        detailMapDelegate = DetailMapViewDelegate(manager: self)
        detailMap.delegate = detailMapDelegate
        observers.append(mainMap.observe(\.bounds, options: [.new]) { [weak self] mapView, change in self?.updateAnnotation() })

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
        mainMap.delegate = originalDelegate
    }

    private func makeAnnotationView() -> DetailAnnotationView {
        let annotationView = DetailAnnotationView(annotation: nil)
        annotationView.isDraggable = true
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureHandler))
        recognizer.allowableMovement = CGFloat.infinity
        recognizer.delegate = self
        annotationView.addGestureRecognizer(recognizer)
        return annotationView
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

extension DualMapsManager : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = gestureRecognizer is UILongPressGestureRecognizer && gestureRecognizer.delegate === self && otherGestureRecognizer is UILongPressGestureRecognizer
        //print("shouldRecognizeSimultaneouslyWith = \(result)")
        return result
    }
}
