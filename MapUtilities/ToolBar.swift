//
//  Toolbar.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/5/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class ToolBar<ButtonIdentifier : RawRepresentable & CaseIterable>: UIStackView where ButtonIdentifier.RawValue == Int  {

    private let buttonHandler: (ButtonIdentifier) -> ()

    init(parent: UIView, dismissButton: DismissButton? = nil, buttonHandler: @escaping (ButtonIdentifier) -> ()) {

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

        func addButtons() {
            if let button = dismissButton { self.addArrangedSubview(button) }
            for identifier in ButtonIdentifier.allCases {
                let button = UIButton(type: .system)
                button.tag = identifier.rawValue
                button.addTarget(self, action: #selector(buttonPressHandler), for: .touchUpInside)
                self.addArrangedSubview(button)
            }
        }

        // addToParent depends upon the buttons having already been added; the button count is used in the height constraint
        func addToParent() {
            self.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(self)

            NSLayoutConstraint.activate( [
                self.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: 20),
                self.rightAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.rightAnchor, constant: -20),
                self.widthAnchor.constraint(equalToConstant: 35),
                self.heightAnchor.constraint(equalToConstant: CGFloat(self.arrangedSubviews.count) * 35)
           ])
        }
        // ****************************************************************************************************

        self.buttonHandler = buttonHandler

        super.init(frame: CGRect.zero)

        let shape = makeShape(with: self.bounds)
        self.layer.insertSublayer(shape, at: 0)
        addShadow(to: self, using: shape.path!)

        addButtons()

        addToParent()

        self.axis = .vertical
        self.distribution = .fillEqually
        self.alpha = 0.5
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getButton(for: ButtonIdentifier) -> UIButton {
        for view in self.arrangedSubviews {
            guard let button = view as? UIButton, !(button is DismissButton) else { continue }
            if button.tag == `for`.rawValue { return button }
        }
        fatalError("There is not a button for \(`for`)")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            guard let shape = self.layer.sublayers?[0] as? CAShapeLayer else { fatalError("No shape layer???") }
            
            switch self.traitCollection.userInterfaceStyle {
            case .dark: shape.fillColor = UIColor.lightGray.cgColor
            default: shape.fillColor = UIColor.white.cgColor
            }

            shape.opacity = 0.5
        }
    }
    
    @objc private func buttonPressHandler(_ button: UIButton) {
        guard let identifier = ButtonIdentifier.init(rawValue: button.tag) else {
            fatalError("Invalid \(ButtonIdentifier.self): \(button.tag)")
        }

        buttonHandler(identifier)
    }
}
