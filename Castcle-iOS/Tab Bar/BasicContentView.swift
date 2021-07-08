//
//  BasicContentView.swift
//  Castcle-iOS
//
//  Created by Tanakorn Phoochaliaw on 8/7/2564 BE.
//

import UIKit
import Core
import ESTabBarController

class BasicContentView: ESTabBarItemContentView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        textColor = UIColor.Asset.white
        highlightTextColor = UIColor.Asset.lightBlue
        iconColor = UIColor.Asset.white
        highlightIconColor = UIColor.Asset.lightBlue
        backdropColor = UIColor.Asset.darkGraphiteBlue
        highlightBackdropColor = UIColor.Asset.darkGraphiteBlue
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
