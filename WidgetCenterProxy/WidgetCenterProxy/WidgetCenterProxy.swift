//
//  WidgetCenterProxy.swift
//  WidgetCenterProxy
//
//  Created by huszarcsaba on 2020. 09. 22..
//

import Foundation
import WidgetKit
import Intents
import StoreKit

@available(iOS 14.0, *)
@objc(WidgetCenterProxy)
public class WidgetCenterProxy : NSObject {
    
    @objc
    public func reloadTimeLines(ofKind: String){
        WidgetCenter.shared.reloadTimelines(ofKind: ofKind)
    }
    
    @objc
    public func reloadAllTimeLines(){
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @objc
    public func getCurrentConfigurations( completion: @escaping ([WidgetInfoProxy]) -> Void){
        WidgetCenter.shared.getCurrentConfigurations { results in
           
            do {
                let value = try results.get()
                
                var widgetInfoArr:[WidgetInfoProxy] = []
                
                for widgetInfo in value {
                    
                    let proxy = WidgetInfoProxy()
                    proxy.kind = widgetInfo.kind
                    proxy.family = widgetInfo.family.rawValue
                    proxy.configuration = widgetInfo.configuration
                    
                    widgetInfoArr.append(proxy)
                    
                }
                
                completion(widgetInfoArr)
                
            } catch {
                
                let proxy = WidgetInfoProxy()
                proxy.kind = "error"
                proxy.family = 0
                proxy.configuration = nil
                
                completion([proxy])
            }
           
            
            
        }
    }
}

@available(iOS 16.0, *)
@objc(StoreKitPurchaseHistoryProxy)
public final class StoreKitPurchaseHistoryProxy: NSObject {
    private struct Result: Codable {
        let schemaVersion: Int
        let fetchedAt: String
        let environment: String
        let purchases: [Purchase]
    }

    private struct Purchase: Codable {
        let productId: String
        let productType: String
        let purchasedAt: String
        let originalPurchasedAt: String
        let signedTransaction: String
    }

    @objc
    public func fetchPurchaseHistory(
        completion: @escaping (String?, String?) -> Void
    ) {
        Task {
            do {
                var purchases: [Purchase] = []
                var environment = "Unknown"

                for await verificationResult in Transaction.all {
                    guard case .verified(let transaction) = verificationResult,
                          transaction.ownershipType == .purchased,
                          transaction.revocationDate == nil else {
                        continue
                    }

                    environment = String(describing: transaction.environment)
                    purchases.append(Purchase(
                        productId: transaction.productID,
                        productType: String(describing: transaction.productType),
                        purchasedAt: transaction.purchaseDate.ISO8601Format(),
                        originalPurchasedAt: transaction.originalPurchaseDate.ISO8601Format(),
                        signedTransaction: verificationResult.jwsRepresentation
                    ))
                }

                purchases.sort {
                    if $0.purchasedAt == $1.purchasedAt {
                        return $0.productId < $1.productId
                    }
                    return $0.purchasedAt < $1.purchasedAt
                }

                let result = Result(
                    schemaVersion: 1,
                    fetchedAt: Date().ISO8601Format(),
                    environment: environment,
                    purchases: purchases
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                let data = try encoder.encode(result)
                guard let json = String(data: data, encoding: .utf8) else {
                    throw EncodingError.invalidValue(
                        result,
                        EncodingError.Context(
                            codingPath: [],
                            debugDescription: "StoreKit result was not UTF-8"
                        )
                    )
                }
                await MainActor.run {
                    completion(json, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error.localizedDescription)
                }
            }
        }
    }
}
