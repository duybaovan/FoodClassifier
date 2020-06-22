//
//  ResultCollectionViewCell.swift
//  MemClassifier
//
//  Created by Bao Van on 6/20/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import UIKit

class ResultCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.text = "null"
        // Initialization code
    }

}
