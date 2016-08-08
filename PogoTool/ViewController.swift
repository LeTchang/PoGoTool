//
//  ViewController.swift
//  PogoTool
//
//  Created by Tchang on 03/08/16.
//  Copyright © 2016 Tchang. All rights reserved.
//

import UIKit
import PGoApi
import Alamofire
import AlamofireImage

class ViewController: UIViewController, PGoAuthDelegate, PGoApiDelegate, UITableViewDataSource {

    var auth: PtcOAuth!
    var pokemons = [Pokemon]()
    @IBOutlet weak var pkmnTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = UINib(nibName: "pokemonCell", bundle: nil)
        self.pkmnTableView.registerNib(cellNib, forCellReuseIdentifier: "pokemonCell")
        self.view.backgroundColor = UIColor.grayColor()
        self.pkmnTableView.backgroundColor = UIColor.clearColor()
        self.pkmnTableView.allowsSelection = false
        
        auth = PtcOAuth()
        auth.delegate = self
        
        // MARK: - Add id and password
        auth.login(withUsername: "", withPassword: "")
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")
        let request = PGoApiRequest()
        request.simulateAppStart()
        request.makeRequest(.Login, auth: auth, delegate: self)
    }
    
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
            print(" ----- Got Inventory -----")
            let r = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse
            let item = r.inventoryDelta
            for x in 0 ..< item.inventoryItems.count {
                if item.inventoryItems[x].inventoryItemData.hasPokemonData == true {
                    if item.inventoryItems[x].inventoryItemData.pokemonData.hasIsEgg == false {
                        
                        let cp = item.inventoryItems[x].inventoryItemData.pokemonData.cp
                        let att = item.inventoryItems[x].inventoryItemData.pokemonData.individualAttack
                        let def = item.inventoryItems[x].inventoryItemData.pokemonData.individualDefense
                        let sta = item.inventoryItems[x].inventoryItemData.pokemonData.individualStamina
                        let perf = String(format: "%.2f", Float(att + def + sta) / 45.0 * 100.0) + "%"
                        var pkmn = item.inventoryItems[x].inventoryItemData.pokemonData.pokemonId.description
                        pkmn.removeAtIndex(pkmn.startIndex)
                        let num = String(format: "%03d", item.inventoryItems[x].inventoryItemData.pokemonData.pokemonId.rawValue)
                        let url = "http://serebii.net/pokemongo/pokemon/" + num + ".png"
                        
                        let param = [String(cp), String(att), String(def), String(sta), perf, pkmn, num, url]
                        let id = item.inventoryItems[x].inventoryItemData.pokemonData.id
                        let new = Pokemon(values: param, id: id)
                        self.pokemons.append(new)
                    }
                }
            }
            print("Total pokemon:", pokemons.count)
            self.pokemons.sortInPlace { $0.num < $1.num }
            self.pkmnTableView.reloadData()
        
        case .ReleasePokemon:
            print(" ----- Got Release -----")
            refreshInventory()
            
        case .EvolvePokemon:
            print(" ----- Got Evolve -----")
            refreshInventory()
            
        default:
            break
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
    
    func refreshInventory() {
        pokemons.removeAll()
        let request = PGoApiRequest()
        request.getInventory()
        request.makeRequest(.GetInventory, auth: auth, delegate: self)
    }
    
    // MARK: - TableView Functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pokemons.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell") as! pokemonCell
        let i = indexPath.row
        
        cell.nameText.text = pokemons[i].pkmn
        cell.statText.text = pokemons[i].cp + "cp - " + pokemons[i].perf
        
        cell.transferButton.tag = i
        cell.transferButton.addTarget(self, action: #selector(ViewController.onTransfer(_:)), forControlEvents: .TouchUpInside)
        cell.evolveButton.tag = i
        cell.evolveButton.addTarget(self, action: #selector(ViewController.onEvolve(_:)), forControlEvents: .TouchUpInside)
        
        Alamofire.request(.GET, pokemons[i].urlImg).responseImage {
            response in
            if let image = response.result.value {
                cell.pokemonImage.image = image
            } else {
                cell.pokemonImage.image = nil
            }
        }
        
        return cell
    }
    
    // MARK: - Handle Buttons
    @IBAction func onRefresh(sender: AnyObject) {
        print("Refreshing inventory...")
        refreshInventory()
    }
    
    func onTransfer(sender: UIButton) {
        let i = sender.tag
        let pkmnId = self.pokemons[i].id
        print(pokemons[i].pkmn, "clicked - TRANSFER")
        
        let request = PGoApiRequest()
        request.releasePokemon(pkmnId)
        request.makeRequest(.ReleasePokemon, auth: auth, delegate: self)
    }

    func onEvolve(sender: UIButton) {
        let i = sender.tag
        let pkmnId = self.pokemons[i].id
        print(pokemons[i].pkmn, "clicked - EVOLVE")
        
        let request = PGoApiRequest()
        request.evolvePokemon(pkmnId)
        request.makeRequest(.EvolvePokemon, auth: auth, delegate: self)
    }
}