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
        usageVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(),
            title: R.string.localizable.usage().localizedUppercase,
            image: R.image.usage_tab_icon(),
            tag: 0)

        let insightsVC = InsightViewController(viewModel: InsightViewModel())
        insightsVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(),
            title: R.string.localizable.insights().localizedUppercase,
            image: R.image.insights_tab_icon(),
            tag: 1
        )

        let streamVC = StreamViewController(viewModel: StreamViewModel())
        streamVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(),
            title: R.string.localizable.streams().localizedUppercase,
            image: R.image.stream(),
            tag: 2
        )

        let tabbarController = HomeTabbarController()
        tabbarController.viewControllers = [usageVC, insightsVC, streamVC]

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

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add view
        addSubview(selectedIndicatorLineView)

        themeService.rx
            .bind({ $0.themeColor }, to: selectedIndicatorLineView.rx.backgroundColor)
            .bind({ $0.blackTextColor }, to: rx.textColor)
            .bind({ $0.themeColor }, to: rx.highlightTextColor)
            .bind({ $0.blackTextColor }, to: rx.iconColor)
            .bind({ $0.themeColor }, to: rx.highlightIconColor)
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

        selectedIndicatorLineView.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 2)
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
