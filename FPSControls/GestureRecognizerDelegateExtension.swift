//
//  GestureRecognizerDelegateExtension.swift
//  FPSControls
//
//  Created by Luke Schoen on 4/12/2015.
//  Copyright © 2015 Nick Lockwood. All rights reserved.
//

import UIKit

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        if gestureRecognizer == lookGesture {
            return touch.locationInView(view).x > view.frame.size.width / 2
        } else if gestureRecognizer == walkGesture {
            return touch.locationInView(view).x < view.frame.size.width / 2
        }
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}
