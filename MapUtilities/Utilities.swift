//
//  Utilities.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 1/23/20.
//  Copyright © 2020 Robert Vaessen. All rights reserved.
//

import UIKit

let mainWindow = UIApplication.shared.windows.first { $0.isKeyWindow }!

func getOrientation() -> UIDeviceOrientation {
    var orientation = UIDevice.current.orientation

    switch orientation {
    case .portrait: break
    case .landscapeLeft: break
    case .landscapeRight: break
    default:
        orientation = mainWindow.bounds.width < mainWindow.bounds.height ? .portrait : .landscapeLeft
    }

    return orientation
}
