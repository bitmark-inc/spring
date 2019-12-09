//
//  HomeTabbarController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import ESTabBarController_swift
import RxSwift
import RxCocoa

class HomeTabbarController: ESTabBarController {
    class func tabbarController() -> HomeTabbarController {
        let usageVC = UsageViewController(viewModel: UsageViewModel())
        let usageNavVC = NavigationController(rootViewController: usageVC)

        usageNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#932C19")!),
            title: R.string.localizable.usage().localizedUppercase,
            image: R.image.usage_tab_icon(),
            tag: 0)

        let insightsVC = InsightViewController(viewModel: InsightViewModel())
        let insightsNavVC = NavigationController(rootViewController: insightsVC)
        insightsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#0011AF")!),
            title: R.string.localizable.insights().localizedUppercase,
            image: R.image.insights_tab_icon(),
            tag: 1
        )

        let streamVC = StreamViewController(viewModel: StreamViewModel())
        let streamNavVC = NavigationController(rootViewController: streamVC)
        streamNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#5F6D07")!),
            title: R.string.localizable.streams().localizedUppercase,
            image: R.image.stream(),
            tag: 2
        )

        let tabbarController = HomeTabbarController()
        tabbarController.viewControllers = [usageNavVC, insightsNavVC, streamNavVC]

        return tabbarController
    }

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false

        themeService.rx
            .bind({ $0.background }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
}

class MainTabbarItemContentView: ESTabBarItemContentView {
    let disposeBag = DisposeBag()
    let selectedIndicatorLineView = UIView()
    
    convenience init(highlightColor: UIColor) {
        self.init()
        
        selectedIndicatorLineView.backgroundColor = highlightColor
        highlightIconColor = highlightColor
        highlightTextColor = highlightColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add view
        addSubview(selectedIndicatorLineView)

        themeService.rx
            .bind({ $0.blackTextColor }, to: rx.textColor)
            .bind({ $0.blackTextColor }, to: rx.iconColor)
            .bind({ $0.textViewBackgroundColor }, to: rx.backdropColor)
            .bind({ $0.textViewBackgroundColor }, to: rx.highlightBackdropColor)
        .disposed(by: disposeBag)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateDisplay() {
        super.updateDisplay()

        selectedIndicatorLineView.isHidden = !selected
    }

    override func updateLayout() {
        super.updateLayout()

        selectedIndicatorLineView.frame = CGRect(x: 0, y: -1, width: self.bounds.size.width, height: 2)
    }
}

extension Reactive where Base: ESTabBarItemContentView {

    var textColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.textColor = attr
        }
    }

    var highlightTextColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightTextColor = attr
        }
    }

    var iconColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.iconColor = attr
        }
    }

    var highlightIconColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightIconColor = attr
        }
    }

    var backdropColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.backdropColor = attr
        }
    }

    var highlightBackdropColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightBackdropColor = attr
        }
    }
}
