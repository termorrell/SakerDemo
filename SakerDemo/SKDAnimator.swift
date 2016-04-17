//
//  SKDAnimator.swift
//  SakerDemo
//
//  Created by Thomas Morrell on 17/04/2016.
//  Copyright © 2016 thomasmorrell. All rights reserved.
//

import UIKit

class SKDAnimator: NSObject {

}

extension SKDAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(context: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
    
    func animateTransition(context: UIViewControllerContextTransitioning) {
        
        let container = context.containerView()!
        let fromView = context.viewForKey(UITransitionContextFromViewKey)!
        let toView = context.viewForKey(UITransitionContextToViewKey)!
        
        fromView.alpha = 1.0
        toView.alpha = 0.0
        container.addSubview(fromView)
        container.addSubview(toView)
        
        // Determine the duration of the animation
        let duration = self.transitionDuration(context)
        
        UIView.animateWithDuration(duration, animations: {
            
            toView.alpha = 1.0
            }, completion: { finished in
                context.completeTransition(!context.transitionWasCancelled())
        })
    }
}