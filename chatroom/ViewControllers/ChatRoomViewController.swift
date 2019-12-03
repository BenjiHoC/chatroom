//
//  ChatRoomViewController.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import UIKit
import Photos
import Firebase
import MessageKit
import FirebaseFirestore
import InputBarAccessoryView

final class ChatRoomViewController: MessagesViewController {
  
//MARK: - Variables
    private let db = Firestore.firestore()
    private var reference: CollectionReference?
    private let storage = Storage.storage().reference()

    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
  
    private let user: User
    private let chatRoom: ChatRoom
  
    deinit {
        messageListener?.remove()
    }

    // Initialize the VC with User and Chat room from the selected viewcell from previous vc
    init(user: User, chatRoom: ChatRoom) {
        self.user = user
        self.chatRoom = chatRoom
        super.init(nibName: nil, bundle: nil)
    }
  
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
//MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDocuments()
        setupUI()
    }
  
// MARK: - Actions
    
// MARK: - Methods
  
    // Load the documents
    func loadDocuments(){
        guard let id = chatRoom.id else {
            self.dismiss(animated: true)
          return
        }

        reference = db.collection(["ChatRoom", id, "thread"].joined(separator: "/"))
        
        messageListener = reference?.addSnapshotListener { querySnapshot, error in
          guard let snapshot = querySnapshot else {
            print("Error listening for chat room updates: \(error?.localizedDescription ?? "No error")")
            return
          }
          
          snapshot.documentChanges.forEach { change in
            print(change.document.documentID)
            self.handleDocumentChange(change)
          }
        }
    }
    
    //Setup UI stuff and delegates for the messageControls
    func setupUI(){
        navigationItem.largeTitleDisplayMode = .never
        
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .primary
        messageInputBar.inputTextView.textColor = .primary
        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
    }
    
    // Save the message to Firestore
    private func save(_ message: Message) {
        reference?.addDocument(data: message.representation) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                self.showErrorAlert()
                return
            }
            // Scroll to the bottom
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    // Create alert
    func showErrorAlert(){
        let alert = UIAlertController(title: "Fejl", message: "Der skete en fejl ved.", preferredStyle: .alert)
        
        // Add action for alert
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        // Add alert to view
        self.present(alert, animated: true)
    }
  
    // Add message to messages array and reload the messagesCollectionView
    private func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else {
            return
        }
    
        messages.append(message)
        messages.sort()
        
        // Check if the message is the latest
        let isLatestMessage = messages.index(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
  
    // Observe new databaes changes and handle changes
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let message = Message(document: change.document) else {
            return
        }
        
        switch change.type {
            case .added:
                insertNewMessage(message)
        default:
            break
        }
    }
}

// MARK: - EXTENSIONS

// MARK: - Extenstion MessagesDisplayDelegate

extension ChatRoomViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? .blue : .green
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(corner, .curved)
  }
  
}

// MARK: - Extenstion MessagesLayoutDelegate

extension ChatRoomViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .zero
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 0, height: 8)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    return 0
  }
  
}

// MARK: - Extenstion MessagesDataSource

extension ChatRoomViewController: MessagesDataSource {
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
  
    func currentSender() -> SenderType {
        return Sender(id: user.uid, displayName: AppSettings.displayName)
    }
      
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
      
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
      
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
}

// MARK: - Extenstion MessageInputBarDelegate

extension ChatRoomViewController: MessageInputBarDelegate {
  
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(user: user, content: text)
        save(message)
        
        // Reset the textfield
        inputBar.inputTextView.text = ""
    }
}

// MARK: - TODO : - Extenstion UIImagePickerControllerDelegate
