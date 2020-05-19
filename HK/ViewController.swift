//
//  ViewController.swift
//  HK
//
//  Created by Mike on 19.05.20.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var totalCountLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        authorizeHealthKit { (success, error) in
            print("authorized: \(success)")
        }
    }

    @IBAction func buttonPressed(_ sender: Any) {
        let value = Int.random(in: 500...1000)
        saveSteps(stepsCountValue: value, date: Date())
    }
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
           guard HKHealthStore.isHealthDataAvailable() else {
            print("error")
               return
           }
    
           guard let stepsCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("error")
                   return
           }
           
           let healthKitTypesToWrite: Set<HKSampleType> = [stepsCount,
                                                           HKObjectType.workoutType()]
           
           let healthKitTypesToRead: Set<HKObjectType> = [stepsCount,
                                                          HKObjectType.workoutType()]
           
           HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                                read: healthKitTypesToRead) { (success, error) in
                                                   completion(success, error)
                                                    self.getTodaysSteps { (count) in
                                                        DispatchQueue.main.async {
                                                            self.totalCountLabel.text = "Total count: \(count)"
                                                        }
                                                    }
           }
           
       }
    
    func saveSteps(stepsCountValue: Int,
                             date: Date) {
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            fatalError("Step Count Type is no longer available in HealthKit")
        }
        
        let stepsCountUnit:HKUnit = HKUnit.count()
        let stepsCountQuantity = HKQuantity(unit: stepsCountUnit,
                                           doubleValue: Double(stepsCountValue))
        
        let stepsCountSample = HKQuantitySample(type: stepCountType,
                                               quantity: stepsCountQuantity,
                                               start: date,
                                               end: date)
        
        HKHealthStore().save(stepsCountSample) { (success, error) in
            
            DispatchQueue.main.async {
                if let error = error {
                    self.label.text = "ERROR: \(error)"
                    self.label.sizeToFit()
                } else {
                    self.label.text = "Successfully added \(stepsCountValue)"
                    self.label.sizeToFit()
                    self.getTodaysSteps { (count) in
                        DispatchQueue.main.async {
                            self.totalCountLabel.text = "Total count: \(count)"
                        }
                    }
                }
            }
        }
        
    }
    
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }

        HKHealthStore().execute(query)
    }
    
}

