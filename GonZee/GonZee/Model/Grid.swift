//
//  Grid.swift
//  GonZee
//
//  Created by 1 on 2020/06/06.
//  Copyright © 2020 wook. All rights reserved.
//

import Foundation

struct mapGrid {
    
    let re = 6371.00877    // 사용할 지구반경  [ km ]
    let grid = 5.0         // 사용할 지구반경  [ km ]
    let slat1 = 30.0       // 표준위도       [degree]
    let slat2 = 60.0       // 표준위도       [degree]
    let olon = 126.0       // 기준점의 경도   [degree]
    let olat = 38.0        // 기준점의 위도   [degree]
    let xo = 42.0          // 기준점의 X좌표  [격자거리] // 210.0 / grid
    let yo = 135.0         // 기준점의 Y좌표  [격자거리] // 675.0 / grid
}
class LambertProjection {
    
    let map = mapGrid()
    
    let PI = Double.pi
    let DEGRAD = Double.pi / 180.0
    let RADDEG = 180.0 / Double.pi
    
    var re, slat1, slat2, olon, olat : Double
    var sn, sf, ro : Double
    
    init() {
        
        re = map.re / map.grid
        slat1 = map.slat1 * DEGRAD
        slat2 = map.slat2 * DEGRAD
        olon = map.olon * DEGRAD
        olat = map.olat * DEGRAD
        
        sn = tan(PI * 0.25 + slat2 * 0.5) / tan(PI * 0.25 + slat1 * 0.5)
        sn = log(cos(slat1) / cos(slat2)) / log(sn)
        sf = tan(PI * 0.25 + slat1 * 0.5)
        sf = pow(sf, sn) * cos(slat1) / sn
        ro = tan(PI * 0.25 + olat * 0.5)
        ro = re * sf / pow(ro, sn)
    }
    
    func convertDegree(x: Int, y: Int) -> (Double, Double) {
        
        let x = Double(x) - 1.0
        let y = Double(y) - 1.0
        
        let xn = x - map.xo
        let yn = ro - y + map.yo
        var ra = sqrt(xn * xn + yn * yn)
        
        if sn < 0.0 {
            ra = -ra
        }
        
        var alat = pow(re * sf / ra, 1.0 / sn)
        alat = 2.0 * atan(alat) - PI * 0.5
        
        var theta = 0.0
        
        if fabs(xn) <= 0.0 {
            theta = 0.0
        } else {
            if fabs(yn) <= 0.0 {
                theta = PI * 0.5
                if xn < 0.0 {
                    theta = -theta
                }
            } else {
                theta = atan2(xn, yn)
            }
        }
        
        let alon = theta / sn + olon
        let lat = alat * RADDEG
        let lon = alon * RADDEG
        
        return (lon, lat)
    }
    
    func convertGrid(lon: Double, lat: Double) -> (Int, Int) {
        
        var ra = tan(PI * 0.25 + lat * DEGRAD * 0.5)
        ra = re * sf / pow(ra, sn)
        var theta = lon * DEGRAD - olon
        
        if theta > PI {
            theta -= 2.0 * PI
        }
        
        if theta < -PI {
            theta += 2.0 * PI
        }
        
        theta *= sn
        
        let x = ra * sin(theta) + map.xo
        let y = ro - ra * cos(theta) + map.yo
        
        return (Int(x + 1.5), Int(y + 1.5))
    }
    
    
}
