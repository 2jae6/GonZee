//
//  ViewController.swift
//  GonZee
//
//  Created by 1 on 2020/05/31.
//  Copyright © 2020 wook. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper


class ViewController: UIViewController, CLLocationManagerDelegate, XMLParserDelegate {
    //LocationManager 선언
    var locationManager:CLLocationManager!
    //DefalutData 선언
    var defData = DefaultData()
    
    
    //xml 필요 변수들 시작 nearcheck()
    var currentElement = ""
    
    class CheckStation{
        var checkS:String?
    }
    var checkArray: Array<String> = []
    var checkStation:CheckStation?
    //xml 필요변수들 끝
    
    //xml 필요 변수들 시작 getSmog()
    class Smog{
        var pm10:String?
        var pm25:String?
    }
    var smogArray: Array<String> = []
    var smog:Smog?
    //xml 필요변수들 끝
    
    //xml 필요 변수들 시작 getWeather()
    class Weather{
        var data:String?
    }
    var weatherArray: Array<String> = []
    var th1bool: Bool = false
    var weather:Weather?
    //xml 필요변수들 끝
    
    
    
    
    
    //Outlet
    @IBOutlet var airState: UILabel!
    @IBOutlet var pm10State: UILabel!
    @IBOutlet var pm25State: UILabel!
    @IBOutlet var nowLocation: UILabel!
    @IBOutlet var nowT1H: UILabel!
    @IBOutlet var catImage: UIImageView!
    //IBAction
    
    
    @IBAction func refreshButton(_ sender: Any) {
        refresh()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(self.activityIndicator)
        
        
 
        callback()
  
        
    }//viewdidload 끝

