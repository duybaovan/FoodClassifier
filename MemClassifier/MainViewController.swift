//
//  MainViewController.swift
//  MemClassifier
//
//  Created by Bao Van on 6/16/20.
//  Copyright © 2020 Bao Van. All rights reserved.
//

import UIKit
import Vision
import CoreML
import ImageIO
import ImagePicker


class MainViewController: UIViewController, ImagePickerDelegate {
    let imagePickerController = ImagePickerController()
    var images = [UIImage]()
    var imageLabels: [String] = ["tacos","pho","salad","poke"]
    var savedFoods: [FoodModel] = [FoodModel]()
    var currImageIndex = 0
    var currPrediction = ""
    var currConfidence = 0
    let MAX_SELECTION_ALLOWED = 5
    
    @IBOutlet weak var saveThisFoodButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBAction func classifyDidPress(_ sender: Any) {
        updateClassifications(for: self.imageView.image!)
        saveThisFoodButton.isHidden = false
    }
    @IBAction func chooseImagesButtonClicked(_ sender: UIButton) {
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func saveFoodsDidPress(_ sender: Any) {
        if(images.count == 0) {return}
        let firstline = predictionLabel.text?.split(separator: "\n")[0]
        let prediction = firstline!.split(separator: " ")
        let confidence = prediction[0]
        let label = prediction[prediction.count - 1]
        savedFoods.append(FoodModel(forImage: imageView.image!, withPrediction: String(label), withConfidence: String(confidence)))
        print(savedFoods)
    }
    
    func newPicShown(){
        imageView.image = images[currImageIndex]
        updateClassifications(for: self.imageView.image!)
    }
    
    @IBAction func leftDidPress(_ sender: Any) {
        if(currImageIndex == 0){
            currImageIndex = images.count - 1
        }
        else{
            currImageIndex = currImageIndex - 1
        }
        newPicShown()
    }
    @IBAction func rightDidPress(_ sender: Any) {
        if(currImageIndex == images.count - 1){
            currImageIndex = 0
        }
        else{
            currImageIndex = currImageIndex + 1
        }
        newPicShown()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "food_gallery"){
            if let destinationVC = segue.destination as? ScanResultsViewController {
                destinationVC.savedFoods = savedFoods
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for label in imageLabels{
            images.append(UIImage(named: label)!)
        }
        imageView.layer.borderWidth = 1
        imageView.image = images[currImageIndex]
        imagePickerController.delegate = self
        saveThisFoodButton.isHidden = true
        imagePickerController.imageLimit = MAX_SELECTION_ALLOWED

        // Do any additional setup after loading the view.
    }
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        return
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.images = images
        currImageIndex = 0
        imageView.image = images[currImageIndex]
        predictionLabel.text = "click classify"
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
   
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    var model = Food101()
    
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             Use the Swift class `MobileNet` Core ML generates from the model.
             To use a different Core ML classifier model, add it to the project
             and replace `MobileNet` with that model's generated Swift class.
             */
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
        predictionLabel.text = "Classifying..."
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
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.predictionLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.predictionLabel.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "%.2f percent confident it's %@", classification.confidence*100, classification.identifier)
                }
                
                self.predictionLabel.text = descriptions.joined(separator: "\n")
            }
        }
    }
    
    
    
    func sceneLabel (forImage image: UIImage) -> String? {
        if let pixelBuffer = ImageProcessor.pixelBuffer(forImage: image.cgImage!){
            guard let scene = try? model.prediction(image: pixelBuffer) else {
                fatalError("unexpected")
            }
            return scene.classLabel
        }
        return nil
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        updateClassifications(for: imageView.image!)
        dismiss(animated: true, completion: nil)
    }

}

