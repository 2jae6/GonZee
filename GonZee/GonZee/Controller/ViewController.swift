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
class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var tttt: UITextView!
    //LocationManager 선언
    var locationManager:CLLocationManager!
    
    //DefalutData 선언
    var defaultData: DefaultData!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //위도 경도 획득 및 TM 변환
        locationMan()
        
    
        
    }
    
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
            return
        }
        print(coor)
        let latitude = coor.latitude
        let longitude = coor.longitude
        
        defaultData?.latitude = latitude
        defaultData?.longitude = longitude
        //DefaultData 인스턴스 생성
        
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
         print(latitude)
         print(longitude)
         let url = "https://dapi.kakao.com/v2/local/geo/transcoord.json"
         let param:Parameters = [
         "y": latitude,
         "x": longitude,
         "input_coord" : "WGS84",
         "output_coord": "TM"]
         
         let headers: HTTPHeaders = ["Authorization":"KakaoAK 3b9622f0285c753ec6c27f91e263812d"]
         
         
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
         
         Alamofire.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: headers).responseObject{
         (response: DataResponse<TMConvertDTO>) in
         let tmConvertDTO = response.result.value
         
         
         print(tmConvertDTO!.documents)
            print(tmConvertDTO!.documents![0].x)
            print(tmConvertDTO!.documents![0].y)
            
         
         
         }
         
    }
 
    
}
