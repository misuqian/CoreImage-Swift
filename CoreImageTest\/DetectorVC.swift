//
//  DetectorVC.swift
//  CoreImageTest
//
//  Created by misupeng on 16/8/17.
//  Copyright © 2016年 misuqian. All rights reserved.
//

import UIKit
import CoreImage

//检测类型enum
enum DetectType : Int{
    case Face = 0
    case Rect
    case Text
    case QRC //QR code
}

//图像检测界面
class DetectorVC: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var type = DetectType.Face
    var isFirst = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch type {
        case .Face:
            self.imageView.image = UIImage(named: "jobs")
        case .QRC:
            self.imageView.image = UIImage(named: "qrc")
        case .Rect:
            self.imageView.image = UIImage(named: "rect")
        case .Text:
            self.imageView.image = UIImage(named: "text")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if isFirst{
            detect()
            isFirst = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //选择照片响应
    @IBAction func chooseImage(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let camera = UIAlertAction(title: "拍照", style: .Default, handler: { _ in
            let imageChooser = UIImagePickerController()
            imageChooser.delegate = self
            imageChooser.allowsEditing = false
            imageChooser.sourceType = .Camera
            MainThreadRun({
                self.presentViewController(imageChooser, animated: true, completion: nil)
            })
        })
        sheet.addAction(camera)
        
        let photo = UIAlertAction(title: "相册选取", style: .Default, handler: { _ in
            let imageChooser = UIImagePickerController()
            imageChooser.delegate = self
            imageChooser.allowsEditing = false
            imageChooser.sourceType = .PhotoLibrary
            MainThreadRun({
                self.presentViewController(imageChooser, animated: true, completion: nil)
            })
        })
        sheet.addAction(photo)
        
        let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: { _ in
            
        })
        sheet.addAction(cancel)
        
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.clearDetect()
        self.imageView.image = image
        self.detect()
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func detect(){
        switch type {
        case .QRC:
            self.navigationItem.title = "二维码检测"
            detect_qrc()
        case .Rect:
            self.navigationItem.title = "矩形检测"
            detect_rect()
        case .Text:
            self.navigationItem.title = "文字检测"
            detect_text()
        default:
            self.navigationItem.title = "人脸检测"
            detect_face()
        }
    }

    private func detect_face(){
        AsyncThreadRun({
            let option = [CIDetectorAccuracy:CIDetectorAccuracyHigh] //高准确度
            let dector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: option)
            if let cgImage : CGImage = self.imageView.image?.CGImage{
                let ciImage = CIImage(CGImage: cgImage)
                let results = dector.featuresInImage(ciImage)
                var text = ""
                for i in 0..<results.count{
                    let face = results[i] as! CIFaceFeature
                    self.addBoundsTip(face.bounds,inputImageSize: ciImage.extent.size)
                    if face.hasMouthPosition{
                        self.addBoundsTip(CGRect(origin: face.mouthPosition, size: CGSize(width: 10.0, height: 5.0)),inputImageSize: ciImage.extent.size)
                    }
                    if face.hasLeftEyePosition{
                        self.addBoundsTip(CGRect(origin: face.leftEyePosition, size: CGSize(width: 5.0, height: 5.0)),inputImageSize: ciImage.extent.size)
                    }
                    if face.hasRightEyePosition{
                        self.addBoundsTip(CGRect(origin: face.rightEyePosition, size: CGSize(width: 5.0, height: 5.0)),inputImageSize: ciImage.extent.size)
                    }
                    text += "【第\(i+1)张脸】\n"
                    text += "歪头:\(face.hasFaceAngle)\t微笑:\(face.hasSmile)\n左眼闭合:\(face.leftEyeClosed)\t右眼闭合:\(face.rightEyeClosed)\n"
                }
                if text == ""{
                    text = "无法检测"
                }
                MainThreadRun({
                    self.textView.text = text
                })
            }
        })
    }
    
    private func detect_rect(){
        AsyncThreadRun({
            let option = [CIDetectorAccuracy:CIDetectorAccuracyHigh] //高准确度
            let dector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: option)
            if let cgImage : CGImage = self.imageView.image?.CGImage{
                let ciImage = CIImage(CGImage: cgImage)
                let results = dector.featuresInImage(ciImage)
                var text = ""
                for i in 0..<results.count{
                    let rect = results[i] as! CIRectangleFeature
                    self.addBoundsTip(rect.bounds,inputImageSize: ciImage.extent.size)
                    text += "【第\(i+1)个矩形】\n"
                    text += "左下:\(rect.bottomLeft)\t右下:\(rect.bottomRight)\n左上:\(rect.topLeft)\t右上:\(rect.topRight)\n"
                }
                if text == ""{
                    text = "无法检测"
                }
                MainThreadRun({
                    self.textView.text = text
                })
            }
        })
    }
    
    private func detect_text(){
        AsyncThreadRun({
            let option = [CIDetectorAccuracy:CIDetectorAccuracyHigh] //高准确度
            if #available(iOS 9.0, *) {
                let dector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: option)
                if let cgImage : CGImage = self.imageView.image?.CGImage{
                    let ciImage = CIImage(CGImage: cgImage)
                    let results = dector.featuresInImage(ciImage)
                    var text = ""
                    for i in 0..<results.count{
                        let txt = results[i] as! CITextFeature
                        self.addBoundsTip(txt.bounds,inputImageSize: ciImage.extent.size)
                        text += "【第\(i+1)个文字】\n"
                        text += "左下:\(txt.bottomLeft)\t右下:\(txt.bottomRight)\n左上:\(txt.topLeft)\t右上:\(txt.topRight)\n"
                    }
                    if text == ""{
                        text = "无法检测"
                    }
                    MainThreadRun({
                        self.textView.text = text
                    })
                }
            }
        })
    }
    
    private func detect_qrc(){
        AsyncThreadRun({
            let option = [CIDetectorAccuracy:CIDetectorAccuracyHigh] //高准确度
            let dector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: option)
            if let cgImage : CGImage = self.imageView.image?.CGImage{
                let ciImage = CIImage(CGImage: cgImage)
                let results = dector.featuresInImage(ciImage)
                var text = ""
                for i in 0..<results.count{
                    let qrc = results[i] as! CIQRCodeFeature
                    self.addBoundsTip(qrc.bounds,inputImageSize: ciImage.extent.size)
                    text += "【第\(i+1)个二维码】\n"
                    text += "内容:\(qrc.messageString)\n左下:\(qrc.bottomLeft)\t右下:\(qrc.bottomRight)\n左上:\(qrc.topLeft)\t右上:\(qrc.topRight)\n"
                }
                if text == ""{
                    text = "无法检测"
                }
                MainThreadRun({
                    self.textView.text = text
                })
            }
        })
    }
    
    //添加矩形标示方框
    private func addBoundsTip(rect : CGRect,inputImageSize: CGSize){
        MainThreadRun({
            let view = UIView(frame: self.transformRect(rect, inputImageSize: inputImageSize))
            view.layer.borderWidth = 4.0
            view.layer.borderColor = UIColor.randomColor().CGColor
            view.layer.masksToBounds = true
            view.layer.shouldRasterize = true
            view.layer.rasterizationScale = UIScreen.mainScreen().scale
            view.tag = 2016
            
            self.imageView.addSubview(view)
        })
    }
    
    private func clearDetect(){
        for sub in self.imageView.subviews{
            if sub.tag == 2016{
                sub.removeFromSuperview()
            }
        }
        self.textView.text = ""
    }
    
    //CIImage里面的位置转换成ImageView中的位置
    func transformRect(rect: CGRect, inputImageSize: CGSize) -> CGRect {
        var transform = resizeTransform(self.imageView.image!) //对拍摄的照片或者特殊的图片进行处理
        transform = CGAffineTransformScale(transform, 1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height)

        var faceViewBounds = CGRectApplyAffineTransform(rect, transform)

//        let transScale = 1.0 / UIScreen.mainScreen().scale
//        let scaleTransform = CGAffineTransformMakeScale(transScale, transScale)
//        faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, scaleTransform)
        
//        let scaleWidth = self.imageView.bounds.size.width / inputImageSize.width
//        let scaleHeight = self.imageView.bounds.size.height / inputImageSize.height
//        faceViewBounds.size = CGSize(width: faceViewBounds.size.width * scaleWidth, height: faceViewBounds.size.height * scaleHeight)
//        if scaleWidth < scaleHeight{
//            faceViewBounds.origin.y += (self.imageView.bounds.size.height - inputImageSize.height * scaleWidth) / 2
//            faceViewBounds.origin.x = faceViewBounds.origin.x * scaleWidth
//        }else{
//            faceViewBounds.origin.x += (self.imageView.bounds.size.width - inputImageSize.width * scaleHeight) / 2
//            faceViewBounds.origin.y = faceViewBounds.origin.y * scaleHeight
//        }
        
        let scale = min(imageView.bounds.size.width / inputImageSize.width,
                        imageView.bounds.size.height / inputImageSize.height)
        let offsetX = (imageView.bounds.size.width - inputImageSize.width * scale) / 2
        let offsetY = (imageView.bounds.size.height - inputImageSize.height * scale) / 2
        
        faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, CGAffineTransformMakeScale(scale, scale))
        faceViewBounds.origin.x += offsetX
        faceViewBounds.origin.y += offsetY
        
        return faceViewBounds
    }
    
    func resizeTransform(image : UIImage)-> CGAffineTransform{
        var rectTransform :CGAffineTransform = CGAffineTransformIdentity
        switch image.imageOrientation{
        case .Left,.LeftMirrored:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(90.0 / 180.0 * CGFloat(M_PI)),0,-image.size.height)
        case .Right,.RightMirrored:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-90.0 / 180.0 * CGFloat(M_PI)),-image.size.width,0)
        case .Down,.DownMirrored:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-180.0 / 180.0 * CGFloat(M_PI)),-image.size.width,-image.size.height)
        default:
            break
        }
        return rectTransform
    }
}

extension UIColor{
    static func randomColor() -> UIColor{
        let arc = arc4random() % 6
        switch arc {
        case 0:
            return UIColor.yellowColor()
        case 1:
            return UIColor.blueColor()
        case 2:
            return UIColor.orangeColor()
        case 3:
            return UIColor.whiteColor()
        case 4:
            return UIColor.greenColor()
        case 5:
            return UIColor.redColor()
        default:
            return UIColor.blueColor()
        }
    }
}

private let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
private let group = dispatch_group_create()
func MainThreadRun(action : (Void -> Void)){
    dispatch_async(dispatch_get_main_queue(), {
        action()
    })
}

func AsyncThreadRun(action : (Void -> Void)){
    dispatch_group_async(group, queue, { () -> Void in
        action()
    })
}
