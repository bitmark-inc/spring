//
//  ThemeManager.swift
//  Synergy
//
//  Created by Anh Nguyen on 10/18/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxTheme

let globalStatusBarStyle = BehaviorRelay<UIStatusBarStyle>(value: .default)
var themeService = ThemeType.currentThemeService(for: .unspecified)

struct OurTheme {
    static let paddingInset = UIEdgeInsets(top: 4, left: Size.dw(18), bottom: 0, right: Size.dw(18))
    static let scrollingPaddingInset = UIEdgeInsets(top: 0, left: Size.dw(18), bottom: Size.dh(150), right: Size.dw(18))
    static let paddingBottom: CGFloat = Size.dh(45)
    static let onboardingPaddingScreenTitle: CGFloat = Size.dh(28)
    static let dashboardPaddingScreenTitle: CGFloat = Size.dh(8)
    static let accountPaddingScreenTitleInset = UIEdgeInsets(top: Size.dh(21), left: 0, bottom: Size.dh(43), right: 0)
    static let accountColorTheme = ColorTheme.black
    static let postCellPadding  = UIEdgeInsets(top: Size.dh(27), left: 18, bottom: Size.dh(32), right: 18)
    static let reactionCellPadding  = UIEdgeInsets(top: Size.dh(27), left: 18, bottom: Size.dh(32), right: 18)
}

protocol Theme {
    var blackTextColor: UIColor { get }
    var tundoraTextColor: UIColor { get }
    var lightTextColor: UIColor { get }
    var highlightTextBackgroundColor: UIColor { get }
    var background: UIColor { get }
    var buttonBackground: UIColor { get }
    var lightButtonTextColor: UIColor { get }
    var blackButtonTextColor: UIColor { get }
    var separateLineColor: UIColor { get }
    var textFieldTextColor: UIColor { get }
    var textFieldPlaceholderColor: UIColor { get }
    var textFieldBackgroundColor: UIColor { get }
    var borderColor: UIColor { get }
    var textViewBackgroundColor: UIColor { get }
    var textViewTextColor: UIColor { get }
    var indicatorColor: UIColor { get }
    var themeColor: UIColor { get }
    var themeBlueColor: UIColor { get }
    var themeIndianKhakiColor: UIColor { get }
    var themeGreenColor: UIColor { get }
    var themeMercuryColor: UIColor { get }
    var controlBackgroundColor: UIColor { get }
    var postCellBackgroundColor: UIColor { get }
    var reactionCellBackgroundColor: UIColor { get }
    var sectionBackgroundColor: UIColor { get }
    var blurCoverColor: UIColor { get }

    init(colorTheme: ColorTheme)
}

struct LightTheme: Theme {
    let blackTextColor = UIColor.Material.black
    let tundoraTextColor = UIColor(hexString: "#444")!
    let lightTextColor = UIColor.Material.white
    let highlightTextBackgroundColor = UIColor(hexString: "#000", transparency: 0.4)!
    let background = UIColor(hexString: "#FFFFFF")!
    let buttonBackground = UIColor(hexString: "#932C19")!
    let lightButtonTextColor = UIColor.Material.white
    let blackButtonTextColor = UIColor(hexString: "#404040")!
    let separateLineColor = UIColor.Material.white
    let textFieldTextColor = ColorTheme.internationalKleinBlue.color
    let textFieldPlaceholderColor = ColorTheme.concord.color
    let textFieldBackgroundColor = UIColor.Material.white
    let borderColor = UIColor.Material.white
    let textViewBackgroundColor = UIColor.Material.white
    let textViewTextColor = UIColor(hexString: "#2B47FD")!
    let indicatorColor = UIColor.Material.grey
    let themeColor = UIColor(hexString: "#932C19")!
    let themeBlueColor = UIColor(hexString: "#0011AF")!
    let themeIndianKhakiColor = ColorTheme.indianKhaki.color
    let themeGreenColor = UIColor(hexString: "#5F6D07")!
    let themeMercuryColor = UIColor(hexString: "#E7E7E7")!
    let controlBackgroundColor = UIColor(hexString: "#EDF0F4")!
    let postCellBackgroundColor = UIColor.clear
    let reactionCellBackgroundColor = UIColor.clear
    let sectionBackgroundColor = UIColor(hexString: "#EDF0F4")!
    let blurCoverColor = UIColor(hexString: "#FFF", transparency: 0.7)!

    init(colorTheme: ColorTheme) {
    }
}

