//
//  MoodView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class MoodView: UIView {

    // MARK: - Properties
    fileprivate lazy var moodImage = makeMoodImage()
    fileprivate lazy var titleBarLabel = makeTitleBarLabel()
    fileprivate lazy var moodBarImage = makeMoodBarImage()
    fileprivate lazy var noActivityView = makeNoActivityView()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(0, 18, 0, 18)
            .define { (flex) in
                flex.addItem(moodImage).marginTop(21)
                flex.addItem(titleBarLabel).marginTop(24)
                flex.addItem(moodBarImage).marginTop(18).width(100%)

                flex.addItem().direction(.row)
                    .justifyContent(.spaceBetween)
                    .marginTop(8)
                    .define { (flex) in
                        flex.addItem(makeMoodTextView(moodText: R.string.localizable.unhappy(), moodValue: 1, valueAlignSelf: .start))
                        flex.addItem(makeMoodTextView(moodText: R.string.localizable.happy(), moodValue: 10, valueAlignSelf: .end))
                    }
                flex.addItem(noActivityView).alignSelf(.center)
                flex.addItem().height(Size.dh(30))
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: UsageViewController) {
        weak var container = container
        var dataObserver: Disposable? // stop observing old-data

        switch section {
        case .mood:
            container?.thisViewModel.realmMoodRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self, let container = container else { return }
                    if usage != nil {
                        dataObserver?.dispose()
                        dataObserver = container.moodObservable
                            .map { $0.value }
                            .subscribe(onNext: { [weak self] (moodValue) in
                                self?.fillData(moodValue: moodValue)
                            })

                        dataObserver?
                            .disposed(by: self.disposeBag)
                    } else {
                        dataObserver?.dispose()
                        self.fillData(moodValue: nil)
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    func fillData(moodValue: Double?) {
        if let moodValue = moodValue {
            noActivityView.isHidden = true
            let moodType = MoodType(value: Int(moodValue))
            moodImage.image = moodType.moodImage
            moodBarImage.image = moodType.moodBarImage
        } else {
            noActivityView.isHidden = false
            moodImage.image = R.image.mood0()
            moodBarImage.image = R.image.moodBar0()
        }

        moodBarImage.flex.markDirty()
        flex.layout()
    }
}

extension MoodView {
    fileprivate func makeMoodImage() -> ImageView {
        let imageView = ImageView()
        imageView.flex.height(112)
        return imageView
    }

    fileprivate func makeTitleBarLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.moodAverage().localizedUppercase,
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            colorTheme: ColorTheme.black)
        return label
    }

    fileprivate func makeMoodBarImage() -> ImageView {
        let imageView = ImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }

    fileprivate func makeMoodTextView(moodText: String, moodValue: Int, valueAlignSelf: Flex.AlignSelf) -> UIView {
        let view = UIView()

        let moodTextLabel = Label()
        moodTextLabel.apply(text: moodText, font: R.font.atlasGroteskLight(size: 10), colorTheme: .black)

        let moodValueLabel = Label()
        moodValueLabel.apply(text: "  \(moodValue)", font: R.font.atlasGroteskLight(size: 10), colorTheme: .black)

        view.flex.define { (flex) in
            flex.addItem(moodTextLabel)
            flex.addItem(moodValueLabel).marginTop(2).alignSelf(valueAlignSelf)
        }

        return view
    }

    fileprivate func makeNoActivityView() -> Label {
        let label = Label()
        label.apply(text: R.string.localizable.graphMoodNoActivity(),
                    font: R.font.atlasGroteskLight(size: Size.ds(14)),
                    colorTheme: .black,
                    lineHeight: 1.056)
        label.isHidden = true
        return label
    }
}
