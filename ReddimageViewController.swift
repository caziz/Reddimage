//
//  ReddimageViewController.swift
//  Reddimage
//
//  Created by Christopher Aziz on 7/5/17.
//  Copyright © 2017 Christopher Aziz. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON

class ReddimageViewController: UIViewController {
    var reddimages : [ReddimagePost] = []
    
    @IBOutlet weak var reddimageTableView: UITableView!
    
    @IBOutlet weak var reddimageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reddimageTextField.delegate = self
        self.loadImages(count: 50, with: "aww")
        self.reddimageTableView.rowHeight = UITableViewAutomaticDimension
        self.reddimageTableView.estimatedRowHeight = 200
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func displayImages(index: Int, with json: JSON) {
        print("loading image \(index): ", terminator: "")
        let post = json["data"]["children"][index]["data"]
        let imageString = post["preview"]["images"][0]["source"]["url"].stringValue
        if(imageString.characters.count == 0) {
            print("no string at index api url")
            return
        }
        guard   let imageURL = URL(string: imageString),
                let imageData = try? Data(contentsOf: imageURL),
                let image = UIImage(data: imageData) else {
            print("couldn't load image at index")
            return
        }
        let titleText = post["title"].stringValue
        let score = post["score"].stringValue
        let height = post["preview"]["images"][0]["source"]["height"].doubleValue
        let width = post["preview"]["images"][0]["source"]["width"].doubleValue
        let ratio = height/width

        let reddimage = ReddimagePost(title: titleText, score: score, image: image, ratio: ratio)
        reddimages.append(reddimage)
        print("success")
    }
    
    func loadImages(count toLoad: Int, with: String) {
        let apiToContact = "https://www.reddit.com/r/\(with)/.json"
        Alamofire.request(apiToContact).validate().responseJSON { response in
            switch response.result {
            case .success:
                guard let value = response.result.value else {
                    fatalError("no json at api")
                }
                self.reddimages = []
                for i in 0...toLoad {
                    self.displayImages(index: i, with: JSON(value))
                    self.reddimageTableView.reloadData()
                }
                print("completed loading images")
                //self.reddimageTableView.reloadData()
            case .failure(let error):
                fatalError(error as? String ?? "unknown error!")
            }
        }
    }
}

extension ReddimageViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("loading cell \(indexPath.section)")
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reddimageHeaderCell", for: indexPath) as! ReddimageHeaderCell
            cell.leftLabel.text = reddimages[indexPath.section].title
            
            var score = reddimages[indexPath.section].score
            if(score.characters.count > 4) {
                let index = score.index(score.endIndex, offsetBy: -3)
                score = score.substring(to: index)
                score.append("k")
            }
            cell.rightLabel.text = score
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reddimageCell", for: indexPath) as! ReddimageCell
            cell.reddimage.image = reddimages[indexPath.section].image
            return cell
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        print("displaying \(reddimages.count) cells")
        return reddimages.count
    }
}

extension ReddimageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1:
            let deviceWidth = UIScreen.main.bounds.size.width
            let ratio : Double = Double(reddimages[indexPath.section].ratio)
            return CGFloat(ratio) * deviceWidth
        default:
            // auto adjust height for non images
            return -1
        }
    }
}

extension ReddimageViewController: UITextFieldDelegate {
    func textFieldDidChange(_ textField: UITextField) {
        if let text = reddimageTextField.text {
            self.loadImages(count: 50, with: text)
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.loadImages(count: 50, with: self.reddimageTextField?.text ?? "cat")
        print("hi")
        return true
    }
    
    
}
