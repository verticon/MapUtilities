//
//  Extensions.swift
//  MapUtilities
//
//  Created by Robert Vaessen on 11/23/19.
//  Copyright © 2019 Robert Vaessen. All rights reserved.
//

import Foundation
import UIKit

extension UIUserInterfaceStyle : CustomStringConvertible {
    public var description: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        case .unspecified:
            return "Unspecified"
        @unknown default:
            fatalError("A new case has been added to UIUserInterfaceStyle")
        }
    }
}

extension UIDeviceOrientation : CustomStringConvertible {
    public var description: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscapeLeft: return "LandscapeLeft"
        case .landscapeRight: return "LandscapeRight"
        case .faceUp: return "FaceUp"
        case .faceDown: return "FaceDown"
        case .portraitUpsideDown: return "PortraitUpsideDown"
        case .unknown: return "Unknown"
        @unknown default: fatalError("A new case has been added to UIDeviceOrientation")
        }
    }
}
