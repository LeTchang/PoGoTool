//
//  LoginViewController.swift
//  PogoTool
//
//  Created by Tchang on 08/08/16.
//  Copyright © 2016 Tchang. All rights reserved.
//

import UIKit
import PGoApi

class LoginViewController: UIViewController, PGoAuthDelegate, PGoApiDelegate {

    @IBOutlet weak var userText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var ptcButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!

    var auth: PtcOAuth!
    var gAuth: GPSOAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = PtcOAuth()
        auth.delegate = self
        gAuth = GPSOAuth()
        gAuth.delegate = self
        self.view.backgroundColor = UIColor.grayColor()
    }
    
    // MARK: - API Response
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("API response received")
        if intent == .Login {
            if auth.loggedIn {
                auth.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            } else {
                gAuth.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            }
            performSegueWithIdentifier("loginSegue", sender: nil)
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
    
    // MARK: - AUTH Response
    func didReceiveAuth() {
        print("Auth received")
        let request = PGoApiRequest()
        request.simulateAppStart()
        if auth.loggedIn {
            request.makeRequest(.Login, auth: auth, delegate: self)
        } else {
            request.makeRequest(.Login, auth: gAuth, delegate: self)
        }
        
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    // MARK: - IBAction
    @IBAction func onPtc(sender: AnyObject) {
        guard let user = self.userText.text where self.userText.text != nil else {
            return
        }
        guard let pass = self.passText.text where self.passText.text != nil else {
            return
        }
        auth.login(withUsername: user, withPassword: pass)
    }
    
    @IBAction func onGoogle(sender: AnyObject) {
        guard let user = self.userText.text where self.userText.text != nil else {
            return
        }
        guard let pass = self.passText.text where self.passText.text != nil else {
            return
        }
        print("Trying auth via Google")
        gAuth.login(withUsername: user, withPassword: pass)
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue" {
            let new = segue.destinationViewController as! ViewController
            new.auth = self.auth
            new.gAuth = self.gAuth
        }
    }
}