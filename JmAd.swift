//
//  JmAd.swift
//
//  Copyright ROI-App
//  AlamoFire 5
//

import Foundation
import Alamofire
import SDWebImage
import SafariServices

enum jmadEventType: String {
  case print = "print"
  case hit = "hit"
}

enum jmadEventOrientation: String {
  case portrait = "portrait"
  case landscape = "landscape"
}

class JmAd
{
    typealias CompletionHandler = (Bool) -> Void
    
    static let instance = JmAd()
    
    private var appID = ""
    private var adView: UIView!
    private var sponsorlabel:UILabel!
    private var mytimer: Foundation.Timer!
    private var adDuration: Int!
    private var adObject: jm_Ad!
    private var orientation: jmadEventOrientation!
    private var adcomplete: CompletionHandler!
    private var containerVC: UIViewController!
    private var adTapped: Bool!
    
    struct jm_Ad: Codable {
        let id: Int
        let ad_id: String
        let type: String
        let format: String
        let duration: Int
        let app_id: Int
        let filename: String
        let store_url: String
    }
    
    public func initSDK(_ appid:String)
    {
        self.appID = appid
        self.orientation = .portrait
        self.adTapped = false
    }
    
    public func callInventory(completionHandler:@escaping (Bool) -> Void)
    {
        if self.appID == "" {
            completionHandler(false)
            return
        }
        
        let URL: String = "https://roi-app.com/api/ad/inventory/" + self.appID
        print("API jma inventory: \(URL)")
    
        AF.request(URL, method: .get).responseData { response in
    
            switch response.result {
            case .success(let value):
                
                do {
                    //let data = try Data(contentsOf: testUrl)
                    self.adObject = try JSONDecoder().decode(jm_Ad.self, from: value)
                    completionHandler(true)
                }
                
                catch {
                    print(error)
                    completionHandler(false)
                }
                                
            case .failure(let error):
                print(error)
                completionHandler(false)
            }
        }
    }
    
    public func loadAd(completionHandler:@escaping (Bool) -> Void)
    {
        if self.adTapped == true {
            completionHandler(false)
            return
        }
        completionHandler(true)
        
        /*
        let url: String = "https://roi-app.com/api/v1/fr/1.0/jma/show/" + self.adObject.ad_id
        print("API jma loadAd: \(url)")
        
        let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let downloadFilePath = documentsPath.appendingPathComponent(self.adObject.filename)
        print("downloadFilePath= " + documentsPath.absoluteString)

        let destination: DownloadRequest.Destination = { _, _ in
            return (downloadFilePath, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(
            url,
            method: .get,
            encoding: JSONEncoding.default,
            headers: nil,
            to: destination
            ).downloadProgress(closure: { (progress) in
                print("progress : \(progress.fractionCompleted)")
            }).response(completionHandler: { (DefaultDownloadResponse) in
                completionHandler(true)
            })*/
    }
    
    public func showAd(_ vcont:UIViewController, _ completionHandler: @escaping CompletionHandler)
    {
        containerVC = vcont
        adcomplete = completionHandler
        
        /*if self.adObject.format == jmadEventOrientation.landscape.rawValue {
            self.orientation = jmadEventOrientation.landscape
        }*/
        self.orientation = self.adObject.format == jmadEventOrientation.portrait.rawValue ? jmadEventOrientation.portrait : jmadEventOrientation.landscape
        
        if let appOrientation = vcont.view.window?.windowScene?.interfaceOrientation {
            //self.orientation = (appOrientation.isPortrait == true) ? .portrait : .landscape
        }
        
        if adView != nil {
            adcomplete(false)
            adcomplete = nil
            return
            //hideAd()
        }
        adView =  UIView(frame: vcont.view.frame)
        adView.backgroundColor = .white // vcont.view.backgroundColor != .clear ? vcont.view.backgroundColor : .white
        vcont.view.addSubview(adView)
        
        /*
        let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let downloadFilePath = documentsPath.appendingPathComponent(self.adObject.filename)
        print("API jma showAd= " + downloadFilePath.path)

        guard let img = UIImage(contentsOfFile: downloadFilePath.path) else { return }
        
        if adView != nil {
            hideAd()
        }
        adView =  UIView(frame: vcont.view.frame)
        adView.backgroundColor = .white // vcont.view.backgroundColor != .clear ? vcont.view.backgroundColor : .white
        vcont.view.addSubview(adView)
        */
        
        
        if self.orientation == .landscape {
            //adView.transform = adView.transform.rotated(by:(-90.0 * CGFloat(Double.pi / 180)))
        }
        
        
        let bgAdView =  UIView(frame: .zero)
        bgAdView.backgroundColor = .white // .clear
        bgAdView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bgAdView)
        
