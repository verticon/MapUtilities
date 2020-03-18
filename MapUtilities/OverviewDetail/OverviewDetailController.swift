//
//  ViewController.swift
//  OverviewDetailCombo
//
//  Created by Robert Vaessen on 9/22/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit
import MapKit
import Darwin
import VerticonsToolbox

class OverviewDetailController: UIViewController {

    class SplitView : UIView {

        private let upper: UIView
        let splitter = Splitter()
        private let lower: UIView
        private var currentConstraints: [NSLayoutConstraint]?

        init(overview: UIView, detail: UIView) {
            self.upper = overview
            self.lower = detail
            super.init(frame: .zero)

            overview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(overview)

            splitter.translatesAutoresizingMaskIntoConstraints = false
            addSubview(splitter)

            detail.translatesAutoresizingMaskIntoConstraints = false
            addSubview(detail)
        }
        
        required init?(coder: NSCoder) { fatalError("OverviewDetailView - init(coder:) has not been implemented") }
        
        private lazy var potraitConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: self.rightAnchor),
           upper.bottomAnchor.constraint(equalTo: splitter.topAnchor),
           upper.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.leftAnchor.constraint(equalTo: self.leftAnchor),
           splitter.rightAnchor.constraint(equalTo: self.rightAnchor),
           splitter.centerYAnchor.constraint(equalTo: self.centerYAnchor),
           splitter.heightAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: splitter.bottomAnchor),
           lower.rightAnchor.constraint(equalTo: self.rightAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeRightConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: self.rightAnchor),
           upper.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           upper.leftAnchor.constraint(equalTo: splitter.rightAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: self.topAnchor),
           lower.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeLeftConstraints = [
           upper.topAnchor.constraint(equalTo: self.topAnchor),
           upper.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           upper.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           upper.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: Splitter.thickness),

           lower.topAnchor.constraint(equalTo: self.topAnchor),
           lower.rightAnchor.constraint(equalTo: self.rightAnchor),
           lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           lower.leftAnchor.constraint(equalTo: splitter.rightAnchor),
        ]

        override func layoutSubviews() {
    
            func selectConstraints() -> [NSLayoutConstraint] {
                switch getOrientation() {
                case .portrait: return potraitConstraints
                case .landscapeRight: return landscapeRightConstraints
                case .landscapeLeft: return landscapeLeftConstraints
                default: fatalError("This shouldn't happen")
                }
            }

            if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }
            currentConstraints = selectConstraints()
            updateSplitterPosition()
            NSLayoutConstraint.activate(currentConstraints!)
        }


        // The magnitude of the splitter's offset remains the same in portrait or in landscape; the splitter is always
        // moving through the device's longer dimension (y in portrait, x in landscape). The sign (+/-) might, however,
        // change when the orientation changes.

        func updateSplitterPosition() {
            func getSplitterCenterConstraint() -> NSLayoutConstraint {
                for constraint in  currentConstraints! {
                    if constraint.firstItem === splitter && (constraint.firstAttribute == .centerY || constraint.firstAttribute == .centerX) {
                        return constraint
                    }
                }

                fatalError("No center constraint???")
            }

            getSplitterCenterConstraint().constant = splitter.offset
        }
    }

    private let dualMapsManager: DualMapsManager
    private let mainMapInitialConstraints: [NSLayoutConstraint]

    init(mainMap: MKMapView) {
        mainMapInitialConstraints = mainMap.constraints
        dualMapsManager = DualMapsManager(mainMap: mainMap)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let splitView = SplitView(overview: dualMapsManager.mainMap, detail: dualMapsManager.detailMap)
        splitView.splitter.percentOffset = 1
        view = splitView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // When coming out of portraitUpsideDown iOS does not perform layout (iOS 13). Feels odd ...
        var previousOrientation: UIDeviceOrientation = .unknown
        var notificationObserver: NSObjectProtocol?
        notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            let newOrientation = UIDevice.current.orientation
            //print("OverviewDetailController - orientation change notification: \(getOrientation()) (\(newOrientation))")

            guard self != nil else  {
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                    notificationObserver = nil
                }
                return
            }

            if previousOrientation == .portraitUpsideDown { self!.view.setNeedsLayout() }
            previousOrientation = newOrientation
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateSplitter(to: 0)
    }

    func animateSplitter(to percentOffset: CGFloat) {
        guard  let splitView = view as? SplitView else { return }

        splitView.splitter.percentOffset = percentOffset
        splitView.updateSplitterPosition()
        UIView.animate(withDuration: 2,
            animations: { splitView.layoutIfNeeded() },
            completion: { _ in self.dualMapsManager.initialPesentationCompleted() })
    }
}
