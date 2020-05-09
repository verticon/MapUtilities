//
//  SplitView.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 5/5/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit
import VerticonsToolbox

class SplitView: UIView {

    let upper: UIView
    let splitter: Splitter
    let lower: UIView

    private var currentConstraints: [NSLayoutConstraint]?
    private lazy var potraitConstraints = [
       upper.leftAnchor.constraint(equalTo: self.leftAnchor),
       upper.rightAnchor.constraint(equalTo: self.rightAnchor),
       upper.topAnchor.constraint(equalTo: self.topAnchor),
       upper.bottomAnchor.constraint(equalTo: splitter.topAnchor),

       splitter.leftAnchor.constraint(equalTo: self.leftAnchor),
       splitter.rightAnchor.constraint(equalTo: self.rightAnchor),
       splitter.centerYAnchor.constraint(equalTo: self.centerYAnchor),
       splitter.heightAnchor.constraint(equalToConstant: Splitter.thickness),

       lower.leftAnchor.constraint(equalTo: self.leftAnchor),
       lower.rightAnchor.constraint(equalTo: self.rightAnchor),
       lower.bottomAnchor.constraint(equalTo: self.bottomAnchor),
       lower.topAnchor.constraint(equalTo: splitter.bottomAnchor),
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

    private var splitterObserver: NSKeyValueObservation? = nil

    init(upper: UIView, lower: UIView) {
        self.upper = upper
        splitter = Splitter()
        self.lower = lower

        super.init(frame: .zero)

        splitterObserver = splitter.observe(\.offset, options: [.new]) { [weak self] splitter, change in self?.setNeedsLayout() }

        upper.translatesAutoresizingMaskIntoConstraints = false
        addSubview(upper)

        splitter.translatesAutoresizingMaskIntoConstraints = false
        addSubview(splitter)

        lower.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lower)
    }
    
    required init?(coder: NSCoder) { fatalError("SplitView - init(coder:) has not been implemented") }

    override func layoutSubviews() {

        if let current = currentConstraints { NSLayoutConstraint.deactivate(current) }

        let orientation = getOrientation()

        switch orientation {
        case .portrait: currentConstraints =  potraitConstraints
        case .landscapeRight: currentConstraints =  landscapeRightConstraints
        case .landscapeLeft: currentConstraints =  landscapeLeftConstraints
        default: fatalError("This shouldn't happen")
        }

        // The magnitude of the splitter's offset remains the same in portrait or in landscape; the splitter is always
        // moving through the device's longer dimension (y in portrait, x in landscape). The sign (+/-) might, however,
        // change when the orientation changes.

        let result = currentConstraints!.filter{ $0.firstItem === self.splitter && ($0.firstAttribute == .centerY || $0.firstAttribute == .centerX) }
        guard result.count == 1 else { fatalError("Cannot find splitter's center constraint???") }
        result[0].constant = splitter.offset

        NSLayoutConstraint.activate(currentConstraints!)

        super.layoutSubviews()

        print("SplitView.layoutSubviews")
    }
}
