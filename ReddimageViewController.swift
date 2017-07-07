//
//  ReddimageViewController.swift
//  Reddimage
//
//  Created by Christopher Aziz on 7/5/17.
//  Copyright © 2017 Christopher Aziz. All rights reserved.
//

/*
    TODO:   gif support buggy
            pagination
            link to reddit
 */


import UIKit
import Alamofire
import SwiftyJSON
import SwiftGifOrigin

class ReddimageViewController: UIViewController {
    var reddimages : [ReddimagePost] = []
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    var currentSubreddit : String = ""
    
    @IBOutlet weak var errorMessage: UILabel!
    @IBAction func imagePressed(_ sender: UIButton) {
        let touchPoint = sender.convert(CGPoint.zero, to: self.reddimageTableView)
        let index = self.reddimageTableView.indexPathForRow(at: touchPoint)
        let url = URL(string: reddimages[index![0]].link)!
        UIApplication.shared.open(url, options: [:]) { x in}
    }
    @IBOutlet weak var reddimageTableView: UITableView!
    @IBOutlet weak var reddimageTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // initialize
        self.loadImages(count: 1000, with: "pics")
        self.reddimageTextField.delegate = self
        // auto resize header cell
        self.reddimageTableView.rowHeight = UITableViewAutomaticDimension
        self.reddimageTableView.estimatedRowHeight = 200

    }
    
    func constructImage(post: JSON) -> Bool {
        // get link
        guard let image = getImage(post: post) else {
            print("didn't load image")
            return false
        }
        
        // grab meta info
        let titleText = post["title"].stringValue
        let score = post["score"].stringValue
        let height = post["preview"]["images"][0]["source"]["height"].doubleValue
        let width = post["preview"]["images"][0]["source"]["width"].doubleValue
        let ratio = height/width
        let link = "https://www.reddit.com\(post["permalink"])"
        // init reddimage and append
        let reddimage = ReddimagePost(title: titleText, score: score, image: image, ratio: ratio, link: link)
        reddimages.append(reddimage)
        return true
    }
    
    func getImage(post: JSON) -> UIImage? {
        // try to get image
        let imageString = post["preview"]["images"][0]["source"]["url"].stringValue
        if  let imageURL = URL(string: imageString),
            let imageData = try? Data(contentsOf: imageURL),
            let image = UIImage(data: imageData) {
            print("loaded image")
            return image
        }

        // try to get gif
        let gifString = post["url"].stringValue
        if  let gifURL = URL(string: gifString),
            let gifData = try? Data(contentsOf: gifURL),
            let gif = UIImage.gif(data: gifData) {
            print("loaded gif")
            return gif
        }
        
        // otherwise return nil
        return nil
    }
    
    func loadImages(count toLoad: Int, with: String) {
        var toSearch = with
        self.errorMessage.isHidden = true
        reddimages = []
        reddimageTableView.reloadData()
        self.startSpinner()
        if self.reddimageTextField.text == "bug" {
            self.reddimageTextField.text = "feature"
            toSearch = "feature"
        }
        let apiToContact = "https://www.reddit.com/r/\(toSearch)/.json?count=\(toLoad)&after=t3_10omtd/"
        Alamofire.request(apiToContact).validate().responseJSON { response in
            switch response.result {
            case .success:
                guard let value = response.result.value else {
                    return
                }
                // load images
                var validReddimages = 0
                let children = JSON(value)["data"]["children"]
                for i in 0..<toLoad {
                    let post = children[i]["data"]
                    if self.constructImage(post: post) {
                        validReddimages += 1
                    }
                }

                if validReddimages == 0 {
                    self.reddimageTextField.text = ""
                    self.errorMessage.text = "We couldn't find any images for that subreddit."
                    self.errorMessage.isHidden = false
                }
                
                // display images
                self.reddimageTableView.reloadData()
                self.reddimageTableView.setContentOffset(CGPoint.zero, animated: false)
                self.stopSpinner()
            case .failure:
                return
            }
        }
    }
    
}

// MARK: - UITableViewDataSource

extension ReddimageViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reddimageHeaderCell", for: indexPath) as! ReddimageHeaderCell
            
            // left label with title
            cell.leftLabel.text = reddimages[indexPath.section].title
            
            // right label with score
            var score = reddimages[indexPath.section].score
            if score.characters.count > 4 {
                let index = score.index(score.endIndex, offsetBy: -3)
                score = score.substring(to: index)
                score.append("k")
            }
            cell.rightLabel.text = score
            
            return cell
        case 1:
            // add image
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
        return reddimages.count
    }
}

// MARK: - UITableViewDelegate

extension ReddimageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1:
            // set proportional image height
            let deviceWidth = UIScreen.main.bounds.size.width
            let ratio : Double = Double(reddimages[indexPath.section].ratio)
            return CGFloat(ratio) * deviceWidth
        default:
            // auto adjust height for non images
            return -1
        }
    }
}

// MARK: - UITextFieldDelegate

extension ReddimageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // search cannot be pressed without text
        if currentSubreddit != textField.text {
            currentSubreddit = textField.text!
            self.loadImages(count: 30, with: self.reddimageTextField.text!)
        }
        return true
        
    }
}

// MARK: - Spinner

extension ReddimageViewController {
    func startSpinner() {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.transform = CGAffineTransform.init(scaleX: 3, y: 3)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopSpinner() {
        activityIndicator.stopAnimating()
    }
}
