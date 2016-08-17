//
//  BlurVC.swift
//  CoreImageTest
//
//  Created by misupeng on 16/8/16.
//  Copyright © 2016年 misuqian. All rights reserved.
//

import UIKit
import GLKit
import OpenGLES

protocol BlurDelegate {
    func didSelectBlurName(name : String)
}

//滤镜处理界面
class BlurVC: UIViewController,BlurDelegate{
    
    @IBOutlet weak var imageView: FilterImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    private var inputKeys : [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        didSelectBlurName("CIDotScreen")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EAGLContext.setCurrentContext(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //选择滤镜后初始化
    func didSelectBlurName(name: String) {
        if let filter = CIFilter(name: name){
            self.navigationItem.title = name
            self.inputKeys = filter.inputKeys
            let attri = filter.attributes
            let scrollWidth = self.scrollView.frame.width
            let cellHeight : CGFloat = 60.0
            for view in self.scrollView.subviews{
                if view is ScrollBarView{
                    view.removeFromSuperview() //清空原先的滑动条
                }
            }
            var count = 0
            for i in 0..<self.inputKeys.count{
                let key = self.inputKeys[i]
                if key.uppercaseString.containsString("IMAGE"){
                    
                }else if let dic = attri[key] as? Dictionary<String,AnyObject>{
                    //根据attribute属性动态添加属性设置滚动条
                    let panel = NSBundle.mainBundle().loadNibNamed("ScrollBarPanel", owner: nil, options: nil).first as! ScrollBarView
                    panel.frame = CGRect(x: 0.0, y: CGFloat(count) * cellHeight, width: scrollWidth, height: cellHeight)
                    panel.title.text = dic[kCIAttributeDisplayName] as? String ?? key
                    panel.number.text = "\(dic[kCIAttributeDefault]!)"
                    let max : Float = dic[kCIAttributeSliderMax] as? Float ?? 1.0
                    let min : Float = dic[kCIAttributeSliderMin] as? Float ?? 0.0
                    if dic[kCIAttributeClass] as! String != "NSNumber"{
                        panel.scrollBar.enabled = false //不是NSNumber的属性不能滚动设置.此可扩展，一般还有Vector,Transform等属性参数
                    }
                    panel.scrollBar.maximumValue = max
                    panel.scrollBar.minimumValue = min
                    panel.scrollBar.value = dic[kCIAttributeDefault] as? Float ?? 0.0
                    panel.scrollBar.tag = i
                    panel.scrollBar.addTarget(self, action: #selector(BlurVC.scrollBarChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    
                    self.scrollView.addSubview(panel)
                    count += 1
                }
            }
            imageView.inputImage = UIImage(named: "shit")!
            imageView.filter = filter
            self.scrollView.contentSize = CGSize(width: scrollWidth, height: CGFloat(count) * cellHeight)
        }else{
            print("filter init fail,GG")
        }
    }
    
    //显示滤镜选择界面
    private func showBlurSelect(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("blurSelect") as! BlurSelectVC
        vc.delegate = self
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func selectBlur(sender: UIBarButtonItem) {
        self.showBlurSelect()
    }
    
    //滑动条滑动响应
    func scrollBarChanged(slider : UISlider){
        let label = slider.superview?.viewWithTag(3) as? UILabel
        label?.text = String(format: "%.2f", slider.value)
        if let _filter = self.imageView.filter{
            //设置滤镜属性重新绘制imageView
            _filter.setValue(slider.value, forKey: inputKeys[slider.tag])
            imageView.setNeedsDisplay()
        }
    }
}

class ScrollBarView : UIView{
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var scrollBar: UISlider!
}

//OpenGL重绘滤镜图片
class FilterImageView : GLKView{
    private var ciContext: CIContext!
    
    var filter: CIFilter! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var inputImage: UIImage! {
        didSet {
            setNeedsDisplay()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        self.context = EAGLContext(API: .OpenGLES2) //必须使用2.0
        ciContext = CIContext(EAGLContext: context)
        EAGLContext.setCurrentContext(self.context)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clipsToBounds = true
        self.context = EAGLContext(API: .OpenGLES2)
        ciContext = CIContext(EAGLContext: context)
        EAGLContext.setCurrentContext(self.context)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard ciContext != nil && inputImage != nil else{
            return
        }
        if let _filter = self.filter{
            let inputCIImage = CIImage(image: inputImage)
            _filter.setValue(inputCIImage!, forKey: kCIInputImageKey)
            if let outputImage = _filter.outputImage {
                clearBackground()
                let inputBounds = inputCIImage!.extent
                let drawableBounds = CGRect(x: 0, y: 0, width: self.drawableWidth, height: self.drawableHeight)
                let targetBounds = aspectFill(inputBounds, toRect: drawableBounds)
                ciContext.drawImage(outputImage, inRect: targetBounds, fromRect: inputBounds)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    //对aspectFill进行适配
    func aspectFill(fromRect: CGRect, toRect: CGRect) -> CGRect {
        let fromAspectRatio = fromRect.size.width / fromRect.size.height;
        let toAspectRatio = toRect.size.width / toRect.size.height;
        
        var fitRect = toRect
        
        if (fromAspectRatio > toAspectRatio) {
            fitRect.size.width = toRect.size.height  * fromAspectRatio;
            fitRect.origin.x += (toRect.size.width - fitRect.size.width) * 0.5;
        } else {
            fitRect.size.height = toRect.size.width / fromAspectRatio;
            fitRect.origin.y += (toRect.size.height - fitRect.size.height) * 0.5;
        }
        
        return CGRectIntegral(fitRect)
    }
    
    func clearBackground() {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a)
        glClearColor(GLfloat(r), GLfloat(g), GLfloat(b), GLfloat(a))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
}
