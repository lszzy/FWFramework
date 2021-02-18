//
//  CoreModule.swift
//  Core
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework

@objcMembers public class Theme: NSObject {
    public static var backgroundColor = UIColor.fwThemeLight(.white, dark: .black)
    public static var textColor = UIColor.fwThemeLight(.black, dark: .white)
    public static var detailColor = UIColor.fwThemeLight(UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
    public static var barColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
    public static var tableColor = UIColor.fwThemeLight(.fwColor(withHex: 0xF2F2F2), dark: .fwColor(withHex: 0x000000))
    public static var cellColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFFFFFF), dark: .fwColor(withHex: 0x1C1C1C))
    public static var borderColor = UIColor.fwThemeLight(.fwColor(withHex: 0xDDDDDD), dark: .fwColor(withHex: 0x303030))
    
    public static func largeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage.fwImage(with: UIColor.fwThemeLight(.fwColor(withHex: 0x017AFF), dark: .fwColor(withHex: 0x0A84FF))), for: .normal)
        button.titleLabel?.font = .fwBoldFont(ofSize: 17)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.fwSetDimension(.width, toSize: FWScreenWidth - 30)
        button.fwSetDimension(.height, toSize: 50)
        return button
    }
}
