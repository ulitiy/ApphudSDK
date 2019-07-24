//
//  ApphudRequestManager.swift
// Apphud
//
//  Created by ren6 on 26/06/2019.
//  Copyright © 2019 Softeam Inc. All rights reserved.
//

import Foundation

typealias ApphudBoolDictionaryCallback = (Bool, [String : Any]?, Error?) -> Void

struct ApphudHttpClient {
    
    enum ApphudHttpMethod : String {
        case post = "POST"
        case get = "GET"
        case put = "PUT"
    }
    
    let apiKey : String
    private let domain_url_string = "https://api.apphud.com"
    
    private let session : URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession.init(configuration: config)
    }()
    
    func startRequest(path: String, params : [String : Any]?, method : ApphudHttpMethod, callback: @escaping ApphudBoolDictionaryCallback) {
        if let request = makeRequest(path: path, params: params, method: method) {
            start(request: request, callback: callback)
        }
    }
    
    private func makeRequest(path : String, params : [String : Any]?, method : ApphudHttpMethod) -> URLRequest? {
        var request: URLRequest? = nil
        do {
            var url: URL? = nil
            if method == .get {
                var components = URLComponents(string: "\(domain_url_string)/v1/\(path)")
                var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey)]
                if let requestParams = params {
                    for key in requestParams.keys {
                        items.append(URLQueryItem(name: key, value: requestParams[key] as? String))
                    }
                }
                components?.queryItems = items
                url = components?.url
            }
            else {
                url = URL(string: "\(domain_url_string)/v1/\(path)")
            }
            guard let finalURL = url else {
                return nil
            }
            
            request = URLRequest(url: finalURL, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 20)
            request?.httpMethod = method.rawValue
            request?.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request?.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
            
            if method != .get {
                var finalParams : [String : Any] = ["api_key" : apiKey]
                if params != nil {
                    finalParams.merge(params!, uniquingKeysWith: {$1})
                }
                let data = try JSONSerialization.data(withJSONObject: finalParams, options: [])
                request?.httpBody = data
            }
        } catch {
            
        }
        
        #if DEBUG
        apphudLog("Start request \(request?.url?.absoluteString ?? "") params: \(params ?? [:])")
        #endif
        
        return request
    }
    
    private func start(request: URLRequest, callback: ApphudBoolDictionaryCallback?){
        let task = session.dataTask(with: request) { (data, response, error) in
            
            var dictionary: [String : Any]?
            
            do {
                if data != nil {
                    dictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
                }
            } catch {
                
            }
                        
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    if code >= 200 && code < 300 {
                        
                        if data != nil {
                            let stringResponse = String(data: data!, encoding: .utf8)
                            apphudLog("Request \(request.url?.absoluteString ?? "") success with response: \n\(stringResponse ?? "")")
                        }
                        callback?(true, dictionary, nil)
                        return
                    }
                    apphudLog("Request \(request.url?.absoluteString ?? "") failed with code \(code), error: \(error?.localizedDescription ?? "") response: \(dictionary)")
                }
                
                callback?(false, nil, error)
            }
            
        }
        task.resume()
    }
}