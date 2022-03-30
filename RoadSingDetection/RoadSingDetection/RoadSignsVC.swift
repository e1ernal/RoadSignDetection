//
//  RoadSignsVC.swift
//  RoadSingDetection
//
//  Created by Dmitry Smirnykh on 23.07.2021.
//

import Foundation
import UIKit

class RoadSignsVC : UIViewController, UINavigationControllerDelegate{
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var image5: UIImageView!
    
    override func viewDidLoad() {
        self.image1.image = UIImage(named: "IMG_3177")
        self.image2.image = UIImage(named: "IMG_3178")
        self.image3.image = UIImage(named: "IMG_3179")
        self.image4.image = UIImage(named: "IMG_3180")
        self.image5.image = UIImage(named: "IMG_3181")
    }
    
}
