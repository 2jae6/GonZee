//
//  TMPData.swift
//  GonZee
//
//  Created by 1 on 2020/06/08.
//  Copyright © 2020 wook. All rights reserved.
//

import UIKit
import ObjectMapper


class TMPData: Mappable {
    
    var main: Main?
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        main <- map["main"]
    }
    
    class Main: Mappable {
        var temp: Double?
        required init?(map: Map) {
            
        }
        
        func mapping(map: Map) {
            temp <- map["temp"]
        }
        
        
    }

}
