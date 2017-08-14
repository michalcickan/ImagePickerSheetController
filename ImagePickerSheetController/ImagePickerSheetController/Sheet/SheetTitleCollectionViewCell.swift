//
//  SheetTitleCollectionViewCell.swift
//  Pods
//
//  Created by Michal Čičkán on 28/07/16.
//
//

import UIKit

class SheetTitleCollectionViewCell: SheetCollectionViewCell {
    var titleLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        titleLabel.textColor = UIColor(red: 143/255, green: 142/255,blue: 148/255, alpha: 1)
        titleLabel.textAlignment = .center
        
        self.addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.frame = self.bounds
    }
}
