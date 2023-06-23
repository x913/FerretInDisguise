//
//  File.swift
//
//
//  Created by Дмитрий on 23.06.2023.
//

import Foundation
import UIKit

public class FerretInDisguise {
    
    static func unmaskFerret(url: URL, onSuccess: @escaping (FerretResponse) -> Void, onFailed: @escaping (String) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpMethod = "POST"
        
        
        let ferretRequestAsJson = FerretInDisguise.buildFerretRequest().toJson()
        if(ferretRequestAsJson == nil) {
            onFailed("AAA Can't encode to JSON")
            return
        }
        
        request.httpBody = Data(ferretRequestAsJson!.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                    let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil
                else {                                                               // check for fundamental networking error
                    onFailed("AAA error \(error ?? URLError(.badServerResponse))")
                    return
                }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                onFailed("AAA statusCode should be 2xx, but is \(response.statusCode), response: \(response)")
                return
            }

            
            do {
                let cloakResponse = try JSONDecoder().decode(FerretResponse.self, from: data)
                onSuccess(cloakResponse)
            } catch {
                onFailed("AAA error \(error)")
            }
        }
        task.resume()
    }
    
    private static func buildFerretRequest() -> FerretRequest {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let dt = formatter.string(from: Date())
        
        return FerretRequest(
            bundleId: Bundle.main.bundleIdentifier ?? "",
            // bundleId: "com.game",
            osVersion: UIDevice.current.systemVersion,
            phoneModel: UIDevice.modelName,
            language: NSLocale.current.languageCode ?? "",
            phoneTime: dt,
            phoneTz: TimeZone.current.identifier,
            vpn: FerretInDisguise.isVpn())
    }
    
    private static func isVpn() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings() else { return false }
        let nsDict = cfDict.takeRetainedValue() as NSDictionary
        guard let keys = nsDict["__SCOPED__"] as? NSDictionary,
              let allKeys = keys.allKeys as? [String] else { return false }
 
        let protocols = [
            "tap", "tun", "ppp", "ipsec", "utun"
        ]
        
        for key in allKeys {
            for protocolId in protocols
                where key.starts(with: protocolId) {
                        return true
                }
        }
        return false
    }
        
}

extension FerretRequest {
    func toJson() -> String? {
        do {
            let json = try JSONEncoder().encode(self)
            return String(data: json, encoding: .utf8)
        } catch {
            print(error)
        }
        return nil
    }
}
