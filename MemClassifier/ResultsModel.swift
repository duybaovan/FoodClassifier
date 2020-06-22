//
//  ResultsModel.swift
//  MemClassifier
//
//  Created by Bao Van on 6/20/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import Foundation
import UIKit

class ResultsModel {
    var image: UIImage
    var predictionClass: String
    
    init(fromImage image: UIImage, withPredictionClass predictionClass: String) {
        self.image = image
        self.predictionClass = predictionClass
    }
}
