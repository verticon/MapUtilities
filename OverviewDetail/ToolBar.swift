//
//  Toolbar.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/5/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class ToolBar: UIStackView {

    let width: CGFloat = 20
    let height: CGFloat

    init() {

        func makeShape(with frame: CGRect) -> CAShapeLayer {
            let path = UIBezierPath.init(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight, .bottomRight, .bottomLeft], cornerRadii: CGSize.init(width: width/4, height: width/4))
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

        // ****************************************************************************************************

        height = 5 * width

        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))

        let shape = makeShape(with: self.bounds)
        self.layer.insertSublayer(shape, at: 0)
        addShadow(to: self, using: shape.path!)

        self.axis = .vertical

        var button = UIButton(type: .system)
        button.setTitle("1", for: .normal)
        self.addArrangedSubview(button)
        button = UIButton(type: .system)
        button.setTitle("2", for: .normal)
        self.addArrangedSubview(button)
        button = UIButton(type: .system)
        button.setTitle("3", for: .normal)
        self.addArrangedSubview(button)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let shape = self.layer.sublayers?[0] as? CAShapeLayer else { fatalError("No shape layer???") }
        
        switch self.traitCollection.userInterfaceStyle {
        case .dark:
            shape.fillColor = UIColor.lightGray.cgColor
        default:
            shape.fillColor = UIColor.white.cgColor
        }

        shape.opacity = 0.5
    }
}
