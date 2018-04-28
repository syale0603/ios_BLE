//
//  CentralViewController.swift
//  BLEAccelerator
//
//  Created by しゅんた on 2018/04/28.
//  Copyright © 2018年 shunta shimizu. All rights reserved.
//

import UIKit
import CoreBluetooth
import Charts

class CentralViewController: UIViewController {
    @IBOutlet weak var chartView: LineChartView!
    
    struct Chart {
        static let xIndex: Int = 0
        static let yIndex: Int = 1
        static let zIndex: Int = 2
        static let maxDisplayedPoint: Int = 200
    }
    
    var identifier: String?
    fileprivate let bleHelper = BLEHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let data = LineChartData()
        data.addDataSet(createDataSet(color: UIColor.red, label: "x"))
        data.addDataSet(createDataSet(color: UIColor.green, label: "y"))
        data.addDataSet(createDataSet(color: UIColor.blue, label: "z"))
        
        chartView.data = data
        chartView.gridBackgroundColor = UIColor.white
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.chartDescription?.text = "Accelerator"
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMaximum = 1.5
        leftAxis.axisMinimum = -1.5
        
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let uuid = identifier else {
            return
        }
        
        bleHelper.connect(identifier: uuid) { [weak self] (acceleration) in
            guard let data = self?.chartView.data else { return }
            let xSet = data.dataSets[Chart.xIndex]
            let ySet = data.dataSets[Chart.yIndex]
            let zSet = data.dataSets[Chart.zIndex]
            if xSet.entryCount > Chart.maxDisplayedPoint {
                _ = xSet.removeFirst()
            }
            if ySet.entryCount > Chart.maxDisplayedPoint {
                _ = ySet.removeFirst()
            }
            if zSet.entryCount > Chart.maxDisplayedPoint {
                _ = zSet.removeFirst()
            }
            _ = xSet.addEntry(ChartDataEntry(x: Double(max(0, xSet.xMax) + 1), y: Double(acceleration.x)))
            _ = ySet.addEntry(ChartDataEntry(x: Double(max(0, ySet.xMax) + 1), y: Double(acceleration.y)))
            _ = zSet.addEntry(ChartDataEntry(x: Double(max(0, zSet.xMax) + 1), y: Double(acceleration.z)))
            data.notifyDataChanged()
            self?.chartView.notifyDataSetChanged()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bleHelper.cancel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func createDataSet(values: [ChartDataEntry] = [], color: UIColor, label: String) -> LineChartDataSet {
        let dataSet = LineChartDataSet(values: values, label: label)
        dataSet.colors = [color]
        dataSet.drawCirclesEnabled = false
        return dataSet
    }
}