struct DarkTheme: Theme {
    let blackTextColor = UIColor.Material.black
    let tundoraTextColor = UIColor(hexString: "#444")!
    let lightTextColor = UIColor.Material.white
    let highlightTextBackgroundColor = UIColor(hexString: "#000", transparency: 0.4)!
    let background = UIColor(hexString: "#FFFFFF")!
    let buttonBackground = UIColor(hexString: "#000", transparency: 0.4)!
    let lightButtonTextColor = UIColor.Material.white
    let blackButtonTextColor = UIColor(hexString: "#404040")!
    let separateLineColor = UIColor.Material.white
    let textFieldTextColor = ColorTheme.internationalKleinBlue.color
    let textFieldPlaceholderColor = ColorTheme.concord.color
    let textFieldBackgroundColor = UIColor.Material.white
    let borderColor = UIColor.Material.white
    let textViewBackgroundColor = UIColor.Material.white
    let textViewTextColor = UIColor(hexString: "#2B47FD")!
    let indicatorColor = UIColor.Material.grey
    let themeColor = UIColor(hexString: "#932C19")!
    let themeBlueColor = UIColor(hexString: "#0011AF")!
    let themeIndianKhakiColor = ColorTheme.indianKhaki.color
    let themeGreenColor = UIColor(hexString: "#5F6D07")!
    let themeMercuryColor = UIColor(hexString: "#E7E7E7")!
    let controlBackgroundColor = UIColor(hexString: "#EDF0F4")!
    let postCellBackgroundColor = UIColor.clear
    let reactionCellBackgroundColor = UIColor.clear
    let sectionBackgroundColor = UIColor(hexString: "#EDF0F4")!
    let blurCoverColor = UIColor(hexString: "#FFF", transparency: 0.7)!

    init(colorTheme: ColorTheme) {
    }
}

enum ColorTheme: Int, CaseIterable {
    case red, pink, purple, deepPurple, indigo, blue, lightBlue, cyan, teal, green, lightGreen, lime, yellow, amber, orange, deepOrange, brown, gray, blueGray, internationalKleinBlue, concord, silver, yukonGold

    case white, cognac, black, tundora, mercury, indianKhaki

    var color: UIColor {
        switch self {
        case .red:        return UIColor.Material.red
        case .pink:       return UIColor.Material.pink
        case .purple:     return UIColor.Material.purple
        case .deepPurple: return UIColor.Material.deepPurple
        case .indigo:     return UIColor.Material.indigo
        case .blue:       return UIColor.Material.blue
        case .lightBlue:  return UIColor.Material.lightBlue
        case .cyan:       return UIColor.Material.cyan
        case .teal:       return UIColor.Material.teal
        case .green:      return UIColor.Material.green
        case .lightGreen: return UIColor.Material.lightGreen
        case .lime:       return UIColor.Material.lime
        case .yellow:     return UIColor.Material.yellow
        case .amber:      return UIColor.Material.amber
        case .orange:     return UIColor.Material.orange
        case .deepOrange: return UIColor.Material.deepOrange
        case .brown:      return UIColor.Material.brown
        case .gray:       return UIColor.Material.grey
        case .blueGray:   return UIColor.Material.blueGrey
        case .internationalKleinBlue: return UIColor(hexString: "#0011AF")!
        case .concord:    return UIColor(hexString: "#828180")!
        case .silver:        return UIColor(hexString: "#C1C1C1")!
        case .white:        return UIColor.white
        case .cognac:       return UIColor(hexString: "#932C19")!
        case .yukonGold:    return UIColor(hexString: "#5F6D07")!
        case .black:        return UIColor.black
        case .tundora:      return UIColor(hexString: "#444")!
        case .mercury:      return UIColor(hexString: "#E7E7E7")!
        case .indianKhaki:      return UIColor(hexString: "#BBAB8C")!
        }
    }

    var colorDark: UIColor {
        switch self {
        case .red:        return UIColor.Material.red900
        case .pink:       return UIColor.Material.pink900
        case .purple:     return UIColor.Material.purple900
        case .deepPurple: return UIColor.Material.deepPurple900
        case .indigo:     return UIColor.Material.indigo900
        case .blue:       return UIColor.Material.blue900
        case .lightBlue:  return UIColor.Material.lightBlue900
        case .cyan:       return UIColor.Material.cyan900
        case .teal:       return UIColor.Material.teal900
        case .green:      return UIColor.Material.green900
        case .lightGreen: return UIColor.Material.lightGreen900
        case .lime:       return UIColor.Material.lime900
        case .yellow:     return UIColor.Material.yellow900
        case .amber:      return UIColor.Material.amber900
        case .orange:     return UIColor.Material.orange900
        case .deepOrange: return UIColor.Material.deepOrange900
        case .brown:      return UIColor.Material.brown900
        case .gray:       return UIColor.Material.grey900
        case .blueGray:   return UIColor.Material.blueGrey900
        case .internationalKleinBlue: return UIColor(hexString: "#0011AF")!
        case .concord:    return UIColor(hexString: "#828180")!
        case .silver:    return UIColor(hexString: "#C1C1C1")!
        case .white:        return UIColor.white
        case .cognac:       return UIColor(hexString: "#932C19")!
        case .yukonGold:    return UIColor(hexString: "#5F6D07")!
        case .black:        return UIColor.black
        case .tundora:      return UIColor(hexString: "#444")!
        case .mercury:      return UIColor(hexString: "#E7E7E7")!
        case .indianKhaki:      return UIColor(hexString: "#BBAB8C")!
        }
    }

