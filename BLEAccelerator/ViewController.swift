//
//  ViewController.swift
//  BLEAccelerator
//
//  Created by しゅんた on 2018/04/27.
//  Copyright © 2018年 shunta shimizu. All rights reserved.
//
import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!
    
    struct Item {
        let title: String
        let subtitle: String
        let identifier: String
    }
    
    let items: [Item] = [
        Item(
            title: "01. Central",
            subtitle: "Peripheralの検出と取得した加速度の値を表示します",
            identifier:"Scan"
        ),
        Item(title: "02. Peripheral",
             subtitle: "Advertisingの開始とCentralに加速度の値を送信します",
             identifier: "Peripheral"
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Observable.just(items)
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { (_, item: Item, cell) in
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = item.subtitle
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(Item.self)
            .subscribe(onNext: {[weak self] (item) in
                self?.performSegue(withIdentifier: item.identifier, sender: nil)
            })
            // .addDisposableTo(disposeBag) <-こっちかも
            .disposed(by: disposeBag)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

