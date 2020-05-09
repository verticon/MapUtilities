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

    // When a map is panned or zoomed:
    //      * mapViewDidChangeVisibleRegion is called multiple times while the pan/zoom is in progress
    //      * regionDidChangeAnimated is called once at the end.
    //
    // regionDidChangeAnimated is called whenever the map's frame is changed. When the user drags the
    // splitter the frame will be updated as the splitter is moved: regionDidChangeAnimated is called
    // upon each of those updates. However, if the splitter is animated to a new positio then
    // regionDidChangeAnimated is only called once.

    private class DetailMapViewDelegate : NSObject, MKMapViewDelegate {

        weak var manager: DualMapsManager!
        var regionChangeCompletionHandler: (()->())? = nil

        init(manager: DualMapsManager) { self.manager = manager }

        // Handle paning and zooming.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { manager.syncAnnotationWithDetailMap() }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard let completionHandler = regionChangeCompletionHandler else { return }
            regionChangeCompletionHandler = nil
            completionHandler()
        }

        private var firstRender = true
        func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
            guard firstRender else { return }
            manager.detailMap.region = manager.mainMap.region
            firstRender = false
        }
    }

    private class MainMapViewDelegate : NSObject, MKMapViewDelegate {

        weak var manager: DualMapsManager!

        init(manager: DualMapsManager) { self.manager = manager }

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

        // Handle paning and zooming.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            manager.syncAnnotationWithDetailMap()

            manager.originalDelegate?.mapViewDidChangeVisibleRegion?(mapView)
        }

        // Handle the frame updates that occur when the user drags the splitter.
        // This only needs to be done for one of the two maps (i.e. it would be
        // redundant to do it twice in a row for each of the maps). Therefore
        // we only do it in the main map view delegate
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
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

        var background: UIColor { return traitCollection.userInterfaceStyle == .light ? .lightGray : .white }
        var border: UIColor { return traitCollection.userInterfaceStyle == .light ? .red : .blue }
        func setColors(invert: Bool = false) {
            backgroundColor = invert ? border : background
            layer.borderColor = (invert ? background : border).cgColor
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

    let detailMap: MKMapView
    private var detailMapDelegate: DetailMapViewDelegate?

    private var detailAnnotation: DetailAnnotation! = nil

    private var detailRepositioner: UITapGestureRecognizer! = nil

    init(mainMap: MKMapView) {
        self.mainMap = mainMap

        detailMap = MKMapView()

        super.init()

        originalDelegate = mainMap.delegate
        mainMapDelegate = MainMapViewDelegate(manager: self)
        mainMap.delegate = mainMapDelegate

        detailRepositioner = UITapGestureRecognizer(target: self, action: #selector(repositionDetailMapAndAnnotation))
        mainMap.addGestureRecognizer(detailRepositioner)

        detailMapDelegate = DetailMapViewDelegate(manager: self)
        detailMap.delegate = detailMapDelegate
        detailMap.region = mainMap.region
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        mainMap.removeGestureRecognizer(detailRepositioner)
        mainMap.delegate = originalDelegate
    }

    enum Direction {
        case `in`
        case out
    }
    func zoomDetailMap(direction: Direction, completion: (()->())? = nil) {
        var newRegion = mainMap.region
        if direction == .in { newRegion /= DualMapsManager.spanRatio }
        MKMapView.animate(withDuration: 1, animations: { self.detailMap.setRegion(newRegion, animated: true) }, completion: { _ in completion?() })
    }

    func pulseDetailMap(completion: (()->())? = nil) {
        let currentRegion = detailMap.region
        let expandedRegion = 1.5 * currentRegion

        let filter = UIView(frame: detailMap.bounds)
        filter.alpha = 0
        filter.backgroundColor = .red
        detailMap.addSubview(filter)

        func pulse(repetitions: Int) {
            guard repetitions > 0 else {
                filter.removeFromSuperview()
                completion?()
                return
            }

            var annotationView: DetailAnnotationView? = nil
            if let annotation = detailAnnotation {
                annotationView = mainMap.view(for: annotation) as? DetailAnnotationView
            }

            MKMapView.animate(withDuration: 0.25,
                animations: { // Zoom out
                    self.detailMap.setRegion(expandedRegion, animated: true)
                    if let view = annotationView { view.setColors(invert: true) }
                    filter.alpha = 0.2
                },
                completion: { _ in
                    MKMapView.animate(withDuration: 0.25,
                        animations: { // Zoom back in
                            self.detailMap.setRegion(currentRegion, animated: true)
                            if let view = annotationView { view.setColors(invert: false) }
                            filter.alpha = 0
                        },
                        completion: { _ in
                            pulse(repetitions: repetitions - 1)
                        }
                    )
                }
            )
        }

        pulse(repetitions: 3)
    }

    func addAnnotation() {
        guard detailAnnotation == nil else { return }
        detailAnnotation = DetailAnnotation()
        detailAnnotation.coordinate = mainMap.region.center
        mainMap.addAnnotation(detailAnnotation)
    }

    // Note: It is possible (unlikely) that the completion function will be called before the method returns.
    func removeDetailAnnotation(completion: (()->())? = nil) {
        guard let annotation = detailAnnotation else {
            completion?()
            return
        }

        guard let annotationView = mainMap.view(for: annotation) as? DetailAnnotationView  else {
            mainMap.removeAnnotation(annotation)
            completion?()
            return
        }

        MKMapView.animate(withDuration: 0.5, animations: { annotationView.alpha = 0 }) { _ in
            self.mainMap.removeAnnotation(annotation)
            completion?()
        }
    }

    private func makeAnnotationView(for: MKAnnotation) -> DetailAnnotationView {
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

    // Update the annotation's center and bounds to match the detail view.
    private func syncAnnotationWithDetailMap() {
        guard let annotation = detailAnnotation else { return }
        annotation.coordinate = detailMap.centerCoordinate
        if let annotationView = mainMap.view(for: annotation) as? DetailAnnotationView { annotationView.updateBounds(self) }
    }

    // As the user drags the detail annotaion, pan the detail map.
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

    // When the user taps the main map:
    //      1. Reposition the detail annotation to the tapped location
    //      2. Recenter the detail map upon the tapped location
    @objc private func repositionDetailMapAndAnnotation(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
           let tapPoint = recognizer.location(in: mainMap)
           let tapLocation = mainMap.convert(tapPoint, toCoordinateFrom: mainMap)
           if let annotation = detailAnnotation { annotation.coordinate = tapLocation }
           detailMap.region.center = tapLocation
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
