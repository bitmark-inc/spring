//
//  InsightViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import BitmarkSDK
import RxSwift
import RxCocoa
import RxRealm
import FlexLayout
import RealmSwift
import Realm
import SwiftDate

class InsightViewController: ViewController {
    lazy var thisViewModel = viewModel as! InsightViewModel

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var insightView = UIView()
    lazy var headingView = makeHeadingView()
    lazy var fbIncomeView = makeFBIncomeView()
    lazy var adsCategoryView = makeAdsCategoryView()

    // SECTION: FB Income
    lazy var incomeInsightObservable: Observable<Insight> = {
        thisViewModel.realmIncomeInsightRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? InsightViewModel else { return }
        viewModel.fetchDataResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenFetchingData(error: error)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        viewModel.fetchInsight()
    }

    func errorWhenFetchingData(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.signInError())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = insightView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        themeForContentView()

        insightView.flex.define { (flex) in
            flex.addItem(headingView)
            flex.addItem(fbIncomeView)
            flex.addItem(adsCategoryView)
        }

        scroll.addSubview(insightView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }
    }
}

// MARK: - ContainerLayoutDelegate
extension InsightViewController: ContainerLayoutDelegate {
    func layout() {
        insightView.flex.markDirty()
        insightView.flex.layout(mode: .adjustHeight)
        scroll.contentSize = insightView.frame.size
    }
}

extension InsightViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(
            title: R.string.localizable.insights().localizedUppercase,
            color:  ColorTheme.internationalKleinBlue.color)
        headingView.subTitle = R.string.localizable.howfacebookusesyoU()
        headingView.accountButton.rx.tap.bind { [weak self] in
            self?.gotoAccountScreen()
        }.disposed(by: disposeBag)
        return headingView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section)
        return sectionHeadingView
    }

    fileprivate func makeFBIncomeView() -> IncomeView {
        let incomeView = IncomeView()
        incomeView.containerLayoutDelegate = self
        incomeView.setProperties(section: .fbIncome, container: self)
        return incomeView
    }



    fileprivate func  makeAdsCategoryView() -> AdsCategoryView {
        let adsCategoryView = AdsCategoryView()
        adsCategoryView.containerLayoutDelegate = self
        adsCategoryView.setProperties(container: self)
        return adsCategoryView
    }
}

// MARK: - Navigator
extension InsightViewController {
    fileprivate func goToPostListScreen(filterScope: FilterScope) {
        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    fileprivate func gotoAccountScreen() {
        let viewModel = AccountViewModel()
        navigator.show(segue: .account(viewModel: viewModel), sender: self)
    }
}
