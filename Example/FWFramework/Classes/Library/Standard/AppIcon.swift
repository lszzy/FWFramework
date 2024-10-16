//
//  AppIcon.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

extension Icon {
    static var backImage: UIImage? {
        UIImage.app.image(systemName: "chevron.left", scaleWidth: 24)
    }

    static var closeImage: UIImage? {
        UIImage.app.image(systemName: "xmark", scaleWidth: 24)
    }
}

class MaterialIcons: Icon {
    static func setupIcon() {
        if let fileUrl = Bundle.main.url(forResource: "Material", withExtension: "ttf") {
            Icon.installIconFont(fileUrl)
        }
        Icon.registerClass(MaterialIcons.self)
    }

    override class func iconFont(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Material-Design-Iconic-Font", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }

    override class func iconMapper() -> [String: String] {
        [
            "zmdi-var-3d-rotation": "\u{f101}",
            "zmdi-var-airplane-off": "\u{f102}",
            "zmdi-var-airplane": "\u{f103}",
            "zmdi-var-album": "\u{f104}",
            "zmdi-var-archive": "\u{f105}",
            "zmdi-var-assignment-account": "\u{f106}",
            "zmdi-var-assignment-alert": "\u{f107}",
            "zmdi-var-assignment-check": "\u{f108}",
            "zmdi-var-assignment-o": "\u{f109}",
            "zmdi-var-assignment-return": "\u{f10a}",
            "zmdi-var-assignment-returned": "\u{f10b}",
            "zmdi-var-assignment": "\u{f10c}",
            "zmdi-var-attachment-alt": "\u{f10d}",
            "zmdi-var-attachment": "\u{f10e}",
            "zmdi-var-audio": "\u{f10f}",
            "zmdi-var-badge-check": "\u{f110}",
            "zmdi-var-balance-wallet": "\u{f111}",
            "zmdi-var-balance": "\u{f112}",
            "zmdi-var-battery-alert": "\u{f113}",
            "zmdi-var-battery-flash": "\u{f114}",
            "zmdi-var-battery-unknown": "\u{f115}",
            "zmdi-var-battery": "\u{f116}",
            "zmdi-var-bike": "\u{f117}",
            "zmdi-var-block-alt": "\u{f118}",
            "zmdi-var-block": "\u{f119}",
            "zmdi-var-boat": "\u{f11a}",
            "zmdi-var-book-image": "\u{f11b}",
            "zmdi-var-book": "\u{f11c}",
            "zmdi-var-bookmark-outline": "\u{f11d}",
            "zmdi-var-bookmark": "\u{f11e}",
            "zmdi-var-brush": "\u{f11f}",
            "zmdi-var-bug": "\u{f120}",
            "zmdi-var-bus": "\u{f121}",
            "zmdi-var-cake": "\u{f122}",
            "zmdi-var-car-taxi": "\u{f123}",
            "zmdi-var-car-wash": "\u{f124}",
            "zmdi-var-car": "\u{f125}",
            "zmdi-var-card-giftcard": "\u{f126}",
            "zmdi-var-card-membership": "\u{f127}",
            "zmdi-var-card-travel": "\u{f128}",
            "zmdi-var-card": "\u{f129}",
            "zmdi-var-case-check": "\u{f12a}",
            "zmdi-var-case-download": "\u{f12b}",
            "zmdi-var-case-play": "\u{f12c}",
            "zmdi-var-case": "\u{f12d}",
            "zmdi-var-cast-connected": "\u{f12e}",
            "zmdi-var-cast": "\u{f12f}",
            "zmdi-var-chart-donut": "\u{f130}",
            "zmdi-var-chart": "\u{f131}",
            "zmdi-var-city-alt": "\u{f132}",
            "zmdi-var-city": "\u{f133}",
            "zmdi-var-close-circle-o": "\u{f134}",
            "zmdi-var-close-circle": "\u{f135}",
            "zmdi-var-close": "\u{f136}",
            "zmdi-var-cocktail": "\u{f137}",
            "zmdi-var-code-setting": "\u{f138}",
            "zmdi-var-code-smartphone": "\u{f139}",
            "zmdi-var-code": "\u{f13a}",
            "zmdi-var-coffee": "\u{f13b}",
            "zmdi-var-collection-bookmark": "\u{f13c}",
            "zmdi-var-collection-case-play": "\u{f13d}",
            "zmdi-var-collection-folder-image": "\u{f13e}",
            "zmdi-var-collection-image-o": "\u{f13f}",
            "zmdi-var-collection-image": "\u{f140}",
            "zmdi-var-collection-item-1": "\u{f141}",
            "zmdi-var-collection-item-2": "\u{f142}",
            "zmdi-var-collection-item-3": "\u{f143}",
            "zmdi-var-collection-item-4": "\u{f144}",
            "zmdi-var-collection-item-5": "\u{f145}",
            "zmdi-var-collection-item-6": "\u{f146}",
            "zmdi-var-collection-item-7": "\u{f147}",
            "zmdi-var-collection-item-8": "\u{f148}",
            "zmdi-var-collection-item-9-plus": "\u{f149}",
            "zmdi-var-collection-item-9": "\u{f14a}",
            "zmdi-var-collection-item": "\u{f14b}",
            "zmdi-var-collection-music": "\u{f14c}",
            "zmdi-var-collection-pdf": "\u{f14d}",
            "zmdi-var-collection-plus": "\u{f14e}",
            "zmdi-var-collection-speaker": "\u{f14f}",
            "zmdi-var-collection-text": "\u{f150}",
            "zmdi-var-collection-video": "\u{f151}",
            "zmdi-var-compass": "\u{f152}",
            "zmdi-var-cutlery": "\u{f153}",
            "zmdi-var-delete": "\u{f154}",
            "zmdi-var-dialpad": "\u{f155}",
            "zmdi-var-dns": "\u{f156}",
            "zmdi-var-drink": "\u{f157}",
            "zmdi-var-edit": "\u{f158}",
            "zmdi-var-email-open": "\u{f159}",
            "zmdi-var-email": "\u{f15a}",
            "zmdi-var-eye-off": "\u{f15b}",
            "zmdi-var-eye": "\u{f15c}",
            "zmdi-var-eyedropper": "\u{f15d}",
            "zmdi-var-favorite-outline": "\u{f15e}",
            "zmdi-var-favorite": "\u{f15f}",
            "zmdi-var-filter-list": "\u{f160}",
            "zmdi-var-fire": "\u{f161}",
            "zmdi-var-flag": "\u{f162}",
            "zmdi-var-flare": "\u{f163}",
            "zmdi-var-flash-auto": "\u{f164}",
            "zmdi-var-flash-off": "\u{f165}",
            "zmdi-var-flash": "\u{f166}",
            "zmdi-var-flip": "\u{f167}",
            "zmdi-var-flower-alt": "\u{f168}",
            "zmdi-var-flower": "\u{f169}",
            "zmdi-var-font": "\u{f16a}",
            "zmdi-var-fullscreen-alt": "\u{f16b}",
            "zmdi-var-fullscreen-exit": "\u{f16c}",
            "zmdi-var-fullscreen": "\u{f16d}",
            "zmdi-var-functions": "\u{f16e}",
            "zmdi-var-gas-station": "\u{f16f}",
            "zmdi-var-gesture": "\u{f170}",
            "zmdi-var-globe-alt": "\u{f171}",
            "zmdi-var-globe-lock": "\u{f172}",
            "zmdi-var-globe": "\u{f173}",
            "zmdi-var-graduation-cap": "\u{f174}",
            "zmdi-var-home": "\u{f175}",
            "zmdi-var-hospital-alt": "\u{f176}",
            "zmdi-var-hospital": "\u{f177}",
            "zmdi-var-hotel": "\u{f178}",
            "zmdi-var-hourglass-alt": "\u{f179}",
            "zmdi-var-hourglass-outline": "\u{f17a}",
            "zmdi-var-hourglass": "\u{f17b}",
            "zmdi-var-http": "\u{f17c}",
            "zmdi-var-image-alt": "\u{f17d}",
            "zmdi-var-image-o": "\u{f17e}",
            "zmdi-var-image": "\u{f17f}",
            "zmdi-var-inbox": "\u{f180}",
            "zmdi-var-invert-colors-off": "\u{f181}",
            "zmdi-var-invert-colors": "\u{f182}",
            "zmdi-var-key": "\u{f183}",
            "zmdi-var-label-alt-outline": "\u{f184}",
            "zmdi-var-label-alt": "\u{f185}",
            "zmdi-var-label-heart": "\u{f186}",
            "zmdi-var-label": "\u{f187}",
            "zmdi-var-labels": "\u{f188}",
            "zmdi-var-lamp": "\u{f189}",
            "zmdi-var-landscape": "\u{f18a}",
            "zmdi-var-layers-off": "\u{f18b}",
            "zmdi-var-layers": "\u{f18c}",
            "zmdi-var-library": "\u{f18d}",
            "zmdi-var-link": "\u{f18e}",
            "zmdi-var-lock-open": "\u{f18f}",
            "zmdi-var-lock-outline": "\u{f190}",
            "zmdi-var-lock": "\u{f191}",
            "zmdi-var-mail-reply-all": "\u{f192}",
            "zmdi-var-mail-reply": "\u{f193}",
            "zmdi-var-mail-send": "\u{f194}",
            "zmdi-var-mall": "\u{f195}",
            "zmdi-var-map": "\u{f196}",
            "zmdi-var-menu": "\u{f197}",
            "zmdi-var-money-box": "\u{f198}",
            "zmdi-var-money-off": "\u{f199}",
            "zmdi-var-money": "\u{f19a}",
            "zmdi-var-more-vert": "\u{f19b}",
            "zmdi-var-more": "\u{f19c}",
            "zmdi-var-movie-alt": "\u{f19d}",
            "zmdi-var-movie": "\u{f19e}",
            "zmdi-var-nature-people": "\u{f19f}",
            "zmdi-var-nature": "\u{f1a0}",
            "zmdi-var-navigation": "\u{f1a1}",
            "zmdi-var-open-in-browser": "\u{f1a2}",
            "zmdi-var-open-in-new": "\u{f1a3}",
            "zmdi-var-palette": "\u{f1a4}",
            "zmdi-var-parking": "\u{f1a5}",
            "zmdi-var-pin-account": "\u{f1a6}",
            "zmdi-var-pin-assistant": "\u{f1a7}",
            "zmdi-var-pin-drop": "\u{f1a8}",
            "zmdi-var-pin-help": "\u{f1a9}",
            "zmdi-var-pin-off": "\u{f1aa}",
            "zmdi-var-pin": "\u{f1ab}",
            "zmdi-var-pizza": "\u{f1ac}",
            "zmdi-var-plaster": "\u{f1ad}",
            "zmdi-var-power-setting": "\u{f1ae}",
            "zmdi-var-power": "\u{f1af}",
            "zmdi-var-print": "\u{f1b0}",
            "zmdi-var-puzzle-piece": "\u{f1b1}",
            "zmdi-var-quote": "\u{f1b2}",
            "zmdi-var-railway": "\u{f1b3}",
            "zmdi-var-receipt": "\u{f1b4}",
            "zmdi-var-refresh-alt": "\u{f1b5}",
            "zmdi-var-refresh-sync-alert": "\u{f1b6}",
            "zmdi-var-refresh-sync-off": "\u{f1b7}",
            "zmdi-var-refresh-sync": "\u{f1b8}",
            "zmdi-var-refresh": "\u{f1b9}",
            "zmdi-var-roller": "\u{f1ba}",
            "zmdi-var-ruler": "\u{f1bb}",
            "zmdi-var-scissors": "\u{f1bc}",
            "zmdi-var-screen-rotation-lock": "\u{f1bd}",
            "zmdi-var-screen-rotation": "\u{f1be}",
            "zmdi-var-search-for": "\u{f1bf}",
            "zmdi-var-search-in-file": "\u{f1c0}",
            "zmdi-var-search-in-page": "\u{f1c1}",
            "zmdi-var-search-replace": "\u{f1c2}",
            "zmdi-var-search": "\u{f1c3}",
            "zmdi-var-seat": "\u{f1c4}",
            "zmdi-var-settings-square": "\u{f1c5}",
            "zmdi-var-settings": "\u{f1c6}",
            "zmdi-var-shield-check": "\u{f1c7}",
            "zmdi-var-shield-security": "\u{f1c8}",
            "zmdi-var-shopping-basket": "\u{f1c9}",
            "zmdi-var-shopping-cart-plus": "\u{f1ca}",
            "zmdi-var-shopping-cart": "\u{f1cb}",
            "zmdi-var-sign-in": "\u{f1cc}",
            "zmdi-var-sort-amount-asc": "\u{f1cd}",
            "zmdi-var-sort-amount-desc": "\u{f1ce}",
            "zmdi-var-sort-asc": "\u{f1cf}",
            "zmdi-var-sort-desc": "\u{f1d0}",
            "zmdi-var-spellcheck": "\u{f1d1}",
            "zmdi-var-storage": "\u{f1d2}",
            "zmdi-var-store-24": "\u{f1d3}",
            "zmdi-var-store": "\u{f1d4}",
            "zmdi-var-subway": "\u{f1d5}",
            "zmdi-var-sun": "\u{f1d6}",
            "zmdi-var-tab-unselected": "\u{f1d7}",
            "zmdi-var-tab": "\u{f1d8}",
            "zmdi-var-tag-close": "\u{f1d9}",
            "zmdi-var-tag-more": "\u{f1da}",
            "zmdi-var-tag": "\u{f1db}",
            "zmdi-var-thumb-down": "\u{f1dc}",
            "zmdi-var-thumb-up-down": "\u{f1dd}",
            "zmdi-var-thumb-up": "\u{f1de}",
            "zmdi-var-ticket-star": "\u{f1df}",
            "zmdi-var-toll": "\u{f1e0}",
            "zmdi-var-toys": "\u{f1e1}",
            "zmdi-var-traffic": "\u{f1e2}",
            "zmdi-var-translate": "\u{f1e3}",
            "zmdi-var-triangle-down": "\u{f1e4}",
            "zmdi-var-triangle-up": "\u{f1e5}",
            "zmdi-var-truck": "\u{f1e6}",
            "zmdi-var-turning-sign": "\u{f1e7}",
            "zmdi-var-wallpaper": "\u{f1e8}",
            "zmdi-var-washing-machine": "\u{f1e9}",
            "zmdi-var-window-maximize": "\u{f1ea}",
            "zmdi-var-window-minimize": "\u{f1eb}",
            "zmdi-var-window-restore": "\u{f1ec}",
            "zmdi-var-wrench": "\u{f1ed}",
            "zmdi-var-zoom-in": "\u{f1ee}",
            "zmdi-var-zoom-out": "\u{f1ef}",
            "zmdi-var-alert-circle-o": "\u{f1f0}",
            "zmdi-var-alert-circle": "\u{f1f1}",
            "zmdi-var-alert-octagon": "\u{f1f2}",
            "zmdi-var-alert-polygon": "\u{f1f3}",
            "zmdi-var-alert-triangle": "\u{f1f4}",
            "zmdi-var-help-outline": "\u{f1f5}",
            "zmdi-var-help": "\u{f1f6}",
            "zmdi-var-info-outline": "\u{f1f7}",
            "zmdi-var-info": "\u{f1f8}",
            "zmdi-var-notifications-active": "\u{f1f9}",
            "zmdi-var-notifications-add": "\u{f1fa}",
            "zmdi-var-notifications-none": "\u{f1fb}",
            "zmdi-var-notifications-off": "\u{f1fc}",
            "zmdi-var-notifications-paused": "\u{f1fd}",
            "zmdi-var-notifications": "\u{f1fe}",
            "zmdi-var-account-add": "\u{f1ff}",
            "zmdi-var-account-box-mail": "\u{f200}",
            "zmdi-var-account-box-o": "\u{f201}",
            "zmdi-var-account-box-phone": "\u{f202}",
            "zmdi-var-account-box": "\u{f203}",
            "zmdi-var-account-calendar": "\u{f204}",
            "zmdi-var-account-circle": "\u{f205}",
            "zmdi-var-account-o": "\u{f206}",
            "zmdi-var-account": "\u{f207}",
            "zmdi-var-accounts-add": "\u{f208}",
            "zmdi-var-accounts-alt": "\u{f209}",
            "zmdi-var-accounts-list-alt": "\u{f20a}",
            "zmdi-var-accounts-list": "\u{f20b}",
            "zmdi-var-accounts-outline": "\u{f20c}",
            "zmdi-var-accounts": "\u{f20d}",
            "zmdi-var-face": "\u{f20e}",
            "zmdi-var-female": "\u{f20f}",
            "zmdi-var-male-alt": "\u{f210}",
            "zmdi-var-male-female": "\u{f211}",
            "zmdi-var-male": "\u{f212}",
            "zmdi-var-mood-bad": "\u{f213}",
            "zmdi-var-mood": "\u{f214}",
            "zmdi-var-run": "\u{f215}",
            "zmdi-var-walk": "\u{f216}",
            "zmdi-var-cloud-box": "\u{f217}",
            "zmdi-var-cloud-circle": "\u{f218}",
            "zmdi-var-cloud-done": "\u{f219}",
            "zmdi-var-cloud-download": "\u{f21a}",
            "zmdi-var-cloud-off": "\u{f21b}",
            "zmdi-var-cloud-outline-alt": "\u{f21c}",
            "zmdi-var-cloud-outline": "\u{f21d}",
            "zmdi-var-cloud-upload": "\u{f21e}",
            "zmdi-var-cloud": "\u{f21f}",
            "zmdi-var-download": "\u{f220}",
            "zmdi-var-file-plus": "\u{f221}",
            "zmdi-var-file-text": "\u{f222}",
            "zmdi-var-file": "\u{f223}",
            "zmdi-var-folder-outline": "\u{f224}",
            "zmdi-var-folder-person": "\u{f225}",
            "zmdi-var-folder-star-alt": "\u{f226}",
            "zmdi-var-folder-star": "\u{f227}",
            "zmdi-var-folder": "\u{f228}",
            "zmdi-var-gif": "\u{f229}",
            "zmdi-var-upload": "\u{f22a}",
            "zmdi-var-border-all": "\u{f22b}",
            "zmdi-var-border-bottom": "\u{f22c}",
            "zmdi-var-border-clear": "\u{f22d}",
            "zmdi-var-border-color": "\u{f22e}",
            "zmdi-var-border-horizontal": "\u{f22f}",
            "zmdi-var-border-inner": "\u{f230}",
            "zmdi-var-border-left": "\u{f231}",
            "zmdi-var-border-outer": "\u{f232}",
            "zmdi-var-border-right": "\u{f233}",
            "zmdi-var-border-style": "\u{f234}",
            "zmdi-var-border-top": "\u{f235}",
            "zmdi-var-border-vertical": "\u{f236}",
            "zmdi-var-copy": "\u{f237}",
            "zmdi-var-crop": "\u{f238}",
            "zmdi-var-format-align-center": "\u{f239}",
            "zmdi-var-format-align-justify": "\u{f23a}",
            "zmdi-var-format-align-left": "\u{f23b}",
            "zmdi-var-format-align-right": "\u{f23c}",
            "zmdi-var-format-bold": "\u{f23d}",
            "zmdi-var-format-clear-all": "\u{f23e}",
            "zmdi-var-format-clear": "\u{f23f}",
            "zmdi-var-format-color-fill": "\u{f240}",
            "zmdi-var-format-color-reset": "\u{f241}",
            "zmdi-var-format-color-text": "\u{f242}",
            "zmdi-var-format-indent-decrease": "\u{f243}",
            "zmdi-var-format-indent-increase": "\u{f244}",
            "zmdi-var-format-italic": "\u{f245}",
            "zmdi-var-format-line-spacing": "\u{f246}",
            "zmdi-var-format-list-bulleted": "\u{f247}",
            "zmdi-var-format-list-numbered": "\u{f248}",
            "zmdi-var-format-ltr": "\u{f249}",
            "zmdi-var-format-rtl": "\u{f24a}",
            "zmdi-var-format-size": "\u{f24b}",
            "zmdi-var-format-strikethrough-s": "\u{f24c}",
            "zmdi-var-format-strikethrough": "\u{f24d}",
            "zmdi-var-format-subject": "\u{f24e}",
            "zmdi-var-format-underlined": "\u{f24f}",
            "zmdi-var-format-valign-bottom": "\u{f250}",
            "zmdi-var-format-valign-center": "\u{f251}",
            "zmdi-var-format-valign-top": "\u{f252}",
            "zmdi-var-redo": "\u{f253}",
            "zmdi-var-select-all": "\u{f254}",
            "zmdi-var-space-bar": "\u{f255}",
            "zmdi-var-text-format": "\u{f256}",
            "zmdi-var-transform": "\u{f257}",
            "zmdi-var-undo": "\u{f258}",
            "zmdi-var-wrap-text": "\u{f259}",
            "zmdi-var-comment-alert": "\u{f25a}",
            "zmdi-var-comment-alt-text": "\u{f25b}",
            "zmdi-var-comment-alt": "\u{f25c}",
            "zmdi-var-comment-edit": "\u{f25d}",
            "zmdi-var-comment-image": "\u{f25e}",
            "zmdi-var-comment-list": "\u{f25f}",
            "zmdi-var-comment-more": "\u{f260}",
            "zmdi-var-comment-outline": "\u{f261}",
            "zmdi-var-comment-text-alt": "\u{f262}",
            "zmdi-var-comment-text": "\u{f263}",
            "zmdi-var-comment-video": "\u{f264}",
            "zmdi-var-comment": "\u{f265}",
            "zmdi-var-comments": "\u{f266}",
            "zmdi-var-check-all": "\u{f267}",
            "zmdi-var-check-circle-u": "\u{f268}",
            "zmdi-var-check-circle": "\u{f269}",
            "zmdi-var-check-square": "\u{f26a}",
            "zmdi-var-check": "\u{f26b}",
            "zmdi-var-circle-o": "\u{f26c}",
            "zmdi-var-circle": "\u{f26d}",
            "zmdi-var-dot-circle-alt": "\u{f26e}",
            "zmdi-var-dot-circle": "\u{f26f}",
            "zmdi-var-minus-circle-outline": "\u{f270}",
            "zmdi-var-minus-circle": "\u{f271}",
            "zmdi-var-minus-square": "\u{f272}",
            "zmdi-var-minus": "\u{f273}",
            "zmdi-var-plus-circle-o-duplicate": "\u{f274}",
            "zmdi-var-plus-circle-o": "\u{f275}",
            "zmdi-var-plus-circle": "\u{f276}",
            "zmdi-var-plus-square": "\u{f277}",
            "zmdi-var-plus": "\u{f278}",
            "zmdi-var-square-o": "\u{f279}",
            "zmdi-var-star-circle": "\u{f27a}",
            "zmdi-var-star-half": "\u{f27b}",
            "zmdi-var-star-outline": "\u{f27c}",
            "zmdi-var-star": "\u{f27d}",
            "zmdi-var-bluetooth-connected": "\u{f27e}",
            "zmdi-var-bluetooth-off": "\u{f27f}",
            "zmdi-var-bluetooth-search": "\u{f280}",
            "zmdi-var-bluetooth-setting": "\u{f281}",
            "zmdi-var-bluetooth": "\u{f282}",
            "zmdi-var-camera-add": "\u{f283}",
            "zmdi-var-camera-alt": "\u{f284}",
            "zmdi-var-camera-bw": "\u{f285}",
            "zmdi-var-camera-front": "\u{f286}",
            "zmdi-var-camera-mic": "\u{f287}",
            "zmdi-var-camera-party-mode": "\u{f288}",
            "zmdi-var-camera-rear": "\u{f289}",
            "zmdi-var-camera-roll": "\u{f28a}",
            "zmdi-var-camera-switch": "\u{f28b}",
            "zmdi-var-camera": "\u{f28c}",
            "zmdi-var-card-alert": "\u{f28d}",
            "zmdi-var-card-off": "\u{f28e}",
            "zmdi-var-card-sd": "\u{f28f}",
            "zmdi-var-card-sim": "\u{f290}",
            "zmdi-var-desktop-mac": "\u{f291}",
            "zmdi-var-desktop-windows": "\u{f292}",
            "zmdi-var-device-hub": "\u{f293}",
            "zmdi-var-devices-off": "\u{f294}",
            "zmdi-var-devices": "\u{f295}",
            "zmdi-var-dock": "\u{f296}",
            "zmdi-var-floppy": "\u{f297}",
            "zmdi-var-gamepad": "\u{f298}",
            "zmdi-var-gps-dot": "\u{f299}",
            "zmdi-var-gps-off": "\u{f29a}",
            "zmdi-var-gps": "\u{f29b}",
            "zmdi-var-headset-mic": "\u{f29c}",
            "zmdi-var-headset": "\u{f29d}",
            "zmdi-var-input-antenna": "\u{f29e}",
            "zmdi-var-input-composite": "\u{f29f}",
            "zmdi-var-input-hdmi": "\u{f2a0}",
            "zmdi-var-input-power": "\u{f2a1}",
            "zmdi-var-input-svideo": "\u{f2a2}",
            "zmdi-var-keyboard-hide": "\u{f2a3}",
            "zmdi-var-keyboard": "\u{f2a4}",
            "zmdi-var-laptop-chromebook": "\u{f2a5}",
            "zmdi-var-laptop-mac": "\u{f2a6}",
            "zmdi-var-laptop": "\u{f2a7}",
            "zmdi-var-mic-off": "\u{f2a8}",
            "zmdi-var-mic-outline": "\u{f2a9}",
            "zmdi-var-mic-setting": "\u{f2aa}",
            "zmdi-var-mic": "\u{f2ab}",
            "zmdi-var-mouse": "\u{f2ac}",
            "zmdi-var-network-alert": "\u{f2ad}",
            "zmdi-var-network-locked": "\u{f2ae}",
            "zmdi-var-network-off": "\u{f2af}",
            "zmdi-var-network-outline": "\u{f2b0}",
            "zmdi-var-network-setting": "\u{f2b1}",
            "zmdi-var-network": "\u{f2b2}",
            "zmdi-var-phone-bluetooth": "\u{f2b3}",
            "zmdi-var-phone-end": "\u{f2b4}",
            "zmdi-var-phone-forwarded": "\u{f2b5}",
            "zmdi-var-phone-in-talk": "\u{f2b6}",
            "zmdi-var-phone-locked": "\u{f2b7}",
            "zmdi-var-phone-missed": "\u{f2b8}",
            "zmdi-var-phone-msg": "\u{f2b9}",
            "zmdi-var-phone-paused": "\u{f2ba}",
            "zmdi-var-phone-ring": "\u{f2bb}",
            "zmdi-var-phone-setting": "\u{f2bc}",
            "zmdi-var-phone-sip": "\u{f2bd}",
            "zmdi-var-phone": "\u{f2be}",
            "zmdi-var-portable-wifi-changes": "\u{f2bf}",
            "zmdi-var-portable-wifi-off": "\u{f2c0}",
            "zmdi-var-portable-wifi": "\u{f2c1}",
            "zmdi-var-radio": "\u{f2c2}",
            "zmdi-var-reader": "\u{f2c3}",
            "zmdi-var-remote-control-alt": "\u{f2c4}",
            "zmdi-var-remote-control": "\u{f2c5}",
            "zmdi-var-router": "\u{f2c6}",
            "zmdi-var-scanner": "\u{f2c7}",
            "zmdi-var-smartphone-android": "\u{f2c8}",
            "zmdi-var-smartphone-download": "\u{f2c9}",
            "zmdi-var-smartphone-erase": "\u{f2ca}",
            "zmdi-var-smartphone-info": "\u{f2cb}",
            "zmdi-var-smartphone-iphone": "\u{f2cc}",
            "zmdi-var-smartphone-landscape-lock": "\u{f2cd}",
            "zmdi-var-smartphone-landscape": "\u{f2ce}",
            "zmdi-var-smartphone-lock": "\u{f2cf}",
            "zmdi-var-smartphone-portrait-lock": "\u{f2d0}",
            "zmdi-var-smartphone-ring": "\u{f2d1}",
            "zmdi-var-smartphone-setting": "\u{f2d2}",
            "zmdi-var-smartphone-setup": "\u{f2d3}",
            "zmdi-var-smartphone": "\u{f2d4}",
            "zmdi-var-speaker": "\u{f2d5}",
            "zmdi-var-tablet-android": "\u{f2d6}",
            "zmdi-var-tablet-mac": "\u{f2d7}",
            "zmdi-var-tablet": "\u{f2d8}",
            "zmdi-var-tv-alt-play": "\u{f2d9}",
            "zmdi-var-tv-list": "\u{f2da}",
            "zmdi-var-tv-play": "\u{f2db}",
            "zmdi-var-tv": "\u{f2dc}",
            "zmdi-var-usb": "\u{f2dd}",
            "zmdi-var-videocam-off": "\u{f2de}",
            "zmdi-var-videocam-switch": "\u{f2df}",
            "zmdi-var-videocam": "\u{f2e0}",
            "zmdi-var-watch": "\u{f2e1}",
            "zmdi-var-wifi-alt-2": "\u{f2e2}",
            "zmdi-var-wifi-alt": "\u{f2e3}",
            "zmdi-var-wifi-info": "\u{f2e4}",
            "zmdi-var-wifi-lock": "\u{f2e5}",
            "zmdi-var-wifi-off": "\u{f2e6}",
            "zmdi-var-wifi-outline": "\u{f2e7}",
            "zmdi-var-wifi": "\u{f2e8}",
            "zmdi-var-arrow-left-bottom": "\u{f2e9}",
            "zmdi-var-arrow-left": "\u{f2ea}",
            "zmdi-var-arrow-merge": "\u{f2eb}",
            "zmdi-var-arrow-missed": "\u{f2ec}",
            "zmdi-var-arrow-right-top": "\u{f2ed}",
            "zmdi-var-arrow-right": "\u{f2ee}",
            "zmdi-var-arrow-split": "\u{f2ef}",
            "zmdi-var-arrows": "\u{f2f0}",
            "zmdi-var-caret-down-circle": "\u{f2f1}",
            "zmdi-var-caret-down": "\u{f2f2}",
            "zmdi-var-caret-left-circle": "\u{f2f3}",
            "zmdi-var-caret-left": "\u{f2f4}",
            "zmdi-var-caret-right-circle": "\u{f2f5}",
            "zmdi-var-caret-right": "\u{f2f6}",
            "zmdi-var-caret-up-circle": "\u{f2f7}",
            "zmdi-var-caret-up": "\u{f2f8}",
            "zmdi-var-chevron-down": "\u{f2f9}",
            "zmdi-var-chevron-left": "\u{f2fa}",
            "zmdi-var-chevron-right": "\u{f2fb}",
            "zmdi-var-chevron-up": "\u{f2fc}",
            "zmdi-var-forward": "\u{f2fd}",
            "zmdi-var-long-arrow-down": "\u{f2fe}",
            "zmdi-var-long-arrow-left": "\u{f2ff}",
            "zmdi-var-long-arrow-return": "\u{f300}",
            "zmdi-var-long-arrow-right": "\u{f301}",
            "zmdi-var-long-arrow-tab": "\u{f302}",
            "zmdi-var-long-arrow-up": "\u{f303}",
            "zmdi-var-rotate-ccw": "\u{f304}",
            "zmdi-var-rotate-cw": "\u{f305}",
            "zmdi-var-rotate-left": "\u{f306}",
            "zmdi-var-rotate-right": "\u{f307}",
            "zmdi-var-square-down": "\u{f308}",
            "zmdi-var-square-right": "\u{f309}",
            "zmdi-var-swap-alt": "\u{f30a}",
            "zmdi-var-swap-vertical-circle": "\u{f30b}",
            "zmdi-var-swap-vertical": "\u{f30c}",
            "zmdi-var-swap": "\u{f30d}",
            "zmdi-var-trending-down": "\u{f30e}",
            "zmdi-var-trending-flat": "\u{f30f}",
            "zmdi-var-trending-up": "\u{f310}",
            "zmdi-var-unfold-less": "\u{f311}",
            "zmdi-var-unfold-more": "\u{f312}",
            "zmdi-var-apps": "\u{f313}",
            "zmdi-var-grid-off": "\u{f314}",
            "zmdi-var-grid": "\u{f315}",
            "zmdi-var-view-agenda": "\u{f316}",
            "zmdi-var-view-array": "\u{f317}",
            "zmdi-var-view-carousel": "\u{f318}",
            "zmdi-var-view-column": "\u{f319}",
            "zmdi-var-view-comfy": "\u{f31a}",
            "zmdi-var-view-compact": "\u{f31b}",
            "zmdi-var-view-dashboard": "\u{f31c}",
            "zmdi-var-view-day": "\u{f31d}",
            "zmdi-var-view-headline": "\u{f31e}",
            "zmdi-var-view-list-alt": "\u{f31f}",
            "zmdi-var-view-list": "\u{f320}",
            "zmdi-var-view-module": "\u{f321}",
            "zmdi-var-view-quilt": "\u{f322}",
            "zmdi-var-view-stream": "\u{f323}",
            "zmdi-var-view-subtitles": "\u{f324}",
            "zmdi-var-view-toc": "\u{f325}",
            "zmdi-var-view-web": "\u{f326}",
            "zmdi-var-view-week": "\u{f327}",
            "zmdi-var-widgets": "\u{f328}",
            "zmdi-var-alarm-check": "\u{f329}",
            "zmdi-var-alarm-off": "\u{f32a}",
            "zmdi-var-alarm-plus": "\u{f32b}",
            "zmdi-var-alarm-snooze": "\u{f32c}",
            "zmdi-var-alarm": "\u{f32d}",
            "zmdi-var-calendar-alt": "\u{f32e}",
            "zmdi-var-calendar-check": "\u{f32f}",
            "zmdi-var-calendar-close": "\u{f330}",
            "zmdi-var-calendar-note": "\u{f331}",
            "zmdi-var-calendar": "\u{f332}",
            "zmdi-var-time-countdown": "\u{f333}",
            "zmdi-var-time-interval": "\u{f334}",
            "zmdi-var-time-restore-setting": "\u{f335}",
            "zmdi-var-time-restore": "\u{f336}",
            "zmdi-var-time": "\u{f337}",
            "zmdi-var-timer-off": "\u{f338}",
            "zmdi-var-timer": "\u{f339}",
            "zmdi-var-android-alt": "\u{f33a}",
            "zmdi-var-android": "\u{f33b}",
            "zmdi-var-apple": "\u{f33c}",
            "zmdi-var-behance": "\u{f33d}",
            "zmdi-var-codepen": "\u{f33e}",
            "zmdi-var-dribbble": "\u{f33f}",
            "zmdi-var-dropbox": "\u{f340}",
            "zmdi-var-evernote": "\u{f341}",
            "zmdi-var-facebook-box": "\u{f342}",
            "zmdi-var-facebook": "\u{f343}",
            "zmdi-var-github-box": "\u{f344}",
            "zmdi-var-github": "\u{f345}",
            "zmdi-var-google-drive": "\u{f346}",
            "zmdi-var-google-earth": "\u{f347}",
            "zmdi-var-google-glass": "\u{f348}",
            "zmdi-var-google-maps": "\u{f349}",
            "zmdi-var-google-pages": "\u{f34a}",
            "zmdi-var-google-play": "\u{f34b}",
            "zmdi-var-google-plus-box": "\u{f34c}",
            "zmdi-var-google-plus": "\u{f34d}",
            "zmdi-var-google": "\u{f34e}",
            "zmdi-var-instagram": "\u{f34f}",
            "zmdi-var-language-css3": "\u{f350}",
            "zmdi-var-language-html5": "\u{f351}",
            "zmdi-var-language-javascript": "\u{f352}",
            "zmdi-var-language-python-alt": "\u{f353}",
            "zmdi-var-language-python": "\u{f354}",
            "zmdi-var-lastfm": "\u{f355}",
            "zmdi-var-linkedin-box": "\u{f356}",
            "zmdi-var-paypal": "\u{f357}",
            "zmdi-var-pinterest-box": "\u{f358}",
            "zmdi-var-pocket": "\u{f359}",
            "zmdi-var-polymer": "\u{f35a}",
            "zmdi-var-share": "\u{f35b}",
            "zmdi-var-stack-overflow": "\u{f35c}",
            "zmdi-var-steam-square": "\u{f35d}",
            "zmdi-var-steam": "\u{f35e}",
            "zmdi-var-twitter-box": "\u{f35f}",
            "zmdi-var-twitter": "\u{f360}",
            "zmdi-var-vk": "\u{f361}",
            "zmdi-var-wikipedia": "\u{f362}",
            "zmdi-var-windows": "\u{f363}",
            "zmdi-var-aspect-ratio-alt": "\u{f364}",
            "zmdi-var-aspect-ratio": "\u{f365}",
            "zmdi-var-blur-circular": "\u{f366}",
            "zmdi-var-blur-linear": "\u{f367}",
            "zmdi-var-blur-off": "\u{f368}",
            "zmdi-var-blur": "\u{f369}",
            "zmdi-var-brightness-2": "\u{f36a}",
            "zmdi-var-brightness-3": "\u{f36b}",
            "zmdi-var-brightness-4": "\u{f36c}",
            "zmdi-var-brightness-5": "\u{f36d}",
            "zmdi-var-brightness-6": "\u{f36e}",
            "zmdi-var-brightness-7": "\u{f36f}",
            "zmdi-var-brightness-auto": "\u{f370}",
            "zmdi-var-brightness-setting": "\u{f371}",
            "zmdi-var-broken-image": "\u{f372}",
            "zmdi-var-center-focus-strong": "\u{f373}",
            "zmdi-var-center-focus-weak": "\u{f374}",
            "zmdi-var-compare": "\u{f375}",
            "zmdi-var-crop-16-9": "\u{f376}",
            "zmdi-var-crop-3-2": "\u{f377}",
            "zmdi-var-crop-5-4": "\u{f378}",
            "zmdi-var-crop-7-5": "\u{f379}",
            "zmdi-var-crop-din": "\u{f37a}",
            "zmdi-var-crop-free": "\u{f37b}",
            "zmdi-var-crop-landscape": "\u{f37c}",
            "zmdi-var-crop-portrait": "\u{f37d}",
            "zmdi-var-crop-square": "\u{f37e}",
            "zmdi-var-exposure-alt": "\u{f37f}",
            "zmdi-var-exposure": "\u{f380}",
            "zmdi-var-filter-b-and-w": "\u{f381}",
            "zmdi-var-filter-center-focus": "\u{f382}",
            "zmdi-var-filter-frames": "\u{f383}",
            "zmdi-var-filter-tilt-shift": "\u{f384}",
            "zmdi-var-gradient": "\u{f385}",
            "zmdi-var-grain": "\u{f386}",
            "zmdi-var-graphic-eq": "\u{f387}",
            "zmdi-var-hdr-off": "\u{f388}",
            "zmdi-var-hdr-strong": "\u{f389}",
            "zmdi-var-hdr-weak": "\u{f38a}",
            "zmdi-var-hdr": "\u{f38b}",
            "zmdi-var-iridescent": "\u{f38c}",
            "zmdi-var-leak-off": "\u{f38d}",
            "zmdi-var-leak": "\u{f38e}",
            "zmdi-var-looks": "\u{f38f}",
            "zmdi-var-loupe": "\u{f390}",
            "zmdi-var-panorama-horizontal": "\u{f391}",
            "zmdi-var-panorama-vertical": "\u{f392}",
            "zmdi-var-panorama-wide-angle": "\u{f393}",
            "zmdi-var-photo-size-select-large": "\u{f394}",
            "zmdi-var-photo-size-select-small": "\u{f395}",
            "zmdi-var-picture-in-picture": "\u{f396}",
            "zmdi-var-slideshow": "\u{f397}",
            "zmdi-var-texture": "\u{f398}",
            "zmdi-var-tonality": "\u{f399}",
            "zmdi-var-vignette": "\u{f39a}",
            "zmdi-var-wb-auto": "\u{f39b}",
            "zmdi-var-eject-alt": "\u{f39c}",
            "zmdi-var-eject": "\u{f39d}",
            "zmdi-var-equalizer": "\u{f39e}",
            "zmdi-var-fast-forward": "\u{f39f}",
            "zmdi-var-fast-rewind": "\u{f3a0}",
            "zmdi-var-forward-10": "\u{f3a1}",
            "zmdi-var-forward-30": "\u{f3a2}",
            "zmdi-var-forward-5": "\u{f3a3}",
            "zmdi-var-hearing": "\u{f3a4}",
            "zmdi-var-pause-circle-outline": "\u{f3a5}",
            "zmdi-var-pause-circle": "\u{f3a6}",
            "zmdi-var-pause": "\u{f3a7}",
            "zmdi-var-play-circle-outline": "\u{f3a8}",
            "zmdi-var-play-circle": "\u{f3a9}",
            "zmdi-var-play": "\u{f3aa}",
            "zmdi-var-playlist-audio": "\u{f3ab}",
            "zmdi-var-playlist-plus": "\u{f3ac}",
            "zmdi-var-repeat-one": "\u{f3ad}",
            "zmdi-var-repeat": "\u{f3ae}",
            "zmdi-var-replay-10": "\u{f3af}",
            "zmdi-var-replay-30": "\u{f3b0}",
            "zmdi-var-replay-5": "\u{f3b1}",
            "zmdi-var-replay": "\u{f3b2}",
            "zmdi-var-shuffle": "\u{f3b3}",
            "zmdi-var-skip-next": "\u{f3b4}",
            "zmdi-var-skip-previous": "\u{f3b5}",
            "zmdi-var-stop": "\u{f3b6}",
            "zmdi-var-surround-sound": "\u{f3b7}",
            "zmdi-var-tune": "\u{f3b8}",
            "zmdi-var-volume-down": "\u{f3b9}",
            "zmdi-var-volume-mute": "\u{f3ba}",
            "zmdi-var-volume-off": "\u{f3bb}",
            "zmdi-var-volume-up": "\u{f3bc}",
            "zmdi-var-n-1-square": "\u{f3bd}",
            "zmdi-var-n-2-square": "\u{f3be}",
            "zmdi-var-n-3-square": "\u{f3bf}",
            "zmdi-var-n-4-square": "\u{f3c0}",
            "zmdi-var-n-5-square": "\u{f3c1}",
            "zmdi-var-n-6-square": "\u{f3c2}",
            "zmdi-var-neg-1": "\u{f3c3}",
            "zmdi-var-neg-2": "\u{f3c4}",
            "zmdi-var-plus-1": "\u{f3c5}",
            "zmdi-var-plus-2": "\u{f3c6}",
            "zmdi-var-sec-10": "\u{f3c7}",
            "zmdi-var-sec-3": "\u{f3c8}",
            "zmdi-var-zero": "\u{f3c9}",
            "zmdi-var-airline-seat-flat-angled": "\u{f3ca}",
            "zmdi-var-airline-seat-flat": "\u{f3cb}",
            "zmdi-var-airline-seat-individual-suite": "\u{f3cc}",
            "zmdi-var-airline-seat-legroom-extra": "\u{f3cd}",
            "zmdi-var-airline-seat-legroom-normal": "\u{f3ce}",
            "zmdi-var-airline-seat-legroom-reduced": "\u{f3cf}",
            "zmdi-var-airline-seat-recline-extra": "\u{f3d0}",
            "zmdi-var-airline-seat-recline-normal": "\u{f3d1}",
            "zmdi-var-airplay": "\u{f3d2}",
            "zmdi-var-closed-caption": "\u{f3d3}",
            "zmdi-var-confirmation-number": "\u{f3d4}",
            "zmdi-var-developer-board": "\u{f3d5}",
            "zmdi-var-disc-full": "\u{f3d6}",
            "zmdi-var-explicit": "\u{f3d7}",
            "zmdi-var-flight-land": "\u{f3d8}",
            "zmdi-var-flight-takeoff": "\u{f3d9}",
            "zmdi-var-flip-to-back": "\u{f3da}",
            "zmdi-var-flip-to-front": "\u{f3db}",
            "zmdi-var-group-work": "\u{f3dc}",
            "zmdi-var-hd": "\u{f3dd}",
            "zmdi-var-hq": "\u{f3de}",
            "zmdi-var-markunread-mailbox": "\u{f3df}",
            "zmdi-var-memory": "\u{f3e0}",
            "zmdi-var-nfc": "\u{f3e1}",
            "zmdi-var-play-for-work": "\u{f3e2}",
            "zmdi-var-power-input": "\u{f3e3}",
            "zmdi-var-present-to-all": "\u{f3e4}",
            "zmdi-var-satellite": "\u{f3e5}",
            "zmdi-var-tap-and-play": "\u{f3e6}",
            "zmdi-var-vibration": "\u{f3e7}",
            "zmdi-var-voicemail": "\u{f3e8}"
        ]
    }
}
