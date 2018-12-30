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
import Alamofire //going to use this to pull information about the flowers from Wikipedia.
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaAPI = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        imageView.image = UIImage(named: "machine.png")
        
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        imagePicker.delegate = self
        imagePicker.allowsEditing = false //change to true to allow users to edit their images
        imagePicker.sourceType = .photoLibrary  //picking from the library if the image is tapped
        present(imagePicker, animated: true, completion: nil)

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
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Couldnt classify the image")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.requestWikipediaInfo(flowerName: classification.identifier) //passing the identified flower name into the wikipedia.
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: image)
        do {
            try requestHandler.perform([mlRequest])
        } catch {
            print("error requesting from the ml model \(error)")
        }
        
    }
    
    func requestWikipediaInfo(flowerName : String) {
        let parameters : [String : String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
        ]
        
        Alamofire.request(wikipediaAPI, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess { //got alomofire response from wikipedia. now need to parse it with swiftyJSON
                print("Wiki info received")
                print(response)
                
                let responseJSON : JSON = JSON(response.result.value!)
                let pageID = responseJSON["query"]["pageids"][0].stringValue //get the 0th object of the pageid
                //need to pass the key to pages in order to get the extract from the wikipedia
                
                let wikiDescription = responseJSON["query"]["pages"][pageID]["extract"].stringValue
                
                self.textLabel.text = wikiDescription
                
            }
        }
    }
    
    
    @IBOutlet weak var textLabel: UILabel!
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        imagePicker.delegate = self
        imagePicker.allowsEditing = false //change to true to allow users to edit their images
        imagePicker.sourceType = .camera  //change to .photoLibrary to allow picking images directly from camera
        present(imagePicker, animated: true, completion: nil)
    }
    
}

