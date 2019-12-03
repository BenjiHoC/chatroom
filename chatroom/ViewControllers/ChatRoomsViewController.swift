//
//  ChatRoomsViewController.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseDatabase
import FBSDKCoreKit
import FBSDKLoginKit
import Photos

class ChatRoomsViewController: UIViewController {
    
    // MARK: - IBOutlets variables/components
    
    @IBOutlet weak var ProfileNameLabel: UILabel!
    @IBOutlet weak var ChatRoomTableView: UITableView!
    
    // MARK: - Variables
    
    private let refreshControl = UIRefreshControl()
    var AllChatRooms = [String]()
    var userDisplayName: String = ""
    var db: Firestore!
    private let currentUser = Auth.auth().currentUser!
    
    // Firebase document path
    private var chatRoomReference: CollectionReference {
      return db.collection("ChatRoom")
    }
    
    private var chatRooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?
    
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        //fetchChatRooms()
        ProfileNameLabel.text = AppSettings.displayName
        
        // Spinner and reload function for tableview
        refreshControl.attributedTitle = NSAttributedString(string: "Træk for at opdater")
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        ChatRoomTableView.addSubview(refreshControl)
        
        loadDocuments()
    }
    
    //MARK: - IBOutlet actions
    
    // Sign out with firebase auth and show an alert asking if user is certain
    @IBAction func signOut(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: "Er du sikker på du vil logge ud?", preferredStyle: .alert)
          ac.addAction(UIAlertAction(title: "Nej", style: .cancel, handler: nil))
          ac.addAction(UIAlertAction(title: "Log ud", style: .destructive, handler: { _ in
          do {
            try Auth.auth().signOut()
            self.dismiss(animated: true)
          } catch {
            print("Error signing out: \(error.localizedDescription)")
          }
        }))
        present(ac, animated: true, completion: nil)
    }
    
    //MARK: - Methods
    
    @objc func refresh(sender:AnyObject) {
       // Code to refresh table view
        self.loadDocuments()
    }
    
    // Load documents from firebase
    func loadDocuments(){
        chatRoomListener = chatRoomReference.addSnapshotListener { querySnapshot, error in
          guard let snapshot = querySnapshot else {
            print("Error listening for chat room updates: \(error?.localizedDescription ?? "No error")")
            return
          }
          
          snapshot.documentChanges.forEach { change in
            self.handleDocumentChange(change)
          }
        }
        DispatchQueue.main.async {
            self.ChatRoomTableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let chatRoom = ChatRoom(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            addChatRoomToTable(chatRoom)
        default:
            break
        }
    }
    
    // Add to array 
    private func addChatRoomToTable(_ chatRoom: ChatRoom) {
        guard !chatRooms.contains(chatRoom) else {
            return
        }
        chatRooms.append(chatRoom)
        chatRooms.sort()
        
        guard let index = chatRooms.index(of: chatRoom) else {
            return
        }
        ChatRoomTableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}

// MARK: - Extenstions
extension ChatRoomsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Custom cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomsViewCell") as! ChatRoomsTableViewCell
        let chatRoomName = self.chatRooms[indexPath.row]
        
        // Enables the chevron
        cell.accessoryType = .disclosureIndicator
        
        cell.ChatRoomNameLabel.text = chatRoomName.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatRoom = chatRooms[indexPath.row]
        
        let vc = ChatRoomViewController(user: currentUser, chatRoom: chatRoom)
        //vc.modalPresentationStyle = .fullScreen
        ChatRoomTableView.deselectRow(at: indexPath, animated: true)
        self.present(vc, animated: true)
    }
} 