        NSLayoutConstraint.activate([
            bgAdView.topAnchor.constraint(equalTo: vcont.view.safeAreaLayoutGuide.topAnchor),
            bgAdView.leftAnchor.constraint(equalTo: vcont.view.safeAreaLayoutGuide.leftAnchor),
            bgAdView.rightAnchor.constraint(equalTo: vcont.view.safeAreaLayoutGuide.rightAnchor),
            bgAdView.bottomAnchor.constraint(equalTo: vcont.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        /*
        let imageView = UIImageView(image: img)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bgAdView.addSubview(imageView)
        */
        
        let url = URL(string: self.adObject.filename)
        SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil, completed: { [weak self] (image, data, error, cacheType, finished, url) in
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            bgAdView.addSubview(imageView)
            
            if self?.orientation == .landscape {
                imageView.transform = imageView.transform.rotated(by:(-90.0 * CGFloat(Double.pi / 180)))
            }
            
            //center image
            if self?.orientation == .landscape {
                let centerXConst = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: bgAdView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
                let centerYConst = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: bgAdView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
                NSLayoutConstraint.activate([centerXConst, centerYConst])
            }
            else {
                let centerXConst = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: bgAdView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
                let centerYConst = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: bgAdView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
                NSLayoutConstraint.activate([centerXConst, centerYConst])
            }

            if self?.orientation == .landscape {
                let heightConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.height)
                let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.width)
                imageView.addConstraints([heightConstraint, widthConstraint])
            }
            else {
                let heightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.height)
                let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.width)
                imageView.addConstraints([heightConstraint, widthConstraint])
            }
        })
        
        /*
        if self.orientation == .landscape {
            bgAdView.transform = bgAdView.transform.rotated(by:(-90.0 * CGFloat(Double.pi / 180)))
        }

        //center image
        if self.orientation == .landscape {
            let centerXConst = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: bgAdView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
            let centerYConst = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: bgAdView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            NSLayoutConstraint.activate([centerXConst, centerYConst])
        }
        else {
            let centerXConst = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: bgAdView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            let centerYConst = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: bgAdView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
            NSLayoutConstraint.activate([centerXConst, centerYConst])
        }

        if self.orientation == .landscape {
            let heightConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.height)
            let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.width)
            imageView.addConstraints([heightConstraint, widthConstraint])
        }
        else {
            let heightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.height)
            let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: vcont.view.safeAreaLayoutGuide.layoutFrame.width)
            imageView.addConstraints([heightConstraint, widthConstraint])
        }
*/
        
        adDuration = self.adObject.duration
        
        if self.orientation == .landscape {
            sponsorlabel = UILabel(frame: CGRect(x: 10+190, y: -12-170, width: vcont.view.safeAreaLayoutGuide.layoutFrame.width, height: 14))
        }
        else {
            sponsorlabel = UILabel(frame: CGRect(x: 10, y: -12, width: vcont.view.safeAreaLayoutGuide.layoutFrame.width, height: 14))
        }
        sponsorlabel.textColor = .black
        //sponsorlabel.backgroundColor = .green
        sponsorlabel.font = UIFont.boldSystemFont(ofSize: 14)
        sponsorlabel.adjustsFontForContentSizeCategory = true
        sponsorlabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        sponsorlabel.layer.shadowOpacity = 1//0.8
        sponsorlabel.layer.shadowRadius = 1
        sponsorlabel.layer.shadowColor = CGColor.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        bgAdView.addSubview(sponsorlabel)
        
        updateSponsorLabel()

        if (mytimer != nil) && mytimer.isValid {
            mytimer.invalidate()
        }
        mytimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
        // Initialize Tap Gesture Recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
        adView.addGestureRecognizer(tapGestureRecognizer)
        
        sendStats(.print, completionHandler: { response in
        })
    }
    
    @objc func fireTimer()
    {
        adDuration = adDuration - 1
        if adDuration == 0 {
            hideAd()
            adcomplete(true)
            adcomplete = nil
            containerVC = nil
            return
        }
        updateSponsorLabel()
    }
    
    private func updateSponsorLabel()
    {
        var stext = "Sponsor.. "
        if adDuration > 0 {
            stext += "\(adDuration!)"
        }
        sponsorlabel.text = stext
    }
    
    public func hideAd()
    {
        mytimer?.invalidate()
        if adView != nil {
            adView.removeFromSuperview()
            adView = nil
        }
        self.adTapped = false
    }
    
    private func sendStats(_ event: jmadEventType, completionHandler:@escaping (Bool) -> Void)
    {
        if self.adObject == nil {
            completionHandler(false)
            return
        }
        
        let URL: String = "https://roi-app.com/api/ad/stats"
        print("API jma stats: \(URL)")
        
        /*let callheaders: HTTPHeaders = [
            .accept("application/json"),
            .contentType("application/json")
        ]*/
        
        let params = ["ad_id": self.adObject.ad_id,
                      "app_id_src": self.appID,
                      "app_id_dst": self.adObject.app_id,
                      "event": event.rawValue] as [String : Any]
		
		print(params)
    
        AF.request(URL, method: .post,
                   parameters: params/*,
                   headers: callheaders*/
                ).responseString { response in
            
            //print("response: \(response)")
            switch response.result {
            case .success(let value):
                print("value**: \(value)")
                completionHandler(true)
                
            case .failure(let error):
                print(error)
                completionHandler(false)
            }
        }
    }
    
    @IBAction func didTapImageView(_ sender: UITapGestureRecognizer)
    {
        self.adTapped = true
        
        print("did tap image view", sender)
        sendStats(.hit, completionHandler: { response in
        })

        if let url = URL(string: self.adObject.store_url) {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .overFullScreen // To ensure it doesn't cause the app to enter background
            self.containerVC.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func imageRotatedByDegrees(oldImage: UIImage,degrees: CGFloat) -> UIImage
    {
        let size = oldImage.size
        
        UIGraphicsBeginImageContext(size)
        
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: size.width / 2, y: size.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat(Double.pi / 180)))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        
        let origin = CGPoint(x: -size.width / 2, y: -size.width / 2)
        
        bitmap.draw(oldImage.cgImage!, in: CGRect(origin: origin, size: size))
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

/*
extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
        }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
*/

