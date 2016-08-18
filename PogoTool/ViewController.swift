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

    @IBOutlet weak var pkmnTableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!

    var auth: PtcOAuth!
    var gAuth: GPSOAuth!
    var pokemons = [Pokemon]()
    var locked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "pokemonCell", bundle: nil)
        self.view.backgroundColor = UIColor.grayColor()
        self.navigationItem.hidesBackButton = true
        self.pkmnTableView.registerNib(cellNib, forCellReuseIdentifier: "pokemonCell")
        self.pkmnTableView.backgroundColor = UIColor.clearColor()
        self.pkmnTableView.allowsSelection = false
        
        let request = PGoApiRequest()
        request.getInventory()
        if auth.loggedIn {
            request.makeRequest(.GetInventory, auth: auth, delegate: self)
        } else {
            request.makeRequest(.GetInventory, auth: gAuth, delegate: self)
        }
    }
    
    func sortByIv() {
        var superArray = [[Pokemon]]()
        var tmp = [Pokemon]()
        var prev = self.pokemons[0].num
        
        for x in 0 ..< self.pokemons.count {
            if self.pokemons[x].num != prev {
                superArray.append(tmp)
                tmp.removeAll()
                prev = self.pokemons[x].num
            }
            tmp.append(self.pokemons[x])
            if x == self.pokemons.count - 1 {
                superArray.append(tmp)
            }
        }
        self.pokemons.removeAll()
        for i in 0 ..< superArray.count {
            superArray[i].sortInPlace( { $0.perf > $1.perf } )
            for y in 0 ..< superArray[i].count {
                self.pokemons.append(superArray[i][y])
            }
        }
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        switch intent {
        case .GetInventory:
            print(" ----- Got Inventory ----- with \(response.subresponses.count) subresponse(s)")
            guard response.subresponses.count > 0 else {
                print("Error: no subresponses, should reload inventory\n")
                self.refreshButton.enabled = true
                return
            }
            let r = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse
            let item = r.inventoryDelta
            guard item != nil else {
                print("Error: empty inventory, should reload inventory\n")
                self.refreshButton.enabled = true
                return
            }
            for x in 0 ..< item.inventoryItems.count {
                if item.inventoryItems[x].inventoryItemData.hasPokemonData == true {
                    if item.inventoryItems[x].inventoryItemData.pokemonData.hasIsEgg == false {
                        
                        let cp = item.inventoryItems[x].inventoryItemData.pokemonData.cp
                        let att = item.inventoryItems[x].inventoryItemData.pokemonData.individualAttack
                        let def = item.inventoryItems[x].inventoryItemData.pokemonData.individualDefense
                        let sta = item.inventoryItems[x].inventoryItemData.pokemonData.individualStamina
                        let perf = String(format: "%.2f", Float(att + def + sta) / 45.0 * 100.0)
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
            self.pokemons.sortInPlace({ Int($0.num) < Int($1.num) })
            sortByIv()
            self.locked = false
            self.refreshButton.enabled = true
            self.pkmnTableView.reloadData()
            print("Total pokemon: \(pokemons.count)\n")
        
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
        print("Refreshing inventory...")
        pokemons.removeAll()
        let request = PGoApiRequest()
        request.getInventory()
        if auth.loggedIn {
            request.makeRequest(.GetInventory, auth: auth, delegate: self)
        } else {
            request.makeRequest(.GetInventory, auth: gAuth, delegate: self)
        }
    }
    
    // MARK: - TableView Functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pokemons.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell") as! pokemonCell
        let i = indexPath.row
        if i > pokemons.count {
            print("Error: Index out of range")
            return cell
        }
        
        cell.nameText.text = pokemons[i].pkmn
        cell.statText.text = pokemons[i].cp + "cp - " + pokemons[i].perf + "%"
        
        cell.transferButton.tag = i
        cell.transferButton.addTarget(self, action: #selector(ViewController.onTransfer(_:)), forControlEvents: .TouchUpInside)
        cell.evolveButton.tag = i
        cell.evolveButton.addTarget(self, action: #selector(ViewController.onEvolve(_:)), forControlEvents: .TouchUpInside)
        
        if self.locked {
            cell.transferButton.enabled = false
            cell.evolveButton.enabled = false
        } else {
            cell.transferButton.enabled = true
            cell.evolveButton.enabled = true
        }
        
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
        self.refreshButton.enabled = false
        refreshInventory()
    }
    
    func onTransfer(sender: UIButton) {
        self.locked = true
        self.refreshButton.enabled = false
        self.pkmnTableView.reloadData()
        
        let i = sender.tag
        print("\(pokemons[i].pkmn) (\(pokemons[i].id)) clicked - TRANSFER")
        
        let pkmnId = self.pokemons[i].id
        let request = PGoApiRequest()
        request.releasePokemon(pkmnId)
        if auth.loggedIn {
            request.makeRequest(.ReleasePokemon, auth: auth, delegate: self)
        } else {
            request.makeRequest(.ReleasePokemon, auth: gAuth, delegate: self)
        }
    }

    func onEvolve(sender: UIButton) {
        self.locked = true
        self.refreshButton.enabled = false
        self.pkmnTableView.reloadData()
        
        let i = sender.tag
        print("\(pokemons[i].pkmn) (\(pokemons[i].id)) clicked - EVOLVE")
        let pkmnId = self.pokemons[i].id
        
        let request = PGoApiRequest()
        request.evolvePokemon(pkmnId)
        if auth.loggedIn {
            request.makeRequest(.EvolvePokemon, auth: auth, delegate: self)
        } else {
            request.makeRequest(.EvolvePokemon, auth: gAuth, delegate: self)
        }
    }
    
    func enableAll() {
        let sections = self.pkmnTableView.numberOfSections
        for section in 0 ..< sections {
            let rows = self.pkmnTableView.numberOfRowsInSection(section)
            for row in 0 ..< rows {
                let i = NSIndexPath(forRow: row, inSection: section)
                let cell = self.pkmnTableView.dequeueReusableCellWithIdentifier("pokemonCell", forIndexPath: i) as! pokemonCell
                cell.transferButton.enabled = false
            }
        }
    }
}