//
//  FoodModel.swift
//  MemClassifier
//
//  Created by Bao Van on 6/22/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import Foundation
import UIKit

class FoodModel: CustomStringConvertible {
    var description: String
    var image: UIImage
    var confidence: String
    var prediction: String
    init(forImage image: UIImage, withPrediction prediction: String, withConfidence confidence: String) {
        self.image = image
        self.prediction = prediction
        self.confidence = confidence
        self.description = "Image with \(confidence) in \(prediction)"
    }
}
