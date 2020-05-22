//
//  TestController4.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 5/20/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit

class TestController4: UIViewController {

    let container = UIView()
    let subViewA = UIView()
    let subViewB = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .orange
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear
        view.addSubview(container)
        let percentFill: CGFloat = 0.85
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: percentFill, constant: 0),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: percentFill, constant: 0)
        ])

        subViewA.translatesAutoresizingMaskIntoConstraints = false
        subViewA.backgroundColor = .cyan
        container.addSubview(subViewA)
        NSLayoutConstraint.activate([
            subViewA.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            subViewA.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            subViewA.heightAnchor.constraint(equalTo: container.heightAnchor),
            subViewA.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])

        subViewB.translatesAutoresizingMaskIntoConstraints = false
        subViewB.backgroundColor = .magenta
        container.addSubview(subViewB)
        NSLayoutConstraint.activate([
            subViewB.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            subViewB.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            subViewB.heightAnchor.constraint(equalTo: container.heightAnchor),
            subViewB.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])

        subViewB.isHidden = true
    
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler)))
        
        addToolbar()
    }

    @objc private func tapHandler(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {

        case .ended:
            var from = subViewA
            var to = subViewB
            var flip: UIView.AnimationOptions = .transitionFlipFromLeft
            if subViewA.isHidden {
                from = subViewB
                to = subViewA
                flip = .transitionFlipFromRight
            }
            UIView.transition(from: from, to: to, duration: 1, options: [flip, .showHideTransitionViews])

        default: break
        }
    }

    private var toolBar: UIView? = nil
    private func addToolbar() {
        enum ToolIdentifier {
            case dismiss
        }

        let toolBar = ToolBar<ToolIdentifier>(parent: view)

        let actionHandler: ToolBar<ToolIdentifier>.EventHandler = { [weak self] tool in
            switch tool.id {
            case .dismiss:
                guard let controller = self else { return }
                controller.dismiss(animated: true, completion: nil)
            }
        }

        let styleChangeHandler: ToolBar<ToolIdentifier>.EventHandler = { tool in
            switch tool.id {
            case .dismiss: tool.control.setNeedsDisplay()
            }
        }
        
        _ = toolBar.add(control: DismissButton(), id: .dismiss, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)

        self.toolBar = toolBar
    }


    override var modalPresentationStyle: UIModalPresentationStyle {
        get { return .popover }
        set {}
    }

    override var modalTransitionStyle: UIModalTransitionStyle {
        get { return .flipHorizontal }
        set {}
    }
}
