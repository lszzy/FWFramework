// UIImageView+FWNetwork.h
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

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FWImageDownloader;

/**
 This category adds methods to the UIKit framework's `UIImageView` class. The methods in this category provide support for loading remote images asynchronously from a URL.
 */
@interface UIImageView (FWNetwork)

///------------------------------------
/// @name Accessing the Image Downloader
///------------------------------------

/**
 Set the shared image downloader used to download images.

 @param imageDownloader The shared image downloader used to download images.
 */
+ (void)fwSetSharedImageDownloader:(FWImageDownloader *)imageDownloader;

/**
 The shared image downloader used to download images.
 */
+ (FWImageDownloader *)fwSharedImageDownloader;

///--------------------
/// @name Setting Image
///--------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 By default, URL requests have a `Accept` header field value of "image / *", a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`

 @param url The URL used for the image request.
 */
- (void)fwSetImageWithURL:(NSURL *)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 By default, URL requests have a `Accept` header field value of "image / *", a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`

 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 */
- (void)fwSetImageWithURL:(NSURL *)url
         placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.
 
 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 If a completion block is specified, it is the responsibility of the block to set the image of the image view before returning. If no completion block is specified, the default behavior of setting the image with `self.fwImage = image` is applied.
 
 @param url The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes completely. If `nil`, the image view will not change its image until the image request finishes.
 @param completion A block to be executed when the image data task finishes. This block has no return value and takes two arguments: the image created from the response data of request, and the error object describing the network or parsing error that occurred. If the image was returned from cache, the error parameter will be `nil`.
 */
- (void)fwSetImageWithURL:(NSURL *)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

/**
 Asynchronously downloads an image from the specified URL request, and sets it once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the image view before returning. If no success block is specified, the default behavior of setting the image with `self.fwImage = image` is applied.

 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 @param progress A block object to be executed when the image data task executing. This block has no return value and takes one argument: the progress received from the server.
 */
- (void)fwSetImageWithURLRequest:(NSURLRequest *)urlRequest
                placeholderImage:(nullable UIImage *)placeholderImage
                         success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                         failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                         progress:(nullable void (^)(NSProgress *downloadProgress))progress;

/**
 Cancels any executing image operation for the receiver, if one exists.
 */
- (void)fwCancelImageDownloadTask;

@end

NS_ASSUME_NONNULL_END

#endif
