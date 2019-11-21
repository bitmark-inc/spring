//
//  DesignedSegmentControl.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DesignedSegmentControl: UIControl {

    // MARK: - Properties
    var segmentButtons = [UIButton]()
    var selectorBar: UIView!
    var selectedSegmentIndex = BehaviorRelay<Int>(value: 0)
    var segmentTitles: [String]!
    let disposeBag = DisposeBag()

    // MARK: - Init
    init(titles: [String], width: CGFloat, height: CGFloat) {
        self.segmentTitles = titles
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        setupViews()

        // set first button as default selected segment
        segmentButtons.first?.sendActions(for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Handlers
    @objc func buttonTapped(button: UIButton) {
        for (segmentButtonIndex, segmentButton) in segmentButtons.enumerated() {
            if segmentButton == button {
                selectedSegmentIndex.accept(segmentButtonIndex)

                let  selectorStartPosition = frame.width / CGFloat(segmentButtons.count) * CGFloat(segmentButtonIndex)

                UIView.animate(withDuration: 0.2) {
                    self.selectorBar.frame.origin.x = selectorStartPosition
                }
            }
        }

        sendActions(for: .valueChanged)
    }

    // MARK: - setup views
    fileprivate func setupViews() {
        for segmentTitle in segmentTitles {
            let button = setupSegmentButton(title: segmentTitle)
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            segmentButtons.append(button)
        }

        // *** Setup UI in view ***
        let stackView = UIStackView(
            arrangedSubviews: segmentButtons,
            axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually
        )
        setupSelectorBar()

        addSubview(stackView)
        addSubview(selectorBar)

        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    fileprivate func setupSegmentButton(title: String) -> UIButton {
        let button = Button()
        button.titleLabel?.font = Avenir.Heavy.size(24)
        button.setTitle(title, for: .normal)
        return button
    }

    fileprivate func setupSelectorBar() {
        let selectorWidth = frame.width / CGFloat(segmentTitles.count)
        selectorBar = UIView.init(frame: CGRect.init(x: 0, y: frame.height - 5, width: selectorWidth, height: 5.0))
        themeService.rx
            .bind({ $0.textColor }, to: selectorBar.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
}
