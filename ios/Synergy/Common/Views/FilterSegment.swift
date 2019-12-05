//
//  FilterSegment.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FilterSegment: UIView {
    private let disposeBag = DisposeBag()
    private lazy var underlineView: UIView = UIView()
    
    var elements: [String] = [] {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    // To be using without RxCocoa extension
    var selectedIndexHandler: ((Int) -> Void)?
    
    var selectedIndex: Int = 0
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    convenience init(elements: [String]) {
        self.init()
        self.elements = elements
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        removeSubviews()
        
        let total = elements.count
        if total == 0 {
            return
        }
        let width = self.frame.size.width / CGFloat(total)
        let height = self.frame.size.height
        
        for i in 0..<total {
            let btn = UIButton(frame: CGRect(x: CGFloat(i) * width,
                                             y: 0,
                                             width: width,
                                             height: height))
            btn.setTitle(elements[i], for: .normal)
            btn.titleLabel?.font = R.font.atlasGroteskThin(size: 18)
            btn.tag = i
            btn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
            addSubview(btn)
            
            themeService.rx
                .bind({ $0.blackTextColor }, to: btn.rx.titleColor(for: .normal))
            .disposed(by: disposeBag)
        }
        
        // Underline
        addSubview(underlineView)
        setUnderlinePosition(withIndex: selectedIndex)
        
        // Colors
        themeService.rx
            .bind({ $0.blackTextColor }, to: underlineView.rx.backgroundColor)
            .bind({ $0.controlBackgroundColor }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }
    
    @objc func btnTapped(sender: UIButton) {
        self.selectedIndex = sender.tag
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.setUnderlinePosition(withIndex: self.selectedIndex)
        }
        
        selectedIndexHandler?(self.selectedIndex)
    }
    
    private func setUnderlinePosition(withIndex index: Int) {
        let width = self.frame.size.width / CGFloat(elements.count)
        let lineHeight: CGFloat = 1
        underlineView.frame = CGRect(x: CGFloat(index) * width, y: height - lineHeight, width: width, height: lineHeight)
    }
}

extension Reactive where Base: FilterSegment {
    
    /// Reactive wrapper for `selectedIndex` property.
    var selectedIndex: ControlProperty<Int> {
        let source = Observable<Int>.create { (observer) -> Disposable in
            self.base.selectedIndexHandler = { index in
                observer.onNext(index)
            }
            
            return Disposables.create()
        }

        let observer = Binder(base) { (filterSegment, value: Int) in
            filterSegment.selectedIndex = value
        }
        
        return ControlProperty(values: source, valueSink: observer)
    }
}
