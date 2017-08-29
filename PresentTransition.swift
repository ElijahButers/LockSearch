//
//  PresentTransition.swift
//  Widgets
//
//  Created by User on 8/29/17.
//  Copyright © 2017 Underplot ltd. All rights reserved.
//

import UIKit

class PresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.75
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
  }
}
