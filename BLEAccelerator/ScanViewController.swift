//
//  ScanViewController.swift
//  BLEAccelerator
//
//  Created by しゅんた on 2018/04/28.
//  Copyright © 2018年 shunta shimizu. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxCocoa

class ScanViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    
    let scanTime: Double = 5
    
    //-------------Centralの初期化-------------
    var centralManager: CBCentralManager!
    fileprivate var peripherals = Variable<[CBPeripheral]>([])
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(scan), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        peripherals.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { (_, item: CBPeripheral, cell) in
                cell.textLabel?.text = item.name
                cell.detailTextLabel?.text = item.identifier.uuidString
            }
            .disposed(by: disposeBag)
    
        tableView.addSubview(refreshControl)
        tableView.rx
            .modelSelected(CBPeripheral.self)
            .subscribe(onNext: { (peripheral) in
                self.performSegue(withIdentifier: "Central", sender: peripheral.identifier)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        peripherals.value.removeAll()
        
        
        refreshControl.beginRefreshing()
        tableView.setContentOffset(
            CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.refreshControl.sendActions(for: .valueChanged)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let manager = centralManager else {return}
        if manager.isScanning{
            manager.stopScan()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super .didReceiveMemoryWarning()
    }
    
    //-------------BLEデバイスのスキャンを開始する。5秒経過後スキャンを停止します-------------
    @objc func scan(){
        guard let manager = centralManager else { return }
        if !manager.isScanning {
            manager.scanForPeripherals(withServices: nil, options: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + scanTime) { [weak self] in
                manager.stopScan()
                self?.refreshControl.endRefreshing()
            }
        } else {
            refreshControl.endRefreshing()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CentralViewController,
            let uuid = sender as? UUID {
            viewController.identifier = uuid.uuidString
        }
    }
}

extension ScanViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("%@, state: %d", #function, central.state.rawValue)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        //-------------今回は Peripheral側の名前を `BLE(001)` にしたのでそれだけ検出できるようにする-------------
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            name.lowercased().contains("ble") {
            if peripherals.value.filter( { $0 == peripheral } ).isEmpty {
                peripherals.value.append(peripheral)
            }
        }
    }
}

