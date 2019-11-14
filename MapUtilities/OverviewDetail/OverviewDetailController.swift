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

class OverviewDetailController: UIViewController {

    private let dualMapsManager: DualMapsManager
    private var splitter = SplitterView()
    private let dismissButton = UIButton()

    private var currentConstraints: [NSLayoutConstraint]! // Remember so that they can be deactiveated when needed
    private lazy var potraitConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: splitter.topAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.leftAnchor.constraint(equalTo: view.leftAnchor),
        splitter.rightAnchor.constraint(equalTo: view.rightAnchor),
        splitter.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        splitter.heightAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: splitter.bottomAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: view.leftAnchor),
    ]
    private lazy var landscapeRightConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: splitter.rightAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: view.leftAnchor),
    ]
    private lazy var landscapeLeftConstraints: [NSLayoutConstraint] = [
        dualMapsManager.overview.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.overview.rightAnchor.constraint(equalTo: splitter.leftAnchor),
        dualMapsManager.overview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.overview.leftAnchor.constraint(equalTo: view.leftAnchor),

        splitter.topAnchor.constraint(equalTo: view.topAnchor),
        splitter.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        splitter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

        dualMapsManager.detail.topAnchor.constraint(equalTo: view.topAnchor),
        dualMapsManager.detail.rightAnchor.constraint(equalTo: view.rightAnchor),
        dualMapsManager.detail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        dualMapsManager.detail.leftAnchor.constraint(equalTo: splitter.rightAnchor),
    ]

    init(initialOverviewRegion: MKCoordinateRegion) {
        dualMapsManager = DualMapsManager(initialOverviewRegion: initialOverviewRegion)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dualMapsManager.overview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dualMapsManager.overview)

        splitter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitter)

        dualMapsManager.detail.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dualMapsManager.detail)


        dismissButton.setTitle("D", for: .normal)
        dismissButton.setTitleColor(.lightGray, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismiss(_ :)), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        NSLayoutConstraint.activate( [
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            dismissButton.widthAnchor.constraint(equalToConstant: 50),
            dismissButton.heightAnchor.constraint(equalToConstant: 30)
        ] )


        var previousOrientation: UIDeviceOrientation?
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { _ in
            
            let newOrientation = UIDevice.current.orientation
            guard newOrientation != previousOrientation else { return }
            
            switch newOrientation { // Only act upon these three
            case .portrait: break
            case .landscapeRight: break
            case .landscapeLeft: break
            default: return
            }

            previousOrientation = newOrientation

            if let current = self.currentConstraints { NSLayoutConstraint.deactivate(current) }
            self.currentConstraints = nil // The new constraints will be set in viewDidLayoutSubviews(); see the comments there.

            // When the device's orientation changes between portrait, landscape left, and landscape right iOS performs
            // view layout (viewWillLayoutSubviews() is called). However, when the device passes through the upside down
            // position, on its way to landscape left or lanscape right, then layout does not occur (tested on iOS 13).
            self.view.setNeedsLayout()
        }
    }

    // Wait until viewWillLayoutSubviews to put the new constraints in place.
    // Doing so ensures that the root view's bounds will have been updated to
    // match the new orientation and thus there will be no conflicts between
    // the root view and the new constarints.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if currentConstraints == nil { // It is initially nil, and the orientationDidChangeNotification handler (see viewDidLoad()) sets it to nil

            switch UIDevice.current.orientation {
            case .unknown: fallthrough
            case .faceUp: fallthrough
            case .portraitUpsideDown: fallthrough
            case .faceDown: fallthrough
            case .portrait: currentConstraints = potraitConstraints

            case .landscapeRight: currentConstraints = landscapeRightConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints

            @unknown default: print("Unsupported orientation")
            }

            NSLayoutConstraint.activate(currentConstraints)

            splitter.adapt(to: UIDevice.current.orientation)
        }
    }

    @objc private func dismiss(_ button: UIButton) {
        self.dismiss(animated: true) { }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            dismissButton.setNeedsDisplay()
        }
    }
}
