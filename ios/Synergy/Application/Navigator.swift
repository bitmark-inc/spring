//
//  Navigator.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Hero
import SafariServices
import ESTabBarController_swift

protocol Navigatable {
    var navigator: Navigator! { get set }
}

class Navigator {
    static var `default` = Navigator()

    private lazy var rootViewController: NavigationController = {
        let viewController = NavigationController()
        viewController.hero.isEnabled = true
        viewController.isNavigationBarHidden = true
        return viewController
    }()

    // MARK: - segues list, all app scenes
    enum Scene {
        case launching(viewModel: LaunchingViewModel)
        case signInWall(viewModel: SignInWallViewModel)
        case howItWorks(viewModel: HowItWorksViewModel)
        case getYourData(viewModel: GetYourDataViewModel)
        case safari(URL)
        case safariController(URL)
        case hometabs
    }

    enum Transition {
        case root(in: UIWindow)
        case navigation(type: HeroDefaultAnimationType)
        case customModal(type: HeroDefaultAnimationType)
        case replace(type: HeroDefaultAnimationType)
        case modal
        case detail
        case alert
        case custom
    }

    // MARK: - get a single VC
    func get(segue: Scene) -> UIViewController? {
        switch segue {
        case .launching(let viewModel): return LaunchingViewController(viewModel: viewModel)
        case .signInWall(let viewModel): return SignInWallViewController(viewModel: viewModel)
        case .howItWorks(let viewModel): return HowItWorksViewController(viewModel: viewModel)
        case .getYourData(let viewModel): return GetYourDataViewController(viewModel: viewModel)
        case .safari(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil

        case .safariController(let url):
            let vc = SFSafariViewController(url: url)
            return vc

        case .hometabs:
            if let h = self.rootViewController.viewControllers.first as? ESTabBarController {
                return h
            } else {
                return HomeTabbarController.tabbarController()
            }
        }
    }

    func pop(toRoot: Bool = false) {
        if toRoot {
            rootViewController.popToRootViewController(animated: true)
        } else {
            rootViewController.popViewController()
        }
    }

    func dismiss(sender: UIViewController?) {
        sender?.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - invoke a single segue
    func show(segue: Scene, transition: Transition = .navigation(type: .cover(direction: .left))) {
        if let target = get(segue: segue) {
            let sender = rootViewController.viewControllers.last ?? rootViewController
            show(target: target, sender: sender, transition: transition)
        }
    }

    private func show(target: UIViewController, sender: UIViewController?, transition: Transition) {
        switch transition {
        case .root(in: let window):
            UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                self.rootViewController.setViewControllers([target], animated: false)
                window.rootViewController = self.rootViewController
            }, completion: nil)
            return
        case .custom: return
        default: break
        }

        guard let sender = sender else {
            fatalError("You need to pass in a sender for .navigation or .modal transitions")
        }

        if let nav = sender as? UINavigationController {
            //push root controller on navigation stack
            nav.pushViewController(target, animated: false)
            return
        }

        switch transition {
        case .navigation(let type):
            if let nav = sender.navigationController {
                // push controller to navigation stack
                nav.hero.navigationAnimationType = .autoReverse(presenting: type)
                nav.pushViewController(target, animated: true)
            }
        case .customModal(let type):
            // present modally with custom animation
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                nav.hero.modalAnimationType = .autoReverse(presenting: type)
                sender.present(nav, animated: true, completion: nil)
            }
        case .replace(let type):
            if let nav = sender.navigationController {
                // replace controllers in navigation stack
                nav.hero.navigationAnimationType = .autoReverse(presenting: type)
                nav.setViewControllers([target], animated: true)
            }
        case .modal:
            // present modally
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                sender.present(nav, animated: true, completion: nil)
            }
        case .detail:
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                sender.showDetailViewController(nav, sender: nil)
            }
        case .alert:
            DispatchQueue.main.async {
                sender.present(target, animated: true, completion: nil)
            }
        default: break
        }
    }
}
