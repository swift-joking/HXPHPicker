//
//  PickerControllerInteractiveTransition.swift
//  HXPHPicker
//
//  Created by Slience on 2022/5/23.
//

import UIKit

class PickerControllerInteractiveTransition: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    enum TransitionType {
        case pop
        case dismiss
    }
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerAction(panGR:))
        )
        return panGestureRecognizer
    }()
    var pickerControllerBackgroundColor: UIColor?
    var beganPoint: CGPoint = .zero
    var canInteration: Bool = false
    let triggerRange: CGFloat
    weak var transitionContext: UIViewControllerContextTransitioning?
    weak var pickerController: PhotoPickerController?
    let type: TransitionType
    init(
        panGestureRecognizerFor pickerController: PhotoPickerController,
        type: TransitionType,
        triggerRange: CGFloat
    ) {
        self.pickerController = pickerController
        self.type = type
        self.triggerRange = triggerRange
        super.init()
        panGestureRecognizer.delegate = self
        pickerController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        let pickerController = transitionContext.viewController(forKey: .from) as! PhotoPickerController
        let toVC = transitionContext.viewController(forKey: .to)!
        pickerControllerBackgroundColor = pickerController.view.backgroundColor
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(pickerController.view)
        if type == .pop {
            toVC.view.x = -(toVC.view.width * 0.3)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pickerController = pickerController,
              let topViewController = pickerController.topViewController,
              topViewController is PhotoPickerViewController else {
            return false
        }
        let point = gestureRecognizer.location(in: pickerController.view)
        if point.x > triggerRange {
            return false
        }
        return true
    }
    
    @objc
    func panGestureRecognizerAction(panGR: UIPanGestureRecognizer) {
        guard let pickerController = pickerController else {
            return
        }
        switch panGR.state {
        case .began:
            if canInteration {
                return
            }
            beganPoint = pickerController.view.frame.origin
            canInteration = true
            pickerController.dismiss(animated: true)
        case .changed:
            if !canInteration {
                return
            }
            let point = panGR.translation(in: pickerController.view)
            var scale = (point.x / pickerController.view.width)
            if scale < 0 {
                scale = 0
            }
            if type == .pop {
                if let transitionContext = transitionContext,
                   let toVC = transitionContext.viewController(forKey: .to) {
                    let toScale = toVC.view.width * 0.3 * scale
                    toVC.view.x = -(toVC.view.width * 0.3) + toScale
                }
                pickerController.view.x = pickerController.view.width * scale
            }else {
                pickerController.view.y = beganPoint.y + scale * pickerController.view.height
                if pickerController.view.y < 0 {
                    pickerController.view.y = 0
                }
            }
            update(scale)
        case .ended, .cancelled, .failed:
            if !canInteration {
                return
            }
            let isFinish: Bool
            if type == .pop {
                isFinish = pickerController.view.x > pickerController.view.width * 0.3
            }else {
                isFinish = pickerController.view.y > pickerController.view.height * 0.4
            }
            if isFinish {
                finish()
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: .curveLinear
                ) {
                    if self.type == .pop {
                        if let transitionContext = self.transitionContext,
                           let toVC = transitionContext.viewController(forKey: .to) {
                            toVC.view.x = 0
                        }
                        pickerController.view.x = pickerController.view.width
                    }else {
                        pickerController.view.y = pickerController.view.height
                    }
                } completion: { _ in
                    self.pickerController?.view.removeFromSuperview()
                    self.pickerController = nil
                    self.canInteration = false
                    self.transitionContext?.completeTransition(true)
                    self.transitionContext = nil
                }
            }else {
                cancel()
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: .curveLinear
                ) {
                    if self.type == .pop {
                        if let transitionContext = self.transitionContext,
                           let toVC = transitionContext.viewController(forKey: .to) {
                            toVC.view.x = -(toVC.view.width * 0.3)
                        }
                        pickerController.view.x = 0
                    }else {
                        pickerController.view.y = 0
                    }
                } completion: { _ in
                    self.canInteration = false
                    self.transitionContext?.completeTransition(false)
                    self.transitionContext = nil
                }
            }
        default:
            break
        }
    }
}
