# UrlSessionDemo
Swift URLSession 网络请求

## 使用
```
// 显示日志
SycRequest.shared.shouldLog = true
// get 请求
SycRequest.shared.get(urlStr: "http://www.baidu.com/s?ie=UTF-8&wd=urlsession", param: nil) { (result) in
    // result is any
    // do something ...

    DispatchQueue.main.async(execute: {

		// update ui
    })
}
```

## URLSession
```
let request = URLRequest(url: url)
request.httpMethod = "POST"
// params
request.httpBody = data

let config = URLSessionConfiguration.default
let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)

let dataTask = session.dataTask(with: request) { (originData: Data?, response: URLResponse?, err: Error?) in
    // 解析封装数据            
}

// 启动
dataTask.resume()
```

含 https 证书请求 demo, 参考 [hangge](http://www.hangge.com/blog/cache/detail_991.html)

# Requirements
+ Swift 4
+ iOS 10+
+ Xcode 9+
