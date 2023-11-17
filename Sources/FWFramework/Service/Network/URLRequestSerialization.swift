//
// URLRequestSerialization.swift
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

// MARK: - MultipartFormData
/// 多段表单数据协议
public protocol MultipartFormData: AnyObject {
    
    /// 添加文件，自动使用fileName和mimeType
    func appendPart(fileURL: URL, name: String)
    
    /// 添加文件，指定fileName和mimeType
    func appendPart(fileURL: URL, name: String, fileName: String, mimeType: String)
    
    /// 添加输入流，指定fileName和mimeType
    func appendPart(inputStream: InputStream?, name: String, fileName: String, length: Int64, mimeType: String)
    
    /// 添加文件数据，指定fileName和mimeType
    func appendPart(fileData: Data, name: String, fileName: String, mimeType: String)
    
    /// 添加表单数据
    func appendPart(formData: Data, name: String)
    
    /// 添加头信息和主题数据
    func appendPart(headers: [String: String]?, body: Data)
    
    /// 限制请求带宽
    func throttleBandwidth(packetSize numberOfBytes: UInt, dalay: TimeInterval)
    
}
