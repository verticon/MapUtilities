//
//  TestController.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 1/12/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit

class TestController: UIViewController {

    class TestSubView : UIView {
        override func layoutSubviews() {
            print("TestSubView - Laying out subviews, orientation = \(getOrientation()) (\(UIDevice.current.orientation))")
        }
    }

    class TestView : UIView {
        private let subView = TestSubView()

        init() {
            super.init(frame: .zero)

            backgroundColor = .white

            subView.backgroundColor = .gray
            subView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subView)

            NSLayoutConstraint.activate([
                subView.topAnchor.constraint(equalTo: topAnchor, constant: 35),
                subView.centerXAnchor.constraint(equalTo: centerXAnchor),
                subView.heightAnchor.constraint(equalToConstant: 25),
                subView.widthAnchor.constraint(equalToConstant: 75)
            ])
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        // layoutSubviews will be called on startup and subsequently whenever
        // the orientation changes to/from potrait,
        override func layoutSubviews() {
            print("TestView - Laying out subviews, orientation = \(getOrientation()) (\(UIDevice.current.orientation))")
            //subView.setNeedsLayout()
        }
    }

    override func loadView() {
        view = TestView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do { // Add the toolBar last so that it is on top.
            enum ToolIdentifier {
                case layout
                case dismiss
            }

            let toolBar = ToolBar<ToolIdentifier>(parent: view)

            let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
                switch tool.id {
                case .layout: self?.view.setNeedsLayout()
                case .dismiss: self?.dismiss(animated: true, completion: nil)
                }
            }

            let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
                switch tool.id {
                case .dismiss: tool.control.setNeedsDisplay()
                default: break
                }
            }
            
            _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)

            let layoutButton = UIButton(type: .system)
            layoutButton.backgroundColor = .gray
            _ = toolBar.add(control: layoutButton, id: .layout, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        }

        // ***************************************************************************
        
        var notificationObserver: NSObjectProtocol?
        notificationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            print("Test Controller - orientation change notification: \(UIDevice.current.orientation)")

            if self == nil, let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
                notificationObserver = nil
            }
        }
    }
}
