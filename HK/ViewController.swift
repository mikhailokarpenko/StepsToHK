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
    
    var healthStore: HKHealthStore?
    var typesToShare : Set<HKSampleType> {
        let stepType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
      return [stepType]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ViewController.authorizeHealthKit { (success, error) in
            print("authorized: \(success)")
        }
    }

    @IBAction func buttonPressed(_ sender: Any) {
        let value = Int.random(in: 500...1000)
        ViewController.saveSteps(stepsCountValue: value, date: Date()) { (error) in
            print("is saved: \(error)")
        }
    }
    
    public class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
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
           }
           
       }
    
    public class func saveSteps(stepsCountValue: Int,
                             date: Date,
                             completion: @escaping (Error?) -> Swift.Void) {
        
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
            
            if let error = error {
                completion(error)
                print("Error Saving Steps Count Sample: \(error.localizedDescription)")
            } else {
                completion(nil)
                print("Successfully saved Steps Count Sample")
            }
        }
        
    }
    
}

