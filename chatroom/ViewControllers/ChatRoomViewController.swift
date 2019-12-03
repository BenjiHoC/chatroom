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
    var imagePicker = UIImagePickerController()
  
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
        
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        loadDocuments()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        messageInputBar.isHidden = false
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
  
// MARK: - Actions
    @objc private func cameraButtonPressed() {
        
        // Alert to choose between actions
        let alert = UIAlertController(title: "Upload et billed", message: nil, preferredStyle: .actionSheet)
           alert.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { _ in
               self.openCamera()
           }))

           alert.addAction(UIAlertAction(title: "Kamerarulle", style: .default, handler: { _ in
               self.openGallery()
           }))

        alert.addAction(UIAlertAction.init(title: "Afbryd", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Opens camera if you have
    func openCamera()
    {
        messageInputBar.isHidden = true
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // Opens gallery
    func openGallery()
    {
        messageInputBar.isHidden = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
// MARK: - Methods
    
    private func uploadImage(_ image: UIImage, to chatRoom: ChatRoom, completion: @escaping (URL?) -> Void) {
        guard let chatRoomID = chatRoom.id else {
            completion(nil)
            return
        }
        
        let imageName = NSUUID().uuidString
        let ref = storage.storage.reference().child(chatRoomID).child("message_photos").child(imageName)
        if let uploadData = image.jpegData(compressionQuality: 0.2){
            
            ref.putData(uploadData, metadata: nil) { (metaData, error) in
                if error != nil {
                    print("Error: ", error)
                    return
                }
                    ref.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            print("Error: ", error)

                            return
                        }
                        let imageUrl = downloadURL.absoluteString
                        print(imageUrl)
                    }
            }
        
        }
    }
    
    private func sendPhoto(_ image: UIImage) {
      
      uploadImage(image, to: chatRoom) { [weak self] url in
        guard let `self` = self else {
          return
        }
        
        guard let url = url else {
          return
        }
        
        var message = Message(user: self.user, image: image)
        message.downloadURL = url
        
        self.save(message)
        self.messagesCollectionView.scrollToBottom()
      }
    }
    
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
        
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .primary
        cameraItem.image = #imageLiteral(resourceName: "camera")

        
        cameraItem.addTarget(
          self,
          action: #selector(cameraButtonPressed),
          for: .primaryActionTriggered
        )
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)

        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

    
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
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
        guard var message = Message(document: change.document) else {
            return
      }
      
          switch change.type {
          case .added:
            if let url = message.downloadURL {
                downloadImage(at: url) { [weak self] image in
                    guard let `self` = self else {
                        return
                    }
                    guard let image = image else {
                        return
                    }
                    message.image = image
                    self.insertNewMessage(message)
                }
            }
            else {
                insertNewMessage(message)
            }
          default:
            break
        }
    }
    
    // Download image from firebase storage url
    private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
      let ref = Storage.storage().reference(forURL: url.absoluteString)
      let megaByte = Int64(1 * 1024 * 1024)
      
      ref.getData(maxSize: megaByte) { data, error in
        guard let imageData = data else {
          completion(nil)
          return
        }
        
        completion(UIImage(data: imageData))
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

// MARK: - Extenstion UIImagePickerControllerDelegate

extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
        var selectedImageFromPicker: UIImage?
        
        
        if let editedImage = info[.editedImage] as? UIImage {
            // Set image to the edited image
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            // Set image to the original image
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            // Send photo
            self.sendPhoto(selectedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
  
}
