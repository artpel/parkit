//
//  TestVC.swift
//  parkit
//
//  Created by Arthur Péligry on 29/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit
import Spring
import SnapKit

class TestVC: UIViewController {

    @IBOutlet weak var vue: SpringView!
    
    @IBAction func button1(_ sender: Any) {
        vue.isHidden = false
        vue.animation = "squeezeDown"
        vue.curve = "easeInOut"
        vue.animate()
    }
    
    @IBAction func button2(_ sender: Any) {
        
        vue.isHidden = false
        vue.animation = "zoomOut"
        vue.curve = "easeInOut"
        vue.animate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vue.isHidden = true
        let alert = AlertVC(self.view, "Ceci est un titre", "Ceci un sous-titre", "Cancel", "Ok")
        
//        alert.frame = CGRect(x: 100, y: 0, width: 100, height: 200)
        view.addSubview(alert)
        
        
        alert.snp.makeConstraints { (make) -> Void in
                make.center.equalTo(self.view)
            }
        
       
    }


}


class AlertVC: SpringView {
    var title: String?
    var subtitle: String?
    var cancelBtnLabel: String?
    var acceptBtnLabel: String?
    var supervue: UIView?
   
    // #1
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    // #2
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    // #3
    public convenience init(_ supervue: UIView, _ title: String, _ subtitle: String, _ cancelBtnLabel: String, _ acceptBtnLabel: String) {
        
        self.init(frame: .zero)
        
        self.supervue = supervue
        self.title = title
        self.subtitle = subtitle
        self.cancelBtnLabel = cancelBtnLabel
        self.acceptBtnLabel = acceptBtnLabel
        
        setupView()
    }

    private func setupView() {
        
        self.backgroundColor = UIColor.red
        self.layer.cornerRadius = 8

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        self.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(self)
            make.top.equalTo(self).offset(20)
            make.centerX.equalTo(self)
        }
        
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        
        
        subtitleLabel.text = self.subtitle
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.white
        
        self.addSubview(subtitleLabel)
        
        subtitleLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(self).offset(-20)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self)
        }
        
        self.snp.makeConstraints { (make) -> Void in
            let boundaries = UIScreen.main.bounds
            let width = boundaries.width * 0.7
            make.width.equalTo(width)
            make.height.equalTo(subtitleLabel.snp.height).offset(100)
        }
        
        let button1 = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        button1.titleLabel?.text = cancelBtnLabel
        button1.tintColor = UIColor.white
        
        self.addSubview(button1)

        
//        button1.snp.makeConstraints { (make) -> Void in
//                let boundaries = UIScreen.main.bounds
//                let width = self.frame.width * 0.5
//                make.width.equalTo(width)
//                make.left.equalTo(self.snp.left).offset(0)
//        }
        
        let button2 = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        button2.titleLabel?.text = cancelBtnLabel
        button2.tintColor = UIColor.white
        
        
        button2.snp.makeConstraints { (make) -> Void in
            let boundaries = UIScreen.main.bounds
            let width = self.frame.width * 0.5
            make.width.equalTo(width)
            make.right.equalTo(self.snp.right).offset(0)
        }
        
        self.addSubview(button2)
        
        self.animation = "squeezeRight"
        self.curve = "easeInOut"
        self.delay = 1
        self.animate()
        
        
        
    }

}
