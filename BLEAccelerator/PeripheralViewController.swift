//
//  PeripheralViewController.swift
//  BLEAccelerator
//
//  Created by Kazuya Shida on 5/25/17.
//  Copyright © 2017 UniFa Co.,Ltd. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion
import RxSwift
import RxCocoa

class PeripheralViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logTextView: UITextView!
    
    //-------------CoreMotionの初期化-------------
    fileprivate let motionManager = CMMotionManager()
    fileprivate var peripheralManager: CBPeripheralManager?
    //-------------加速度を通知するキャラクタリスティック-------------
    fileprivate var characteristic: CBMutableCharacteristic?
    fileprivate var acceleration = Variable<Acceleration>(Acceleration())
    
    struct Item {
        let title: String
        var text: Variable<String?>
    }
    
    let items: [Item] = [
        Item(title: "Advertise Name", text: Variable<String?>(Acceleration.advertisementName))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //-------------peripheralManagerの初期化-------------
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        if let queue = OperationQueue.current {
            //-------------CoreMotionから加速度取得する間隔を設定-------------
            motionManager.accelerometerUpdateInterval = 0.2
            //-------------CoreMotionから加速度の値の受取を開始する-------------
            motionManager.startAccelerometerUpdates(to: queue) { [weak self] (data, _) in
                guard let data = data else { return }
                self?.acceleration.value = Acceleration(acceleration: data.acceleration)
            }
        }
        
        items[0].text
            .asObservable()
            .subscribe(
                onNext: { (text) in
                    Acceleration.advertisementName = text ?? ""
            }
            )
            .disposed(by: disposeBag)
        
        Observable.just(items)
            .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: PeripheralCell.self)) { [weak self] (_, item: Item, cell) in
                cell.titleLabel?.text = item.title
                cell.textField?.text = item.text.value
                cell.textField?.rx.text
                    .throttle(0.3, scheduler: MainScheduler.instance)
                    .bind(to: item.text)
                    .disposed(by: cell.disposeBag)
                cell.switchButton?.rx.value
                    .bind(onNext: { (active) in
                        if active {
                            
                            //-------------UI上にスイッチを用意しておりオンにするとアドバタイジングを開始します-------------
                            let data: [String: Any] = [
                                CBAdvertisementDataLocalNameKey: "\(Acceleration.advertisementName)",
                                CBAdvertisementDataServiceUUIDsKey: [Acceleration.UUID.service.uuid]
                            ]
                            self?.peripheralManager?.startAdvertising(data)
                        } else {
                            
                            //-------------スイッチをオフにするとアドバタイジングを終了します-------------
                            self?.peripheralManager?.stopAdvertising()
                        }
                    })
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)
        
        //-------------加速度の値が更新された場合Central側に通知を行う-------------
        acceleration.asObservable()
            .subscribe(
                onNext: { [weak self] (acceleration) in
                    guard let peripheral = self?.peripheralManager else {
                        return
                    }
                    guard let characteristic = self?.characteristic,
                        let centrals = characteristic.subscribedCentrals, !centrals.isEmpty else {
                            return
                    }
                    //-------------Centralと接続している場合は、Central側に加速度の値を通知する-------------
                    peripheral.updateValue(acceleration.data, for: characteristic, onSubscribedCentrals: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension PeripheralViewController: CBPeripheralManagerDelegate {
    
    //-------------Peripheralのステータスが変更されたら通知されます-------------
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logTextView.appendLog(text: "Update State: \(peripheral.state)")
        
        guard peripheral.state == .poweredOn else { return }
        
        //-------------加速度の値を通知するキャラクタリスティックを設定-------------
        let characteristic = CBMutableCharacteristic(
            type: Acceleration.UUID.characteristic.uuid,
            properties: .notify,
            value: nil,
            permissions: .readable
        )
        
        //-------------Peripheral側のサービスを設定-------------
        let service = CBMutableService(type: Acceleration.UUID.service.uuid, primary: true)
        service.characteristics = [characteristic]
        self.characteristic = characteristic
        self.peripheralManager?.add(service)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        logTextView.appendLog(text: "Add: \(service.description)")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            logTextView.appendLog(text: "\(error.localizedDescription)")
        }
        logTextView.appendLog(text: "Start Advertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logTextView.appendLog(text: "Subscription: \(central.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        logTextView?.appendLog(text: "Unsubscription")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        logTextView?.appendLog(text: "IsReady")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logTextView?.appendLog(text: "Receive read: \(request.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print(#function, dict)
        logTextView?.appendLog(text: "Restore State: \(dict)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    }
}

// MARK: - UIScrollViewDelegate

extension PeripheralViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

// MARK: - PeripheralCell

class PeripheralCell: UITableViewCell {
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var switchButton: UISwitch?
    @IBOutlet weak var textField: UITextField?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

// MARK: - UITextView

extension UITextView {
    func appendLog(text: String) {
        DispatchQueue.main.async {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let now = formatter.string(from: Date())
            self.text = String(format: "%@[%@] %@\n", self.text, now, text)
            self.setContentOffset(CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height), animated: true)
        }
    }
}

