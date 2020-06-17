//
//  ScanResultsViewController.swift
//  MemClassifier
//
//  Created by Bao Van on 6/17/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import UIKit
import Photos

class ScanResultsViewController: UIViewController {

    @IBOutlet weak var resultsLabel: UILabel!
    var images = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        getPhotos()
        // Do any additional setup after loading the view.
    }
    
    fileprivate func getPhotos() {

        _ = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        // .highQualityFormat will return better quality photos
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if results.count > 0 {
            for i in 0..<results.count {
                let asset = results.object(at: i)
                images.append(asset.image)
               
            }
        } else {
            print("no photos to display")
        }

    }
    

}
extension PHAsset {

    var image : UIImage {
        var thumbnail = UIImage()
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: self, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }
}

