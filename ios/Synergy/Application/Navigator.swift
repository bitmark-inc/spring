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

    // MARK: - segues list, all app scenes
    enum Scene {
        case launching
        case signInWall(viewModel: SignInWallViewModel)
        case howItWorks(viewModel: HowItWorksViewModel)
        case trustIsCritical(viewModel: TrustIsCriticalViewModel)
        case askNotifications(viewModel: AskNotificationsViewModel)
        case getYourData(viewModel: GetYourDataViewModel)
        case requestData(viewModel: RequestDataViewModel)
        case dataRequested(viewModel: DataRequestedViewModel)
        case dataAnalyzing(viewModel: DataAnalyzingViewModel)
        case safari(URL)
        case safariController(URL)
        case hometabs
        case postList(viewModel: PostListViewModel)
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
        case .launching:
            let viewModel = LaunchingViewModel()
            let lauchingVC = LaunchingViewController(viewModel: viewModel)
            return NavigationController(rootViewController: lauchingVC)
        case .signInWall(let viewModel): return SignInWallViewController(viewModel: viewModel)
        case .howItWorks(let viewModel): return HowItWorksViewController(viewModel: viewModel)
        case .trustIsCritical(let viewModel): return TrustIsCriticalViewController(viewModel: viewModel)
        case .askNotifications(let viewModel): return AskNotificationsViewController(viewModel: viewModel)
        case .getYourData(let viewModel): return GetYourDataViewController(viewModel: viewModel)
        case .requestData(let viewModel): return RequestDataViewController(viewModel: viewModel)
        case .dataRequested(let viewModel): return DataRequestedViewController(viewModel: viewModel)
        case .dataAnalyzing(let viewModel): return DataAnalyzingViewController(viewModel: viewModel)
        case .safari(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil

        case .safariController(let url):
            let vc = SFSafariViewController(url: url)
            return vc

        case .hometabs:
            return HomeTabbarController.tabbarController()
        case .postList(let viewModel): return PostListViewController(viewModel: viewModel)
        }
    }

    func pop(sender: UIViewController?, toRoot: Bool = false) {
        if toRoot {
            sender?.navigationController?.popToRootViewController(animated: true)
        } else {
            sender?.navigationController?.popViewController()
        }
    }

    func dismiss(sender: UIViewController?) {
        sender?.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - invoke a single segue
    func show(segue: Scene, sender: UIViewController?, transition: Transition = .navigation(type: .cover(direction: .left))) {
        if let target = get(segue: segue) {
            show(target: target, sender: sender, transition: transition)
        }
    }

    private func show(target: UIViewController, sender: UIViewController?, transition: Transition) {
        switch transition {
        case .root(in: let window):
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                window.rootViewController = target
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
            guard let rootViewController = Self.getRootViewController() else { return }

            // replace controllers in navigation stack
            rootViewController.hero.navigationAnimationType = .autoReverse(presenting: type)
            rootViewController.setViewControllers([target], animated: true)
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

    static func refreshOnboardingStateIfNeeded() {
        guard let rootViewController = getRootViewController() else { return }

        // check if scene is on onboarding flow's refresh state
        guard let currentVC = rootViewController.viewControllers.last,
            [DataRequestedViewController.self, DataAnalyzingViewController.self].contains(where: { $0 == type(of: currentVC) }),
            let window = getWindow()
            else {
                return
        }

        Navigator.default.show(segue: .launching, sender: nil, transition: .root(in: window))
    }

    static func getRootViewController() -> NavigationController? {
        return getWindow()?.rootViewController as? NavigationController
    }

    static func getWindow() -> UIWindow? {
        return UIApplication.shared.windows
            .filter({ $0.isKeyWindow }).first
    }
}
