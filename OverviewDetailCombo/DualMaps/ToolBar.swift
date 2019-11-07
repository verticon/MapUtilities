//
//  Toolbar.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/5/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

class ToolBar: UIView {

    let width: CGFloat = 20
    let height: CGFloat

    init() {

        func makeShape(with frame: CGRect) -> CAShapeLayer {
            let path = UIBezierPath.init(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight, .bottomRight, .bottomLeft], cornerRadii: CGSize.init(width: width/4, height: width/4))
            let shape = CAShapeLayer.init()
            shape.frame = frame
            shape.path = path.cgPath
            shape.fillColor = UIColor.lightGray.cgColor
            shape.opacity = 0.5
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
