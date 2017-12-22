//
//  SycRequest.swift
//  SycDemo
//
//  Created by rigour on 2017/12/18.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import Foundation

// target —> buildSettings —> swift flag —> Debug -> -D DEBUG
// 在项目中实现：#if DEBUG    #endif
// 这里 T 表示不指定 message参数类型
func SYCLog<T>(_ msg: T, filePath: String = #file, methodName: String = #function, lineNumber: Int = #line, columnNumber: Int = #column){
    
    #if DEBUG
        
        let fileName = (filePath as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        
        print("\n\t \(fileName).\(methodName):(\(lineNumber):\(columnNumber)) - \(msg)")
        
    #endif
}

//定义一个结构体，存储认证相关信息
struct IdentityAndTrust {
    var identityRef:SecIdentity
    var trust:SecTrust
    var certArray:AnyObject
}

// 参考 http://www.hangge.com/blog/cache/detail_991.html

class SycRequest: NSObject {
    public static let shared: SycRequest = SycRequest()
    
    public var shouldLog: Bool!

    override init() {
        shouldLog = false
    }
    
    /// get 请求
    public func get(urlStr: String, param: [String: Any?]?, completed: @escaping (_ result: Any) -> Void){
        guard let url = URL(string: urlStr) else{
            return
        }
        let request = URLRequest(url: url)
        self.http(request: request, completed: completed)
    }
    
    /// post 请求
    public func post(urlStr: String, param: [String: Any?]?, completed: @escaping (_ result: Any) -> Void){
        guard let url = URL(string: urlStr) else{
            return
        }
        
        var request = URLRequest(url: url)
        
        if param != nil && param?.isEmpty == false{
            do{
                let data = try JSONSerialization.data(withJSONObject: param!, options: JSONSerialization.WritingOptions.prettyPrinted)
                // 设置参数
                request.httpBody = data
            }catch let err{
                SYCLog("参数解析异常 \(err)")
            }
        }
        
        request.httpMethod = "POST"
        self.http(request: request, completed: completed)
    }
    
    private func http(request: URLRequest, completed: @escaping (_ result: Any) -> Void ){
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request) { (originData: Data?, response: URLResponse?, err: Error?) in
            guard let data = originData else{
                completed("无数据")
                return
            }
            
            if SycRequest.shared.shouldLog {
                if let urlStr = request.url?.absoluteString{
                    SYCLog("接口 " + urlStr)
                }
                if let body = request.httpBody {
                    SYCLog("参数 " + (String(data: body, encoding: String.Encoding.utf8) ?? "none"))
                }
                if let str = String(data: data, encoding: String.Encoding.utf8){
                    SYCLog("结果 "+str)
                }
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // 封装固定格式
                    // ...
                    completed(data)
                } else {
                    //通知UI接口失败
                    completed("接口调用失败")
                }
            }
            
        }
        // 启动
        dataTask.resume()
    }
}

extension SycRequest: URLSessionDelegate{
    // MARK: url session delegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == (NSURLAuthenticationMethodServerTrust) {
            //认证服务器证书
            if shouldLog {
                SYCLog("服务端证书认证！")
            }
            guard let trust: SecTrust = challenge.protectionSpace.serverTrust else{
                return
            }
            
            // 单向认证
            completionHandler(
                URLSession.AuthChallengeDisposition.useCredential,
                URLCredential(trust: trust)
            )
            /*
            // 双向认证
            let serverTrust: SecTrust = challenge.protectionSpace.serverTrust!
            let certificate: SecCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
            let remoteCertificateData = CFBridgingRetain(SecCertificateCopyData(certificate))!
            // 本地证书
            let cerPath: String = Bundle.main.path(forResource: "tomcat", ofType: "cer")!
            let cerUrl: URL = URL(fileURLWithPath:cerPath)
            let localCertificateData: Data = try! Data(contentsOf: cerUrl)
            
            if (remoteCertificateData.isEqual(localCertificateData) == true) {
                let credential = URLCredential(trust: serverTrust)
                challenge.sender?.use(credential, for: challenge)
                completionHandler(
                    URLSession.AuthChallengeDisposition.useCredential,
                    URLCredential(trust: challenge.protectionSpace.serverTrust!)
                )
                
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            */
            
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            //认证客户端证书
            if shouldLog {
                SYCLog("客户端证书认证！")
            }
            //获取客户端证书相关信息
            let identityAndTrust:IdentityAndTrust = self.extractIdentity()
            let urlCredential:URLCredential = URLCredential(
                identity: identityAndTrust.identityRef,
                certificates: identityAndTrust.certArray as? [Any],
                persistence: URLCredential.Persistence.forSession)
            
            completionHandler(.useCredential, urlCredential)
        } else {
            // 其它情况（不接受认证）
            if shouldLog {
                SYCLog("其它情况（不接受认证）")
            }
            completionHandler(.cancelAuthenticationChallenge, nil);
        }
    }
    // MARK: custom method
    //获取客户端证书相关信息
    func extractIdentity() -> IdentityAndTrust {
        var identityAndTrust:IdentityAndTrust!
        var securityError:OSStatus = errSecSuccess
        
        // 本地证书
        let path: String = Bundle.main.path(forResource: "mykey", ofType: "p12")!
        let PKCS12Data = NSData(contentsOfFile:path)!
        let key : NSString = kSecImportExportPassphrase as NSString
        let options : NSDictionary = [key : "123456"] //客户端证书密码
        
        var items : CFArray?
        
        securityError = SecPKCS12Import(PKCS12Data, options, &items)
        if securityError == errSecSuccess {
            let certItems:CFArray = items as CFArray!;
            let certItemsArray:Array = certItems as Array
            let dict:AnyObject? = certItemsArray.first;
            if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {
                // grab the identity
                let identityPointer:AnyObject? = certEntry["identity"];
                let secIdentityRef:SecIdentity = identityPointer as! SecIdentity!
                // grab the trust
                let trustPointer:AnyObject? = certEntry["trust"]
                let trustRef:SecTrust = trustPointer as! SecTrust
                // grab the cert
                let chainPointer:AnyObject? = certEntry["chain"]
                identityAndTrust = IdentityAndTrust(
                    identityRef: secIdentityRef,
                    trust: trustRef, certArray:  chainPointer!
                )
            }
        }
        return identityAndTrust;
    }
}
