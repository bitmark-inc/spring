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

class ViewController: ThemedViewController {
  var viewModel: ViewModel?

  init(viewModel: ViewModel?) {
    self.viewModel = viewModel
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
