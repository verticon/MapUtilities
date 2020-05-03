//
//  Toolbar.swift
//  DualMaps
//
//  Created by Robert Vaessen on 11/5/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import UIKit

protocol Tool : class {
    associatedtype Identifier

    var control: UIControl { get }
    var id: Identifier { get }
    var userData: Any? { get set }
}

private extension Tool { // These methods allow AnyTool to erasure the properties
    func getControl() -> UIControl { return control }
    func getId() -> Identifier { return id }
    func getUserData() -> Any? { return userData }
    func setUserData(newData: Any? ) {  userData = newData }
}

class AnyTool<Identifier> : Tool { // AnyTool allows an instance of the Tool protocol to be returned to the ToolBar user.
    
    private var getControl: () -> UIControl
    private var getId: () -> Identifier
    private var getUserData: () -> Any?
    private var setUserData: (Any?) -> ()

    fileprivate init<SomeTool: Tool>(tool: SomeTool) where SomeTool.Identifier == Identifier {
        getControl = tool.getControl
        getId = tool.getId
        getUserData = tool.getUserData
        setUserData = tool.setUserData
    }

    var control: UIControl { return getControl() }
    var id: Identifier { return getId() }
    var userData: Any? {
        get { return getUserData() }
        set { setUserData(newValue) }
    }
}

class ToolBar<ToolIdentifier> : UIStackView {

    typealias EventHandler = (AnyTool<ToolIdentifier>) -> Void

    private class ToolBarTool : Tool { // This Tool adopter will be type erased by AnyTool

        let control: UIControl
        let id: ToolIdentifier
        var userData: Any?

        var anyTool: AnyTool<ToolIdentifier>!

        private let actionHandler: EventHandler
        private let styleChangeHandler: EventHandler

        fileprivate init(control: UIControl, id: ToolIdentifier, actionHandler: @escaping EventHandler, styleChangeHandler: @escaping EventHandler) {
            self.control = control
            self.id = id
            self.actionHandler = actionHandler
            self.styleChangeHandler = styleChangeHandler

            control.addTarget(self, action: #selector(toolPressHandler), for: .touchUpInside)
        }

        fileprivate func userInterfaceStyleChanged() { styleChangeHandler(anyTool) }

        @objc private func toolPressHandler(_ tool: UIControl) { self.actionHandler(anyTool) }
    }

    // ****************************************************************************************************

    private var tools = [ToolBarTool]()

    init(parent: UIView, inset: CGFloat = 20) {

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
                self.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: inset),
                self.rightAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.rightAnchor, constant: -inset),
                self.widthAnchor.constraint(equalToConstant: 35),
                self.heightAnchor.constraint(equalToConstant:  35)
           ])
        }

        // ****************************************************************************************************

        super.init(frame: CGRect.zero)

        let shape = makeShape(with: self.bounds)
        self.layer.insertSublayer(shape, at: 0)
        addShadow(to: self, using: shape.path!)

        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 5
        
        addToSuperView()

        self.axis = .vertical
        self.distribution = .fillEqually
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    func add(control: UIControl, id: ToolIdentifier, actionHandler: @escaping EventHandler, styleChangeHandler: @escaping EventHandler) -> AnyTool<ToolIdentifier> {
        self.addArrangedSubview(control)

        let heightConstraint = constraints.first(where: { $0.firstAttribute == .height && $0.relation == .equal })
        heightConstraint?.constant = CGFloat(35 * arrangedSubviews.count)
        setNeedsLayout()

        let toolBarTool = ToolBarTool(control: control, id: id, actionHandler: actionHandler, styleChangeHandler: styleChangeHandler)
        toolBarTool.anyTool = AnyTool(tool: toolBarTool)
        tools.append(toolBarTool)
        
        return toolBarTool.anyTool
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

            for tool in tools { tool.userInterfaceStyleChanged() }
        }
    }
}
