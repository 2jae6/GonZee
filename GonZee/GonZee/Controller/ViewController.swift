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
    
    
    //xml 필요 변수들 시작
    var currentElement = ""
    
    class CheckStation{
        var checkS:String?
    }
    var checkArray: Array<String> = []
    var checkStation:CheckStation?
    //xml 필요변수들 끝
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        //위도 경도 획득 및 TM 변환
        locationMan()
        
        
    }//viewdidload 끝
    //위도 경도 획득 메서드
    func locationMan(){
        
        
        //locationMager 인스턴스 생성 및 델리게이트 생성
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        //포그라운드 상태에서 위치 추적 권한 요청
        locationManager.requestWhenInUseAuthorization()
        
        //배터리에 맞게 권장되는 최적의 정확도
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //위치업데이트
        locationManager.startUpdatingLocation()
        
        //위도 경도 가져오기
        guard let coor = locationManager.location?.coordinate else{
            print("coor 으악")
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
            print("으악")
            return
        }
        
        guard let tmY = self.defData.tmY else{
            print("으악")
            return
        }
        
        let param:Parameters = [
            "ServiceKey" : api_key_decode!,
            "tmX" : tmX,
            "tmY" : tmY
            
            
        ]
        
        /*
         // JSON 데이터 호출 로그
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
        
        
        
        //XML Parser Delegate
        
        
        print(checkArray)
        
        
    }//nearchecker()끝
    
    //method
    // XML 파서가 시작 테그를 만나면 호출됨
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        
        currentElement = elementName
        
        
        if elementName == "stationName"{
            checkStation = CheckStation()
            
            
        }
    }
    
    // 현재 테그에 담겨있는 문자열 전달
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        
        switch currentElement {
        case "stationName":
            checkStation?.checkS = string
            
        default:
            break;
        }
    }
    
    // XML 파서가 종료 테그를 만나면 호출됨
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "stationName"{
            checkArray.append(checkStation!.checkS!)
        }
    }
    
    
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
