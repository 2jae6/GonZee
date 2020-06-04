//
//  TMConvertDTO.swift
//  GonZee
//
//  Created by 1 on 2020/06/02.
//  Copyright © 2020 wook. All rights reserved.
//

import UIKit
import ObjectMapper

class TMConvertDTO: Mappable {
           
    var documents : [Documents]?
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        documents <- map["documents"]
        
    }
    
    class Documents: Mappable {
        var x: Double?
        var y: Double?
        required init?(map: Map) {
            
        }
        
        func mapping(map: Map) {
            x <- map["x"]
            y <- map["y"]
        }
        
        
    }
        
    
}
