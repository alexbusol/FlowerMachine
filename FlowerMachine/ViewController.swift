//
//  ViewController.swift
//  FlowerMachine
//
//  Created by Alex Busol on 7/12/18.
//  Copyright © 2018 Alex Busol. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false //change to true to allow users to edit their images
        imagePicker.sourceType = .photoLibrary  //change to .camera to allow picking images directly from camera
        
        
        
    }
    //triggers after user selected the image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage { //change to uiimagepickercontroller edited image if allows editing is true.
            imageView.image = pickedImage
            guard let ciImage = CIImage(image: pickedImage) else {
                fatalError("Cannot convert to CIImage")
            } //convert for the detectFlower method
            
            detectFlower(image: ciImage)
        }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    //will use machine learning to classify the image passed from the Image Picker
    func detectFlower(image: CIImage) {
        guard let mlModel = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")
        }
        
        let mlRequest = VNCoreMLRequest(model: mlModel) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            self.navigationItem.title = classification?.identifier
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: image)
        do {
            try requestHandler.perform([mlRequest])
        } catch {
            print("error requesting from the ml model \(error)")
        }
        
    }

    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

