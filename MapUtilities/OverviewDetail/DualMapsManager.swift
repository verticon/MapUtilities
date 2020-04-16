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

        init(manager: DualMapsManager) { self.manager = manager }

        // Whenthe map is  panned or zoomed:
        //      * mapViewDidChangeVisibleRegion is called multiple times while the pan/zoom is in progress
        //      * regionDidChangeAnimated is called once at the end.
        //
        // regionDidChangeAnimated is called whenever the map's frame is changed. When the user drags the
        // splitter the frame will be updated as the splitter is moved: regionDidChangeAnimated is called
        // upon each of those updates. However, if the splitter is animated to a new positio then regionDidChangeAnimated
        // is only called once.

        // Handle the paning and zooming that might occur on either map.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            print("\n\(mapView === manager.detailMap ? "Detail Map": "Main Map"): mapViewDidChangeVisibleRegion")
            manager.syncAnnotationWithDetailMap()
        }
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

        // Handle the frame updates that occur when the user drags the splitter.
        // This only needs to be done for one of the two maps - i.e. it would be
        // redundant to do it twice in a row for each of the maps.
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            print("\n\(mapView === manager.detailMap ? "Detail Map": "Main Map"): regionDidChangeAnimated")
            manager.syncAnnotationWithDetailMap()

            manager.originalDelegate?.mapViewDidChangeVisibleRegion?(mapView)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is DetailAnnotation else {
                return manager.originalDelegate?.mapView?(mapView, viewFor: annotation)
            }

            let annotationView = manager.makeAnnotationView(for: annotation)
            annotationView.updateBounds(manager)
            return annotationView
        }
    }

    private class DetailAnnotation : MKPointAnnotation {}

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

        // Update the size so that it correctly depicts the relative size of the detail map
        func updateBounds(_ manager: DualMapsManager) {
            var newBounds = manager.mainMap.convert(manager.detailMap.region, toRectTo: manager.mainMap)
            
            let minDimension: CGFloat = 20 // Don't let it get so small that it can't be seen
            newBounds.size = CGSize(width: max(newBounds.width, minDimension), height: max(newBounds.height, minDimension))

            bounds = newBounds
        }
    }

    private static let spanRatio = 10.0

    let mainMap: MKMapView
    private var mainMapDelegate: MKMapViewDelegate?
    private var originalDelegate: MKMapViewDelegate?

    let detailMap = MKMapView()
    private var detailMapDelegate: MKMapViewDelegate?

    private var detailAnnotation: DetailAnnotation! = nil

    //private var frameObserver: NSKeyValueObservation! = nil
    private var detailRepositioner: UITapGestureRecognizer! = nil

    init(mainMap: MKMapView) {
        self.mainMap = mainMap

        super.init()

        originalDelegate = mainMap.delegate
        mainMapDelegate = MainMapViewDelegate(manager: self)
        mainMap.delegate = mainMapDelegate
        detailRepositioner = UITapGestureRecognizer(target: self, action: #selector(repositionDetailAnnotation))
        mainMap.addGestureRecognizer(detailRepositioner)

        detailMapDelegate = DetailMapViewDelegate(manager: self)
        detailMap.delegate = detailMapDelegate
 
        detailAnnotation = DetailAnnotation()

        detailMap.region = mainMap.region
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        //frameObserver.invalidate()
        mainMap.removeGestureRecognizer(detailRepositioner)
        mainMap.delegate = originalDelegate
    }

    func zoomDetailMap() {
        let newDetailRegion = mainMap.region / DualMapsManager.spanRatio
        detailAnnotation.coordinate = newDetailRegion.center
        mainMap.addAnnotation(detailAnnotation)
        detailMap.setRegion(newDetailRegion, animated: true)
    }
    
    func removeAnnotation(completion: @escaping () -> ()) {

        UIView.animate(withDuration: 1,
            animations: {
                guard let annotationView = self.mainMap.view(for: self.detailAnnotation) as? DetailAnnotationView else { return }
                print("Removing annotation")
                //annotationView.center = CGPoint(x: self.mainMap.bounds.maxX + annotationView.bounds.width, y: self.mainMap.bounds.maxY + annotationView.bounds.height)
                annotationView.center.x += 100
                annotationView.center.y += 100
            },
            completion: { _ in
                self.mainMap.removeAnnotation(self.detailAnnotation)
                completion()
        })
    }

    private func makeAnnotationView(for: MKAnnotation) -> DetailAnnotationView {
        print("makeAnnotationView")
        let annotationView = DetailAnnotationView(annotation: `for`)

        // Allow the user to reposition the annotation. The Map View utilizes a long press gesture recognizer
        // for this purpose. Note that the annotation's coordinate is not updated until the user ends the drag.
        // Thus we cannot track the annotation's movement via coordinate updates
        annotationView.isDraggable = true

        // Let's intall our own long press gesture recognizer to track the annotaion's
        // movement and update its coordinate during the drag.
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(trackAnnotationDrag))
        recognizer.allowableMovement = CGFloat.infinity
        recognizer.delegate = self
        annotationView.addGestureRecognizer(recognizer)

        return annotationView
    }

    private func syncAnnotationWithDetailMap() { // Update the annotation's center and bounds to match the detail view.
        //print("syncAnnotationWithDetailMap")
        detailAnnotation.coordinate = detailMap.centerCoordinate
        if let annotationView = mainMap.view(for: detailAnnotation) as? DetailAnnotationView { annotationView.updateBounds(self) }
    }

    // As the user drags the detail annotaion, reposition the detail map.
    // Note: iOS updates the detail annotation's coordinate when the drags ends.
    @objc private func trackAnnotationDrag(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            print("\nAnnotation Drag handler: repositioning detail map")
            guard let annotationView = mainMap.view(for: detailAnnotation) else { fatalError("Cannot get detail annotation's view") }
            detailMap.centerCoordinate = mainMap.convert(recognizer.location(in: annotationView), toCoordinateFrom: annotationView)
        default: break
        }
    }

    // When the user taps the main map, reposition the detail annotation to the tapped location
    @objc private func repositionDetailAnnotation(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            detailAnnotation.coordinate = mainMap.convert(recognizer.location(in: mainMap), toCoordinateFrom: mainMap)
       default: break
        }
    }

}

extension DualMapsManager : UIGestureRecognizerDelegate {
    // Allow our long press gesture recognizer to operate in tandem with the map's long press gesture recognizer
    // so that as the user repositions the detail annotation on the main map we can correspondingly reposition the
    // detail map's region.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = gestureRecognizer is UILongPressGestureRecognizer && gestureRecognizer.delegate === self && otherGestureRecognizer is UILongPressGestureRecognizer
        return result
    }
}
