//
//  DatabaseRepresentation.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 02/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//
import Foundation

protocol DatabaseRepresentation {
  var representation: [String: Any] { get }
}
