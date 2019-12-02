//
//  ViewController.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var FbLoginButton: FBSDKLoginButton!
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        authFirebase()
        print("Logged in successfully...")
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
    }
    
    func authFirebase(){
        let accessToken = FBSDKAccessToken.current().tokenString!
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credentials) { (user, error) in
            if error != nil {
                print("Something went wrong", error)
                return
            }
            print("Successfully logged in...")
        }
    }
    
    func setupViews(){
        FbLoginButton.delegate = self
        FbLoginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

