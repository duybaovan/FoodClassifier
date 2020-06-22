//
//  ResultsTableViewCell.swift
//  MemClassifier
//
//  Created by Bao Van on 6/18/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import UIKit

class ResultsTableViewCell: UITableViewCell {

    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setCell(image: UIImage, text: String){
        label.text = text
        imageview.image = image
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
