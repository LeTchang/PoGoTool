//
//  Pokemon.swift
//  PogoTool
//
//  Created by Tchang on 03/08/16.
//  Copyright © 2016 Tchang. All rights reserved.
//

import UIKit

class Pokemon: NSObject {

    let id: UInt64
    
    let cp: String
    let att: String
    let def: String
    let sta: String
    let perf: String
    
    let pkmn: String
    let num: String
    let urlImg: String
    
    init(values: [String], id: UInt64) {
        self.cp = values[0]
        self.att = values[1]
        self.def = values[2]
        self.sta = values[3]
        self.perf = values[4]
        self.pkmn = values[5]
        self.num = values[6]
        self.urlImg = values[7]
        self.id = id
    }
    
    func displayPkmn() {
        print("Pokemon: ", self.pkmn, " #", self.num, separator: "")
        print("CP:", self.cp, "|", self.perf)
        print("Url:", self.urlImg)
        print("ID:", self.id, terminator: "\n\n")
    }
}
