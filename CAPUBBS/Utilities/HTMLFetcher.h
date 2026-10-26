//
//  HTMLFetcher.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 9/4/26.
//  Copyright © 2026 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HTMLFetcherCompletion)(NSString * _Nullable html, NSError * _Nullable error);

@interface HTMLFetcher : NSObject

/**
 抓取指定 URL 在 JS 执行后的 HTML 内容（支持注入 Cookie）
 
 @param url 目标 URL
 @param cookieDict 需要注入的 Cookie 列表
 @param delayInSeconds 页面加载完成后额外等待的秒数（适合等待 AJAX / 异步渲染）
 @param completion 完成回调
 */
+ (void)fetchHTMLWithURL:(NSURL *)url
              cookieDict:(nullable NSDictionary<NSString *, NSString *> *)cookieDict
                   delay:(NSTimeInterval)delayInSeconds
              completion:(HTMLFetcherCompletion)completion;

@end

NS_ASSUME_NONNULL_END
