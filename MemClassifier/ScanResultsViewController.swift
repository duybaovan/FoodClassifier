//
//  ScanResultsViewController.swift
//  MemClassifier
//
//  Created by Bao Van on 6/17/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import UIKit
import Photos
import Vision
import CoreML

class ScanResultsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var testImageView: UIImageView!
    var images = [UIImage]()
    var thumbnails = [UIImage]()
    
    var savedFoods = [FoodModel]()

    var doneClassifying = false
    let MAX_PHOTOS_SCANNED = 10
    var predictions = [String]()

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    func newPicShown(){
        if(savedFoods.count > 0){
            imageView.image = savedFoods[currImageIndex].image
            resultLabel.text = "click classify"
        }
    }
    
    @IBAction func rightDidPress(_ sender: Any) {
        if(currImageIndex == savedFoods.count - 1){
            currImageIndex = 0
        }
        else{
            currImageIndex = currImageIndex + 1
        }
        newPicShown()
    }
    @IBAction func leftDidPress(_ sender: Any) {
        if(currImageIndex == 0){
            currImageIndex = savedFoods.count - 1
        }
        else{
            currImageIndex = currImageIndex - 1
        }
        newPicShown()
    }
    @IBOutlet weak var imageView: UIImageView!
    var currImageIndex = 0
    
    @IBOutlet weak var resultLabel: UILabel!
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath) as! ResultCollectionViewCell
        cell.image.image = thumbnails[indexPath.row]
        if doneClassifying{
            cell.label.text = predictions[indexPath.row]
        }
        else{
            cell.label.text = ""
        }
        return cell
    }
    

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var resultsLabel: UILabel!
    var collectionViewFlowLayout: UICollectionViewFlowLayout!
    let cellIndentifier = "ResultCollectionViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        rightButton.isHidden = true
        leftButton.isHidden = true
        print(predictions.count)
        if(savedFoods.count > 0){
            imageView.image = savedFoods[currImageIndex].image
            resultLabel.text = savedFoods[currImageIndex].confidence + " " + savedFoods[currImageIndex].prediction
        }
        if(savedFoods.count > 1){
            rightButton.isHidden = false
            leftButton.isHidden = false
        }
        getPhotos()

        print(images)
        for i in 0..<images.count{
            updateClassifications(for: images[i])
        }
        setupCollectionView()
        print(savedFoods)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupCollectionViewItemSize()
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = UINib(nibName: "ResultCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIndentifier)
    }
    
    private func setupCollectionViewItemSize(){
        if collectionViewFlowLayout == nil {
            let numberOfItemForRow: CGFloat = 3
            let lineSpacing: CGFloat = 5
            let interItemSpacing: CGFloat = 5
            let frameWidth = collectionView.frame.width
            let width = (frameWidth - (numberOfItemForRow - 1) * interItemSpacing) / numberOfItemForRow
            let height = width
            collectionViewFlowLayout = UICollectionViewFlowLayout()
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
            collectionViewFlowLayout.sectionInset = UIEdgeInsets.zero
            collectionViewFlowLayout.scrollDirection = .vertical
            collectionViewFlowLayout.minimumInteritemSpacing = lineSpacing
            collectionViewFlowLayout.minimumInteritemSpacing = interItemSpacing
            collectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: true)
        }
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
                if (i >= MAX_PHOTOS_SCANNED) {
                    return
                }
                let asset = results.object(at: i)
                images.append(convertImageFromAsset(asset: asset))
                thumbnails.append(asset.image)
            }
        } else {
            print("no photos to display")
        }

    }
    
    func convertImageFromAsset(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var image = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: 299, height: 299), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            image = result!
        })
        return image
    }
    
    var currPredictionIndex = 0
    @IBOutlet weak var predictionLabel: UILabel!
    
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: Food101().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {
        let orientationNum: UInt32 = UInt32(image.imageOrientation.rawValue)
        let orientation = CGImagePropertyOrientation(rawValue: orientationNum)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }

    /// - Tag: PerformRequests
    
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            
            guard let results = request.results else {
                self.predictions.append("Unable to classify image.")
                    return
                }
                // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
                let classifications = results as! [VNClassificationObservation]
            
                if classifications.isEmpty {
                    self.predictions.append("Nothing recognized.")
                } else {
                    // Display top classifications ranked by confidence in the UI.
                    let topClassifications = classifications.prefix(1)
                    self.predictions.append(String(round(topClassifications[0].confidence*100)) + " "+topClassifications[0].identifier)
                }
            if(self.predictions.count == self.images.count){
                self.resultsLabel.text = "Done classifying"
                self.doneClassifying = true
                self.collectionView.reloadData()
            }
        }
    }
    

}
extension PHAsset {

    var image : UIImage {
        var thumbnail = UIImage()
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: self, targetSize: CGSize(width: 299, height: 299), contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }
}

