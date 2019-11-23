//
//  Toolbar.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/5/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class ToolBar<ToolIdentifier> : UIStackView {

    typealias Handler = (ToolManager) -> Void

    class ToolManager {

        let tool: UIControl
        let id: ToolIdentifier

        var userData: Any?

        private let actionHandler: Handler
        private let styleChangeHandler: Handler

        fileprivate init(tool: UIControl, id: ToolIdentifier, actionHandler: @escaping Handler, styleChangeHandler: @escaping Handler) {
            self.tool = tool
            self.id = id
            self.actionHandler = actionHandler
            self.styleChangeHandler = styleChangeHandler

            tool.addTarget(self, action: #selector(toolPressHandler), for: .touchUpInside)
        }

        fileprivate func userInterfaceStyleChanged() { styleChangeHandler(self) }

        @objc private func toolPressHandler(_ tool: UIControl) { self.actionHandler(self) }
    }

    // ****************************************************************************************************

    private var managers = [ToolManager]()

    init(parent: UIView) {

        func makeShape(with frame: CGRect) -> CAShapeLayer {
            let path = UIBezierPath.init(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight, .bottomRight, .bottomLeft], cornerRadii: CGSize.init(width: 5, height: 5))
            let shape = CAShapeLayer.init()
            shape.frame = frame
            shape.path = path.cgPath
            shape.masksToBounds = true
            return shape
        }

        func addShadow(to toolbar: ToolBar, using path: CGPath) {
            toolbar.layer.shadowRadius = 8
            toolbar.layer.shadowOpacity = 0.2
            toolbar.layer.shadowOffset = CGSize.init(width: 0, height: 2.5)
            toolbar.layer.shadowColor = UIColor.black.cgColor
            toolbar.layer.shadowPath = path
        }

        func addToSuperView() {
            self.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(self)

            NSLayoutConstraint.activate( [
                self.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: 20),
                self.rightAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.rightAnchor, constant: -20),
                self.widthAnchor.constraint(equalToConstant: 35),
                self.heightAnchor.constraint(equalToConstant:  35)
           ])
        }

        // ****************************************************************************************************

        super.init(frame: CGRect.zero)

        let shape = makeShape(with: self.bounds)
        self.layer.insertSublayer(shape, at: 0)
        addShadow(to: self, using: shape.path!)

        addToSuperView()

        self.axis = .vertical
        self.distribution = .fillEqually
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    func add(tool: UIControl, id: ToolIdentifier, actionHandler: @escaping Handler, styleChangeHandler: @escaping Handler) {
        self.addArrangedSubview(tool)

        let heightConstraint = constraints.first(where: { $0.firstAttribute == .height && $0.relation == .equal })
        heightConstraint?.constant = CGFloat(35 * arrangedSubviews.count)
        setNeedsLayout()

        managers.append(ToolManager(tool: tool, id: id, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {

            print("ToolBar: User interface style changed to \(String(describing: self.traitCollection.userInterfaceStyle))")

            guard let shape = self.layer.sublayers?[0] as? CAShapeLayer else { fatalError("No shape layer???") }
            
            switch self.traitCollection.userInterfaceStyle {
            case .dark: shape.fillColor = UIColor.lightGray.cgColor
            default: shape.fillColor = UIColor.white.cgColor
            }

            shape.opacity = 0.5

            for manager in managers { manager.userInterfaceStyleChanged() }
        }
    }
}
