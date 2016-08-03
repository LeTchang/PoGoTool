//
//  ViewController.swift
//  PogoTool
//
//  Created by Tchang on 03/08/16.
//  Copyright © 2016 Tchang. All rights reserved.
//

import UIKit
import PGoApi

class ViewController: UIViewController, PGoAuthDelegate, PGoApiDelegate {

    var auth: PtcOAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = PtcOAuth()
        auth.delegate = self
        auth.login(withUsername: "", withPassword: "")
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")
        let request = PGoApiRequest()
        request.simulateAppStart()
        request.makeRequest(.Login, auth: auth, delegate: self)    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("Got that API response: \(intent)")
        switch intent {
        case .Login:
            auth.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(auth.endpoint)")
            let request = PGoApiRequest()
            request.getInventory()
            request.makeRequest(.GetInventory, auth: auth, delegate: self)
        case .GetInventory:
            print("Got Inventory !")
            let r = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse
            let item = r.inventoryDelta
            for x in 0 ..< item.inventoryItems.count {
                if item.inventoryItems[x].inventoryItemData.hasPokemonData == true {
                    if item.inventoryItems[x].inventoryItemData.pokemonData.hasIsEgg == false {
                        let id = item.inventoryItems[x].inventoryItemData.pokemonData.id
                        var pkmn = item.inventoryItems[x].inventoryItemData.pokemonData.pokemonId.description
                        pkmn.removeAtIndex(pkmn.startIndex)
                        let num = String(format: "%03d", item.inventoryItems[x].inventoryItemData.pokemonData.pokemonId.rawValue)
                        let atq = item.inventoryItems[x].inventoryItemData.pokemonData.individualAttack
                        let def = item.inventoryItems[x].inventoryItemData.pokemonData.individualDefense
                        let sta = item.inventoryItems[x].inventoryItemData.pokemonData.individualStamina
                        let perf = String(format: "%.2f", Float(atq + def + sta) / 45.0 * 100.0) + "%"
                        print("ID:", id, "| Num:", num)
                        print(pkmn, " | ", atq, "/", def, "/", sta, " | perfect: ", perf, separator: "", terminator: "\n\n")
                    }
                }
            }
        default:
            break
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
}

