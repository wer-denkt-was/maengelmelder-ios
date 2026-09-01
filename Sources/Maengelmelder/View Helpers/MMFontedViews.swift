//
//  MMFontedViews.swift
//  Maengelmelder
//
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class MMLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        font = mappedFont(for: font)
    }

    func mappedFont(for current: UIFont) -> UIFont {
        let size = current.pointSize
        let descriptor = current.fontDescriptor
        let scheme = MMFontScheme.shared
        if let style = resolvedTextStyle(from: descriptor) {
            switch style {
            case .title1, .title2, .title3, .largeTitle:
                return (scheme.titleTextFont ?? scheme.normalTextFont)?.withSize(size) ?? current
            case .headline, .subheadline:
                return (scheme.subTitleTextFont ?? scheme.normalTextFont)?.withSize(size) ?? current
            case .footnote, .caption1, .caption2:
                return (scheme.smallTextFont ?? scheme.normalTextFont)?.withSize(size) ?? current
            default:
                return scheme.normalTextFont?.withSize(size) ?? current
            }
        }
        if descriptor.symbolicTraits.contains(.traitBold) {
            return (scheme.titleTextFont ?? scheme.normalTextFont)?.withSize(size) ?? current
        }
        return scheme.normalTextFont?.withSize(size) ?? current
    }

    // UIKit stores the text style internally as a String rawValue, not as UIFont.TextStyle directly.
    private func resolvedTextStyle(from descriptor: UIFontDescriptor) -> UIFont.TextStyle? {
        if let style = descriptor.object(forKey: .textStyle) as? UIFont.TextStyle { return style }
        if let raw = descriptor.object(forKey: .textStyle) as? String { return UIFont.TextStyle(rawValue: raw) }
        return nil
    }
}

class MMButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        let size = titleLabel?.font.pointSize ?? 15
        let buttonFont = MMFontScheme.shared.buttonTitleFont ?? MMFontScheme.shared.normalTextFont
        if #available(iOS 15, *), configuration != nil {
            configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var a = attrs
                a.font = buttonFont?.withSize(size)
                return a
            }
        } else {
            titleLabel?.font = buttonFont?.withSize(size)
        }
    }
}

class MMTextField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let size = font?.pointSize else { return }
        font = MMFontScheme.shared.normalTextFont?.withSize(size)
    }
}

class MMTextView: UITextView {
    override func awakeFromNib() {
        super.awakeFromNib()
        font = MMFontScheme.shared.normalTextFont?.withSize(font?.pointSize ?? 17)
    }
}
