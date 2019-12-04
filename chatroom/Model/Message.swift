//
//  Message.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import Firebase
import MessageKit
import FirebaseFirestore

// Can't use UIImage so have to make a custom struct of MediaItem from MessageKit
struct ImageMediaItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}

struct Message: MessageType {
    
    //var sender: SenderType
    let id: String?
    let content: String
    let sentDate: Date
    let sender: SenderType
  
    var kind: MessageKind {
        if let image = image {
            return .photo(image)
        } else {
            return .text(content)
        }
    }
    
  
      var messageId: String {
        return id ?? UUID().uuidString
      }
      
      var image: ImageMediaItem? = nil
      var downloadURL: URL? = nil
      
      init(user: User, content: String) {
        sender = Sender(id: user.uid, displayName: AppSettings.displayName)
        self.content = content
        sentDate = Date()
        id = nil
      }
      
      init(user: User, image: UIImage) {
        sender = Sender(id: user.uid, displayName: AppSettings.displayName)
        self.image?.image = image
        content = ""
        sentDate = Date()
        id = nil
      }
      
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
    
        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderName = data["senderName"] as? String else {
            return nil
        }
        
        //let date = data["created"] as? Date
        guard let sentDateTimestamp = document.get("created") as? Timestamp else {
            return nil
        }
        
        let date: Date = sentDateTimestamp.dateValue()
        let sentDate = date
        
        id = document.documentID
        
        self.sentDate = sentDate
        sender = Sender(id: senderID, displayName: senderName)
        
        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
        } else {
            return nil
        }
    }
}

extension Message: DatabaseRepresentation {
  
    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate,
            "senderID": sender.senderId,
            "senderName": sender.displayName
        ]
    
        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }
        return rep
    }
}

extension Message: Comparable {
  
  static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Message, rhs: Message) -> Bool {
    return lhs.sentDate < rhs.sentDate
  }
  
}