    func callback(){
        //포그라운드 상태에서 위치 추적 권한 요청
         locationManager = CLLocationManager()
         locationManager.delegate = self
         //포그라운드 상태에서 위치 추적 권한 요청
         locationManager.requestWhenInUseAuthorization()
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("자동")
            locationMan()
        default:
            print("뀨")
        }
    }
    
    func refresh(){
        // locationman > nearChecker > getSmog> getWeather > getWeather2 > bgSet
        locationMan()
        
    }
 
    
    //위도 경도 획득 메서드
    func locationMan(){
        
        activityIndicator.startAnimating()
        

        //배터리에 맞게 권장되는 최적의 정확도
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //위치업데이트
        locationManager.startUpdatingLocation()
        
        //위도 경도 가져오기
        guard let coor = locationManager.location?.coordinate else{
            print("으억")
            callback()
            return
        }
        let latitude = coor.latitude
        let longitude = coor.longitude
        
        defData.latitude = latitude
        defData.longitude = longitude
        
        
        let findLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        let locale = Locale(identifier: "Ko-kr")
        let geoCoder: CLGeocoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(findLocation, preferredLocale: locale) { (place, error) in
            if let address: [CLPlacemark] = place {
                print("시(도): \(String(describing: address.last?.administrativeArea))")
                print("구(군): \(String(describing: address.last?.locality))")
                self.nowLocation.text = "지금 \(String(describing: address.last!.locality!))는"
            }
        }
        
        
        //여기서부터 TM 변한
        let url = "https://dapi.kakao.com/v2/local/geo/transcoord.json"
        let param:Parameters = [
            "y": latitude,
            "x": longitude,
            "input_coord" : "WGS84",
            "output_coord": "TM"]
        
        let headers: HTTPHeaders = ["Authorization":"KakaoAK 3b9622f0285c753ec6c27f91e263812d"]
        
        /* JSON 데이터 호출 로그
         Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: headers).responseJSON{
         (response) in
         switch response.result{
         case .success(let suc):
         print(suc)
         print("성공")
         case .failure(let err):
         print(err)
         print("실패")
         }
         }
         */
        Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: headers).responseObject{
            (response: DataResponse<TMConvertDTO>) in
            let tmConvertDTO = response.result.value
            
            
            //defData에 집어넣기
            self.defData.tmX = tmConvertDTO!.documents![0].x!
            self.defData.tmY = tmConvertDTO!.documents![0].y!
            
            
            self.nearChecker()
            
        } //locationman() 함수 끝
        
        
    }
    //가까운 측정소 찾기
    func nearChecker(){
        //가까운 측정소 출력
        let url = "http://openapi.airkorea.or.kr/openapi/services/rest/MsrstnInfoInqireSvc/getNearbyMsrstnList"
        
        let api_key = "vejJ9z%2BevfaWK4HHI9EWdssLIRe%2FI31VBETVkH%2B1HWfVOXGdelhAHZ1a1vgdBpYMB8UzNN6USCr75LB9ynmI%2FQ%3D%3D"
        
        let api_key_decode = api_key.decodeUrl()
        
        guard let tmX = self.defData.tmX else{
            print("으악1")
            return
        }
        
        guard let tmY = self.defData.tmY else{
            print("으악2")
            return
        }
        /*
         let param:Parameters = [
         "ServiceKey" : api_key_decode!,
         "tmX" : tmX,
         "tmY" : tmY
         
         
         ]
         
         
         // XML 데이터 호출 로그
         Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default).validate().responseString{
         (response) in
         switch response.result{
         case .success(let suc):
         print(suc)
         print("성공")
         case .failure(let err):
         print(err)
         print("실패")
         }
         }
         */
        
        //XMLParser
        let keyX = api_key
        
        let urlX = "http://openapi.airkorea.or.kr/openapi/services/rest/MsrstnInfoInqireSvc/getNearbyMsrstnList?serviceKey=\(keyX)&tmX=\(tmX)&tmY=\(tmY)"
        
        
        let xmlParser = XMLParser(contentsOf: URL(string: urlX)!)
        xmlParser!.delegate = self
        xmlParser!.parse()
        
        
        
        
        print(checkArray)
        getSmog()
        
    }//nearchecker()끝
    
    //getSmog 시작
    func getSmog(){
        
        let url = "http://openapi.airkorea.or.kr/openapi/services/rest/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty"
        let api_key = "vejJ9z%2BevfaWK4HHI9EWdssLIRe%2FI31VBETVkH%2B1HWfVOXGdelhAHZ1a1vgdBpYMB8UzNN6USCr75LB9ynmI%2FQ%3D%3D"
        
        let api_key_decode = api_key.decodeUrl()
        
        /*
         let param:Parameters = [
         "serviceKey" : api_key_decode!,
         "stationName" : checkArray[0],
         "numOfRows" : 1,
         "pageNo" : 1,
         "dataTerm" : "DAILY",
         "ver" : 1.3
         ]
         
         
         // XML 데이터 호출 로그
         Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default).validate().responseString{
         (response) in
         switch response.result{
         case .success(let suc):
         print(suc)
         print("성공")
         case .failure(let err):
         print(err)
         print("실패")
         }
         }
         */
        
        
        //xmlPasse!!!!!
        if checkArray.isEmpty{
            refresh()
        }
        
        let stationName = checkArray[0].addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        
        let urlS = "http://openapi.airkorea.or.kr/openapi/services/rest/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?serviceKey=\(api_key)&stationName=\(stationName!)&numOfRows=1&pageNo=1&dataTerm=DAILY&ver=1.3"
        
        let xmlParser = XMLParser(contentsOf: URL(string: urlS)!)
        xmlParser!.delegate = self
        xmlParser!.parse()
        
        //pm10Value, pm25Value
        print(smogArray)
        
     //   getWeather()
        getWeather2()
    }//getSmog()끝
    /*
    //날씨 정보 얻기
    func getWeather(){
        //초단기 실황
        let url = "http://apis.data.go.kr/1360000/VilageFcstInfoService/getUltraSrtNcst"
        //getVilageFcst
        //  let api_key = "7jXpwje4kiKt%2F8%2Bhwo5bDGtMqmvhHr%2FNEZWXtFV5fzlFw3v2aYod7%2B9aDe6Ow2D7e68UbljTbwMEwO4DXZNPyw%3D%3D"
        let api_key = "vejJ9z%2BevfaWK4HHI9EWdssLIRe%2FI31VBETVkH%2B1HWfVOXGdelhAHZ1a1vgdBpYMB8UzNN6USCr75LB9ynmI%2FQ%3D%3D"
        
        let api_key_decode = api_key.decodeUrl()
        
        let convert = LambertProjection()
        let (x, y) = convert.convertGrid(lon: defData.longitude!, lat: defData.latitude!)
        
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let year = dateFormatter.string(from: Date())
        
        dateFormatter.dateFormat = "MM"
        let month = dateFormatter.string(from: Date())
        
        dateFormatter.dateFormat = "dd"
        let day = dateFormatter.string(from: Date())
        
        dateFormatter.dateFormat = "HH"
        let hour = dateFormatter.string(from: Date())
        
        let base_date = year + month + day
        let base_time = hour + "00"
        /*
         
         
         let param:Parameters = [
         "serviceKey" : api_key_decode!,
         "numOfRows" : 100,
         "pageNo" : 1,
         "base_date" : base_date,
         "base_time" : base_time,
         "nx" : x,
         "ny" : y
         ]
         
         
         // XML 데이터 호출 로그
         Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default).validate().responseString{
         (response) in
         switch response.result{
         case .success(let suc):
         print(suc)
         print("성공")
         case .failure(let err):
         print(err)
         print("실패")
         }
         }
         */
        
        let urlW = "http://apis.data.go.kr/1360000/VilageFcstInfoService/getUltraSrtNcst?serviceKey=\(api_key)&numOfRows=100&pageNo=1&base_date=\(base_date)&base_time=\(base_time)&nx=\(x)&ny=\(y)"
        
        
        let xmlParser = XMLParser(contentsOf: URL(string: urlW)!)
        xmlParser!.delegate = self
        xmlParser!.parse()
        
        
        print(weatherArray)
        
        bgSet()
    }//날씨 정보 얻기 끝
    */
    func getWeather2(){
        
        let url = "http://api.openweathermap.org/data/2.5/weather"
        //let url = "http://api.openweathermap.org/data/2.5/weather?lat=37&lon=127&appid=1f8af8214a1d9b5b7a074aa65a61aaee"
        
        let appid = "1f8af8214a1d9b5b7a074aa65a61aaee"
        print(defData.latitude)
        let param: Parameters = [
            "lat" : defData.latitude,
            "lon" : defData.longitude,
            "appid" : appid
        ]
        /*
        Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default).responseJSON{
        (response) in
        switch response.result{
        case .success(let suc):
        print(suc)
        print("성공")
        case .failure(let err):
        print(err)
        print("실패")
        }
        }
        */
        
        Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default).responseObject{
             (response: DataResponse<TMPData>) in
             let tmpData = response.result.value
       
            self.defData.temp = tmpData!.main!.temp!
            print(self.defData.temp!)
            self.nowT1H.text = "\(self.defData.temp! - 273.15)" + "°C"
            
    }
        
        bgSet()
        
}
    func bgSet(){
        
        pm10State.text = smogArray[0]
        pm25State.text = smogArray[1]
        
     
        
     
        var smogNum = Int(smogArray[0])
        
        if smogArray[1] > smogArray[0]{
            let smogNum = Int(smogArray[1])
        }
        
        
        //배경 설정
        if smogNum! <= 30{
            //좋음
            self.view.backgroundColor = UIColor(red: 0, green: 0.8392, blue: 0.9686, alpha: 1.0)
            self.catImage.image = UIImage(named: "1.png")
            airState.text = "아주 좋은 공기다냥!!!"
        }else if smogNum! <= 80{
            //보통
            self.view.backgroundColor = UIColor(red: 0.4196, green: 0.898, blue: 0, alpha: 1.0)
            self.catImage.image = UIImage(named: "2.png")
            airState.text = "나름 괜찮은 공기다냥!"
        }else if smogNum! <= 150{
            //나쁨
            self.view.backgroundColor = UIColor(red: 1, green: 0.6471, blue: 0, alpha: 1.0)
            self.catImage.image = UIImage(named: "3.png")
            airState.text = "조심..! 나쁜 공기다냥!"
        }else{
            //매우 나쁨
            self.view.backgroundColor = UIColor(red: 0.8196, green: 0.1059, blue: 0, alpha: 1.0)
            self.catImage.image = UIImage(named: "4.png")
            airState.text = "그냥 집에 있자냥..."
        }
        
        
        activityIndicator.stopAnimating()
    }//배경설정 끝
    
    
    
    //XML method
    // XML 파서가 시작 테그를 만나면 호출됨
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        
        currentElement = elementName
        
        
        if elementName == "stationName"{
            checkStation = CheckStation()
        }
        
        if elementName == "pm10Value"{
            smog = Smog()
        }
        
        if elementName == "pm25Value"{
            smog = Smog()
        }
        
        
        //getWeather
        if elementName == "obsrValue"{
            weather = Weather()
        }
        
        
        
        
    }
    
    // 현재 테그에 담겨있는 문자열 전달
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        
        
        switch currentElement {
        case "stationName":
            checkStation?.checkS = string
        case "pm10Value":
            smog?.pm10 = string
        case "pm25Value":
            smog?.pm25 = string
        default:
            break;
        }
        
        if currentElement == "category" && string == "T1H"{
            th1bool = true
        }
        if currentElement == "obsrValue" && th1bool == true{
            weather?.data = string
        }
        
        
        
        
    }
    
    // XML 파서가 종료 테그를 만나면 호출됨
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "stationName"{
            checkArray.append(checkStation!.checkS!)
        }
        
        if elementName == "pm10Value"{
            smogArray.append(smog!.pm10!)
        }
        
        if elementName == "pm25Value"{
            smogArray.append(smog!.pm25!)
        }
        
        if elementName == "obsrValue" && th1bool == true{
            weatherArray.append(weather!.data!)
            th1bool = false
        }
        
    }
    //로딩 인디케이터
    lazy var activityIndicator: UIActivityIndicatorView = {
        // Create an indicator.
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = self.view.center
        activityIndicator.color = UIColor.red
        // Also show the indicator even when the animation is stopped.
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.white
        // Start animation.
        activityIndicator.stopAnimating()
        return activityIndicator }()
    
} //뷰 컨트롤러 끝

//api - key decode
extension String {
    func decodeUrl() -> String?{
        return self.removingPercentEncoding
        
    }
    func encodeUrl() -> String?{
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        
    }
    
}
