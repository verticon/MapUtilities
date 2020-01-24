//
//  Utilities.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 1/23/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit

func getOrientation() -> UIDeviceOrientation {
    var orientation = UIDevice.current.orientation

    switch orientation {
    case .portrait: break
    case .landscapeLeft: break
    case .landscapeRight: break
    default:
        let window = UIApplication.shared.keyWindow!
        orientation = window.bounds.width < window.bounds.height ? .portrait : .landscapeLeft
    }

    return orientation
}
