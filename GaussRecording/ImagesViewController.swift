//
//  ImagesViewController.swift
//  GaussRecording
//
//  Created by Utsha Guha on 8/25/20.
//  Copyright © 2020 Gauss. All rights reserved.
//

import Foundation
import UIKit

class ImagesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:ImagesCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagesCell", for: indexPath) as! ImagesCollectionViewCell
        let currentImage = finalImages[indexPath.row]["Image"] as! UIImage
        let currentState = finalImages[indexPath.row]["Selected"] as! Bool
        
        cell.mainImageView.image = currentImage
        cell.tickImageView.image = (currentState == true) ? UIImage(named:"Tick") : nil
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentState = finalImages[indexPath.row]["Selected"] as! Bool
        finalImages[indexPath.row] = ["Image":finalImages[indexPath.row]["Image"] as Any,"Selected":!currentState]
        
        let cell:ImagesCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ImagesCollectionViewCell
        cell.tickImageView.image = (!currentState == true) ? UIImage(named:"Tick") : nil
        reloadSaveToDisk()
    }
    
    var shortlistedImages:[UIImage] = []
    var finalImages:[[String:Any]] = []
    var selectedImages:[[String:Any]] = []
    @IBOutlet var saveToDiskButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("IMAGES ARE \(shortlistedImages)")
        saveToDiskButton.isEnabled = false
        saveToDiskButton.alpha = 0.5
        for image in shortlistedImages {
            finalImages.append(["Image":image,"Selected":false])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    
    func reloadSaveToDisk() {
        selectedImages = finalImages.filter({
            let isSelected = $0["Selected"] as! Bool
            return (isSelected == true)
        })
        saveToDiskButton.isEnabled = (selectedImages.count > 0)
        saveToDiskButton.alpha = (selectedImages.count > 0) ? 1.0 : 0.5
    }
    
    @IBAction func saveToDiskPressed(_ sender: Any) {
        saveToDiskButton.isEnabled = false
        saveToDiskButton.alpha = 0.5
        for (i,selectedItem) in selectedImages.enumerated() {
            let selectedImage:UIImage = selectedItem["Image"] as! UIImage
            if let data = selectedImage.pngData() {
                let filename = getDocumentsDirectory().appendingPathComponent("Image\(i+1)_\(Date()).png")
                try? data.write(to: filename)
                if i == selectedImages.count - 1 {
                    saveToDiskButton.isEnabled = true
                    saveToDiskButton.alpha = 1.0
                }
            }
        }
        
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}
