//
//  Acceleration.swift
//  BLEAccelerator
//
//  Created by しゅんた on 2018/04/28.
//  Copyright © 2018年 shunta shimizu. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreMotion

struct Acceleration {
    var x: Float
    var y: Float
    var z: Float
    
    init() {
        x = 0
        y = 0
        z = 0
    }
    
    init(acceleration: CMAcceleration) {
        x = Float(acceleration.x)
        y = Float(acceleration.y)
        z = Float(acceleration.z)
    }
    
    //-------------Central側で受け取ったデータをパースする-------------
    init(bytes: Data) {
        x = Data(bytes[0..<4]).to(type: Float.self)
        y = Data(bytes[4..<8]).to(type: Float.self)
        z = Data(bytes[8..<12]).to(type: Float.self)
    }
    //-------------Peripheral側から送るデータ形式-------------
    //-------------XYZ軸の各値Floatで4バイト×3軸で12バイトの値を送信します-------------
    var data: Data {
        var data = Data()
        data.append(x.bytes)
        data.append(y.bytes)
        data.append(z.bytes)
        return data
    }
    
    enum UUID: String {
        //-------------Peripheral側のサービスのUUIDを "0011"-------------
        case service = "0011"
        //-------------加速度の値を送信するキャラクタリスティックのUUID-------------
        case characteristic = "0012"
        
        var uuid: CBUUID {
            return CBUUID(string: self.rawValue)
        }
    }
    
    static var advertisementName: String {
        get {
            return UserDefaults.standard.object(forKey: "AdvertisementName") as? String ?? "BLE(001)"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AdvertisementName")
            UserDefaults.standard.synchronize()
        }
    }
}
