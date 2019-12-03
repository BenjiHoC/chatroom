//
//  ChatRoom.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct ChatRoom {
    let id: String?
    let name: String
    
    init(name: String) {
        id = nil
        self.name = name
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let name = data["name"] as? String else {
          return nil
        }
        
        id = document.documentID
        self.name = name
    }
}

//MARK:  - Extenstions
extension ChatRoom: DatabaseRepresentation {
    var representation: [String : Any] {
        var rep = ["name": name]
        
        if let id = id {
            rep["id"] = id
        }
        return rep
    }
}

extension ChatRoom: Comparable {
    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.name < rhs.name
    }
}
