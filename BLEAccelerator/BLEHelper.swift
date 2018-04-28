//
//  BLEHelper.swift
//  BLEAccelerator
//
//  Created by しゅんた on 2018/04/28.
//  Copyright © 2018年 shunta shimizu. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEHelper: NSObject {
    fileprivate var centralManager: CBCentralManager!
    fileprivate var peripheral: CBPeripheral?
    
    var action: ((Acceleration) -> Void)?
    var uuid: UUID?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //-------------PeripheralのUUIDを指定してPeripheralに接続開始します-------------
    func connect(identifier: String, action: ((Acceleration) -> Void)?) {
        self.uuid = UUID(uuidString: identifier)
        self.action = action
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //-------------Peripheralとの接続を切ります-------------
    func cancel() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
}

extension BLEHelper: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String, name.lowercased().contains("ble") {
            if peripheral.identifier == uuid {
                self.peripheral = peripheral
                //-------------Peripheralに接続を開始します-------------
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //-------------Peripheralに接続できたらサービスを探します-------------
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }
}

// MARK: - CBPeripheralDelegate

extension BLEHelper: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, !services.isEmpty else { return }
        for service in services {
            if service.uuid == Acceleration.UUID.service.uuid {
                //-------------加速度を取得するために通知を有効にします-------------
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics, !characteristics.isEmpty else { return }
        for characteristic in characteristics {
            if characteristic.uuid == Acceleration.UUID.characteristic.uuid {
                //-------------加速度の通知を受け取ったらコールバックする-------------
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            return
        }
        if characteristic.uuid == Acceleration.UUID.characteristic.uuid {
            let acc = Acceleration(bytes: data)
            self.action?(acc)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    }
}

// MARK: - Extensions

extension Data {
    init<T>(from value: T) {
        var v = value
        self.init(buffer: UnsafeBufferPointer(start: &v, count: 1))
    }
    
    init<T>(from values: [T]) {
        var v = values
        self.init(buffer: UnsafeBufferPointer(start: &v, count: v.count))
    }
    
    func to<T>(type: T.Type) -> T {
        return withUnsafeBytes { $0.pointee }
    }
}

extension Float {
    var bytes: Data {
        let data = Data(from: self)
        return data
    }
}

extension Int16 {
    var bytes: Data {
        let data = Data(from: self)
        return data
    }
}

