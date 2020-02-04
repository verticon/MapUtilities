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

    class OverviewDetailView : UIView {

        private let overview: UIView
        private let splitter = SplitterView()
        private let detail: UIView
        private var currentConstraints: [NSLayoutConstraint]?

        init(overview: UIView, detail: UIView) {
            self.overview = overview
            self.detail = detail
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
           overview.topAnchor.constraint(equalTo: self.topAnchor),
           overview.rightAnchor.constraint(equalTo: self.rightAnchor),
           overview.bottomAnchor.constraint(equalTo: splitter.topAnchor),
           overview.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.leftAnchor.constraint(equalTo: self.leftAnchor),
           splitter.rightAnchor.constraint(equalTo: self.rightAnchor),
           splitter.centerYAnchor.constraint(equalTo: self.centerYAnchor),
           splitter.heightAnchor.constraint(equalToConstant: SplitterView.thickness),

           detail.topAnchor.constraint(equalTo: splitter.bottomAnchor),
           detail.rightAnchor.constraint(equalTo: self.rightAnchor),
           detail.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           detail.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeRightConstraints = [
           overview.topAnchor.constraint(equalTo: self.topAnchor),
           overview.rightAnchor.constraint(equalTo: self.rightAnchor),
           overview.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           overview.leftAnchor.constraint(equalTo: splitter.rightAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

           detail.topAnchor.constraint(equalTo: self.topAnchor),
           detail.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           detail.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           detail.leftAnchor.constraint(equalTo: self.leftAnchor),
        ]
        private lazy var landscapeLeftConstraints = [
           overview.topAnchor.constraint(equalTo: self.topAnchor),
           overview.rightAnchor.constraint(equalTo: splitter.leftAnchor),
           overview.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           overview.leftAnchor.constraint(equalTo: self.leftAnchor),

           splitter.topAnchor.constraint(equalTo: self.topAnchor),
           splitter.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           splitter.centerXAnchor.constraint(equalTo: self.centerXAnchor),
           splitter.widthAnchor.constraint(equalToConstant: SplitterView.thickness),

           detail.topAnchor.constraint(equalTo: self.topAnchor),
           detail.rightAnchor.constraint(equalTo: self.rightAnchor),
           detail.bottomAnchor.constraint(equalTo: self.bottomAnchor),
           detail.leftAnchor.constraint(equalTo: splitter.rightAnchor),
        ]

        override func layoutSubviews() {
            let orientation = getOrientation()
            print("OverviewDetailView - Laying out subviews, orientation = \(orientation) (\(UIDevice.current.orientation))")

            if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }

            switch orientation {
            case .portrait: currentConstraints = potraitConstraints
            case .landscapeRight: currentConstraints = landscapeRightConstraints
            case .landscapeLeft: currentConstraints = landscapeLeftConstraints
            default: fatalError("This shouldn't happen")
            }

            NSLayoutConstraint.activate(currentConstraints!)
        }
    }

    private enum ToolIdentifier : Int, CaseIterable {
        case dismiss
    }

    private let dualMapsManager: DualMapsManager

    init(initialOverviewRegion: MKCoordinateRegion) {
        dualMapsManager = DualMapsManager(initialOverviewRegion: initialOverviewRegion)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("OverviewDetailController Deinit") }

    override func loadView() {
        view = OverviewDetailView(overview: dualMapsManager.overviewMap, detail: dualMapsManager.detailMap)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier {
                case dismiss
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
                switch tool.id {
                case .dismiss: self?.dismiss(animated: true, completion: nil)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .dismiss: tool.control.setNeedsDisplay()
                }
            }
            
            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }


        var notificationObserver: NSObjectProtocol?
        notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            print("OverviewDetailController - orientation change notification: \(getOrientation()) (\(UIDevice.current.orientation))")

            if self == nil, let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
                notificationObserver = nil
            }
        }
    }
}
