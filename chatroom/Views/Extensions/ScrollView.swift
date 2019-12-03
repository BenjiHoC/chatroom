//
//  ScrollView.swift
//  chatroom
//
//  Created by Benjamin Rasmussen on 03/12/2019.
//  Copyright © 2019 Benjamin Rasmussen. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
  
  var isAtBottom: Bool {
    return contentOffset.y >= verticalOffsetForBottom
  }
  
  var verticalOffsetForBottom: CGFloat {
    let scrollViewHeight = bounds.height
    let scrollContentSizeHeight = contentSize.height
    let bottomInset = contentInset.bottom
    let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
    return scrollViewBottomOffset
  }
  
}
