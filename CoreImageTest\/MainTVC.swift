//
//  MainTVC.swift
//  CoreImageTest
//
//  Created by misupeng on 16/8/15.
//  Copyright © 2016年 misuqian. All rights reserved.
//

import UIKit

//首页界面
class MainTVC: UITableViewController {
    let headers : [String] = ["图像检测","图片处理"]
    var datas : [[(String,String)]] = [[("人脸","face"),("矩形","rect"),("文字","text"),("二维码","qrc")],[("滤镜","filter")]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel(frame: CGRect(origin: CGPointZero, size: CGSize(width: self.view.frame.width, height: 20.0)))
        label.textAlignment = .Center
        label.text = "By misupeng"
        self.tableView.tableFooterView = label
        
        let os = NSProcessInfo().operatingSystemVersion
        if os.majorVersion < 9{
            datas = [[("人脸","face"),("矩形","rect"),("二维码","qrc")],[("滤镜","filter")]]
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return headers.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = datas[indexPath.section][indexPath.row].0
        cell?.accessoryType = .DisclosureIndicator
        return cell!
    }
    
    //点击响应
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let identity : String = datas[indexPath.section][indexPath.row].1 where identity != ""{
            if identity == "filter"{
                self.performSegueWithIdentifier(identity, sender: self)
            }else{
                var type = DetectType.Face
                if identity == "rect"{
                    type = DetectType.Rect
                }else if identity == "text"{
                    type = DetectType.Text
                }else if identity == "qrc"{
                    type = DetectType.QRC
                }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("detect") as! DetectorVC
                vc.type = type
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}