    var title: String {
        switch self {
        case .red:        return "Red"
        case .pink:       return "Pink"
        case .purple:     return "Purple"
        case .deepPurple: return "Deep Purple"
        case .indigo:     return "Indigo"
        case .blue:       return "Blue"
        case .lightBlue:  return "Light Blue"
        case .cyan:       return "Cyan"
        case .teal:       return "Teal"
        case .green:      return "Green"
        case .lightGreen: return "Light Green"
        case .lime:       return "Lime"
        case .yellow:     return "Yellow"
        case .amber:      return "Amber"
        case .orange:     return "Orange"
        case .deepOrange: return "Deep Orange"
        case .brown:      return "Brown"
        case .gray:       return "Gray"
        case .blueGray:   return "Blue Gray"
        case .internationalKleinBlue: return "international klein blue"
        case .concord:    return "concord"
        case .silver:        return ""
        case .white:        return "White"
        case .cognac:       return "Cognac"
        case .yukonGold:    return "Yokon Gold"
        case .black:        return "Black"
        case .tundora:      return "Tundora"
        case .mercury:      return "Mercury"
        case .indianKhaki:      return "Cornflower Blue"
        }
    }
}

enum ThemeType: ThemeProvider {
    case light(color: ColorTheme)
    case dark(color: ColorTheme)

    var associatedObject: Theme {
        switch self {
        case .light(let color): return LightTheme(colorTheme: color)
        case .dark(let color): return DarkTheme(colorTheme: color)
        }
    }

    var isDark: Bool {
        switch self {
        case .dark: return true
        default: return false
        }
    }

    func toggled() -> ThemeType {
        var theme: ThemeType
        switch self {
        case .light(let color): theme = ThemeType.dark(color: color)
        case .dark(let color): theme = ThemeType.light(color: color)
        }
        return theme
    }

    func withColor(color: ColorTheme) -> ThemeType {
        var theme: ThemeType
        switch self {
        case .light: theme = ThemeType.light(color: color)
        case .dark: theme = ThemeType.dark(color: color)
        }
        theme.save()
        return theme
    }
}

extension ThemeService where Provider == ThemeType {
    func switchThemeType(for userStyle: UIUserInterfaceStyle) {
        let updateTheme = ThemeType.currentTheme(isDark: userStyle == .dark)
        self.switch(updateTheme)
    }
}

extension ThemeType {
    static func currentThemeService(for userStyle: UIUserInterfaceStyle) -> ThemeService<ThemeType> {
        let currentThemeForStyle = currentTheme(isDark: userStyle == .dark)
        return ThemeType.service(initial: currentThemeForStyle)
    }

    static func currentTheme(isDark: Bool) -> ThemeType {
        let defaults = UserDefaults.standard
        let colorTheme = ColorTheme(rawValue: defaults.integer(forKey: "ThemeKey")) ?? ColorTheme.red
        let theme = isDark ? ThemeType.dark(color: colorTheme) : ThemeType.light(color: colorTheme)
        theme.save()
        return theme
    }

    func save() {
        let defaults = UserDefaults.standard
        switch self {
        case .light(let color): defaults.set(color.rawValue, forKey: "ThemeKey")
        case .dark(let color): defaults.set(color.rawValue, forKey: "ThemeKey")
        }
    }
}

class Size {

    // dimention size
    static func ds(_ size: CGFloat) -> CGFloat {
        return (size / 414) * UIScreen.main.bounds.width
    }

    // dimention width
    static func dw(_ size: Int) -> CGFloat {
        let sizeFloat = CGFloat(size)
        return (sizeFloat / 414) * UIScreen.main.bounds.width
    }

    // dimention height
    static func dh(_ size: Int) -> CGFloat {
        let sizeFloat = CGFloat(size)
        return (sizeFloat / 896) * UIScreen.main.bounds.height
    }
}

class Avenir {
    static func size(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Avenir", size: Size.ds(size))!
    }

    class Heavy {
        static func size(_ size: CGFloat) -> UIFont {
            return UIFont(name: "Avenir-Heavy", size: Size.ds(size))!
        }
    }
}

extension Reactive where Base: UIView {

    var backgroundColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.backgroundColor = attr
        }
    }

    var borderColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.borderColor = attr
        }
    }
}

extension Reactive where Base: UITextField {

    var borderColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.borderColor = attr
        }
    }

    var placeholderColor: Binder<UIColor?> {
        return Binder(self.base) { textfield, attr in
            guard let color = attr else { return }
            textfield.setPlaceHolderTextColor(color)
        }
    }
}

extension Reactive where Base: UITableView {

    var separatorColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.separatorColor = attr
        }
    }
}

extension Reactive where Base: UINavigationBar {

    @available(iOS 11.0, *)
    var largeTitleTextAttributes: Binder<[NSAttributedString.Key: Any]?> {
        return Binder(self.base) { view, attr in
            view.largeTitleTextAttributes = attr
        }
    }
}

extension Reactive where Base: UIApplication {

    var statusBarStyle: Binder<UIStatusBarStyle> {
        return Binder(self.base) { _, attr in
            globalStatusBarStyle.accept(attr)
        }
    }
}

public extension Reactive where Base: UISwitch {

    var onTintColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.onTintColor = attr
        }
    }

    var thumbTintColor: Binder<UIColor?> {
        return Binder(self.base) { view, attr in
            view.thumbTintColor = attr
        }
    }
}
