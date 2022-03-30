import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var photoImageView: UIImageView?
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var buttonNext: UIButton!
    
    
    @IBAction func buttonNextAction(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil)
        let controller = vc.instantiateViewController(identifier: "RoadSignsVC") as RoadSignsVC
        self.present(controller, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        let startimage = UIImage(named: "mlimage")
        self.photoImageView?.image = startimage
        let resultText = "Пока результатов нет"
        resultTextView.text = resultText
        button.layer.cornerRadius = button.frame.height / 2
        button.addTarget(self, action: #selector(buttonNextAction(_:)), for: .touchUpInside)
    }
    
    //Модуль ML обработки изображения
    lazy var detectionRequest: VNCoreMLRequest = {
        do {
            //Создание модели ML
            let model = try VNCoreMLModel(for: MyObjectDetector3().model)
            
            //Запрос в ML модуль и получение результата
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetections(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
            self.resultTextView.insertText("Failed to load Vision ML model: \(error)\n")
        }
    }()
    
    //Нажатие на кнопку
    @IBAction func testPhoto(sender: UIButton) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc, animated: true)
        
    }
    
    private func updateDetections(for image: UIImage) {
        
        //Подготовка нужного формата изображения
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
            self.resultTextView.insertText("Unable to create \(CIImage.self) from \(image).\n")
        }
        
        //Запрос для дальнейшей обработки изображения
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.detectionRequest])
            } catch {
                print("Failed to perform detection.\n\(error.localizedDescription)")
                self.resultTextView.insertText("Failed to perform detection.\n\(error.localizedDescription)\n")
            }
        }
    }
    
    //Процесс поиска объекта на изображении
    private func processDetections(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to detect anything.\n\(error!.localizedDescription)")
                self.resultTextView.insertText("Unable to detect anything.\n\(error!.localizedDescription)\n")
                return
            }
        
            let detections = results as! [VNRecognizedObjectObservation]
            self.drawDetectionsOnPreview(detections: detections)
        }
    }
    
    //Отрисовка прямоугольников для выделения найденных объектов
    func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]) {
        guard let image = self.photoImageView?.image else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        image.draw(at: CGPoint.zero)
        
        for detection in detections {
            self.resultTextView.insertText("✅")
            self.resultTextView.insertText(detection.labels.map(
                                            {"\($0.identifier) %: \(round(Double($0.confidence), toDecimalPlaces: 4))"}).joined(separator: "\n     "))
            self.resultTextView.insertText("\n\n")
            
            let boundingBox = detection.boundingBox
            let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
            UIColor(red: 0, green: 1, blue: 0, alpha: 0.4).setFill()
            UIRectFillUsingBlendMode(rectangle, CGBlendMode.normal)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.photoImageView?.image = newImage
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        self.resultTextView.text = nil
        self.photoImageView?.image = image
        updateDetections(for: image)
    }
}

func round(_ value: Double, toDecimalPlaces places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return round(value * divisor) / divisor
}
