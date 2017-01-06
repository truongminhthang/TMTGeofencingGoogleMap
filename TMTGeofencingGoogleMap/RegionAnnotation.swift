//
//  RegionAnnotation.swift
//  TMT_Geofencing
//
//  Created by Trương Thắng on 1/4/17.
//  Copyright © 2017 Trương Thắng. All rights reserved.
//

import GoogleMaps

// MARK: - <#Mark#>

extension GMSCircle {
    convenience init?(region: CLRegion) {
        guard let circleRegion = region as? CLCircularRegion else {return nil}
        let center = circleRegion.center
        let radius = circleRegion.radius
        self.init(position: center, radius: radius)
    }
}
