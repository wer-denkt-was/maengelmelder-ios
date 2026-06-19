//
//  MMFontScheme.shared.swift
//  Maengelmelder
//
//  Created by Felix on 16.02.24.
//
import UIKit

/**
 FontScheme for the Maengelmelder-Module.
 */
public class MMFontScheme {
    
    /** The shared instance. Use this to access the font scheme. */
    public static let shared = MMFontScheme()
    
    /** The font that is used on buttons */
    public var buttonTitleFont = UIFont (name: "HelveticaNeue-Medium", size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    /** The font that is used for titles */
    public var titleTextFont = UIFont (name: "HelveticaNeue-Bold", size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    /** The font that is used for subtitles */
    public var subTitleTextFont = UIFont (name: "HelveticaNeue-Bold", size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    /** The font that is used for normal texts */
    public var normalTextFont = UIFont (name: "HelveticaNeue", size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    /** The font that is used for small texts */
    public var smallTextFont = UIFont(name: "HelveticaNeue-Light", size: UIFont.preferredFont(forTextStyle: .footnote).pointSize)
}
