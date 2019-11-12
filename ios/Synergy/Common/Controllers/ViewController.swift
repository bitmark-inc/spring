//
//  ViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: ThemedViewController, Navigatable {
  var viewModel: ViewModel?
  var navigator: Navigator!

  init(viewModel: ViewModel?, navigator: Navigator) {
    self.viewModel = viewModel
    self.navigator = navigator
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(nibName: nil, bundle: nil)
  }

  let isLoading = BehaviorRelay(value: false)
  
  lazy var contentView: UIView = {
    let view = UIView()
    self.view.addSubview(view)
    
    view.frame = self.view.safeAreaLayoutGuide.layoutFrame
    
    #if targetEnvironment(simulator)
    view.layer.borderColor = UIColor.Material.yellow.cgColor
    view.layer.borderWidth = 1
    #endif
    
    return view
  }()

  override func setupViews() {
    super.setupViews()

  }

  override func bindViewModel() {
    super.bindViewModel()

//    themeService.rx
//      .bind({ $0.textColor }, to: screenTitleLabel.rx.textColor)
//      .disposed(by: disposeBag)
  }
}
