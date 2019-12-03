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
import GoogleSignIn

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var FbLoginButton: FBSDKLoginButton!
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        FbLoginButton.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
         NotificationCenter.default.addObserver(self, selector: #selector(didSignIn), name: NSNotification.Name("SuccessfulSignInNotification"), object: nil)
        handleAutoLogin()
    }
    
    // MARK: - IBOutlet actions
    
    // Login button for facebook
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        
        // Login/Sign in for firebase method
        authFirebase()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    // MARK: - Methods
    
    // Redirect with google sign in
    @objc func didSignIn()  {
        redirectToChatRooms()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Check if any user is already logged in and sent to chat room viewcontroller if user is logged in
    func handleAutoLogin(){
        
        // Check if user is logged in
        if Auth.auth().currentUser != nil {
            //Auth.auth().currentUser!.uid
            AppSettings.displayName = Auth.auth().currentUser!.displayName!
            self.redirectToChatRooms()
        }
    }
    
    // Login/Sign in to firebase with facebook token
    func authFirebase(){
        
        // Retrieve access token
        let accessToken = FBSDKAccessToken.current().tokenString!
        
        // Get fb credentials with the access token
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessToken)
        Auth.auth().signIn(with: credentials) { (user, error) in
            if error != nil {
                print("Something went wrong", error)
                self.showLoginAlert()
                return
            }
            
            // Set user display name to be equal to facebook name
            AppSettings.displayName = Auth.auth().currentUser!.displayName!
            self.redirectToChatRooms()
            print("Successfully logged in...")
        }
    }
    
    // Send to chat rooms viewcontroller
    func redirectToChatRooms(){
        let chatStoryboard = UIStoryboard(name: "ChatRooms", bundle: nil)
        let chatRoomsVC = chatStoryboard.instantiateViewController(withIdentifier: "ChatRoomsStoryboard") as! ChatRoomsViewController
        chatRoomsVC.modalPresentationStyle = .fullScreen
        self.present(chatRoomsVC, animated: true)
    }
    
    // Create alert
    func showLoginAlert(){
        let alert = UIAlertController(title: "Fejl", message: "Der skete en fejl ved forsøg af login. Prøv igen", preferredStyle: .alert)
        
        // Add action for alert
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        // Add alert to view
        self.present(alert, animated: true)
    }
}

