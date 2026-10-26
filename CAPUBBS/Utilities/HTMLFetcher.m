//
//  HTMLFetcher.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 9/4/26.
//  Copyright © 2026 熊典. All rights reserved.
//

#import "HTMLFetcher.h"
#import <WebKit/WebKit.h>

@interface HTMLFetcher () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) HTMLFetcherCompletion completion;
@property (nonatomic, assign) NSTimeInterval delayInSeconds;
@property (nonatomic, strong) HTMLFetcher *selfRetain; // 防止异步回调前实例被释放

@end

@implementation HTMLFetcher

+ (void)fetchHTMLWithURL:(NSURL *)url
              cookieDict:(nullable NSDictionary<NSString *, NSString *> *)cookieDict
                   delay:(NSTimeInterval)delayInSeconds
              completion:(HTMLFetcherCompletion)completion {
    dispatch_main_async_safe(^{
        HTMLFetcher *fetcher = [[HTMLFetcher alloc] init];
        [fetcher startFetchingURL:url cookieDict:cookieDict delay:delayInSeconds completion:completion];
    });
}

- (void)startFetchingURL:(NSURL *)url
              cookieDict:(nullable NSDictionary<NSString *, NSString *> *)cookieDict
                   delay:(NSTimeInterval)delay
              completion:(HTMLFetcherCompletion)completion {
    self.completion = completion;
    self.delayInSeconds = delay;
    self.selfRetain = self; // 保持对象生命周期
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 400, 800) configuration:config];
    self.webView.navigationDelegate = self;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:30.0];
    
    // 如果有 Cookie，异步写入 WKHTTPCookieStore 成功后再发起加载
    NSArray<NSHTTPCookie *> *cookies = [self cookiesFromDictionary:cookieDict forURL:url];
    if (cookies && cookies.count > 0) {
        WKHTTPCookieStore *cookieStore = self.webView.configuration.websiteDataStore.httpCookieStore;
        dispatch_group_t group = dispatch_group_create();
        
        for (NSHTTPCookie *cookie in cookies) {
            dispatch_group_enter(group);
            [cookieStore setCookie:cookie completionHandler:^{
                dispatch_group_leave(group);
            }];
        }
        
        __weak typeof(self) weakSelf = self;
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [weakSelf.webView loadRequest:request];
        });
    } else {
        [self.webView loadRequest:request];
    }
}

#pragma mark - Helper Methods

- (NSArray<NSHTTPCookie *> *)cookiesFromDictionary:(NSDictionary<NSString *, NSString *> *)dict forURL:(NSURL *)url {
    if (!dict || dict.count == 0 || !url.host) {
        return @[];
    }
    
    NSMutableArray<NSHTTPCookie *> *cookies = [NSMutableArray array];
    NSString *domain = url.host;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
            NSMutableDictionary *properties = [NSMutableDictionary dictionary];
            properties[NSHTTPCookieName] = key;
            properties[NSHTTPCookieValue] = value;
            properties[NSHTTPCookieDomain] = domain;
            properties[NSHTTPCookiePath] = @"/";
            
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:properties];
            if (cookie) {
                [cookies addObject:cookie];
            }
        }
    }];
    
    return [cookies copy];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.delayInSeconds > 0) {
        dispatch_main_after(self.delayInSeconds, ^{
            [self extractHTML];
        });
    } else {
        [self extractHTML];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self handleCompletionWithHTML:nil error:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self handleCompletionWithHTML:nil error:error];
}

#pragma mark - Private Helper

- (void)extractHTML {
    NSString *jsScript = @"document.documentElement.outerHTML;";
    [self.webView evaluateJavaScript:jsScript completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            [self handleCompletionWithHTML:nil error:error];
        } else if ([result isKindOfClass:[NSString class]]) {
            [self handleCompletionWithHTML:(NSString *)result error:nil];
        } else {
            NSError *customError = [NSError errorWithDomain:@"HTMLFetcherErrorDomain"
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Unable to parse DOM content"}];
            [self handleCompletionWithHTML:nil error:customError];
        }
    }];
}

- (void)handleCompletionWithHTML:(NSString *)html error:(NSError *)error {
    if (self.completion) {
        self.completion(html, error);
        self.completion = nil;
    }
    
    // 清理资源，打断循环引用
    self.webView.navigationDelegate = nil;
    self.webView = nil;
    self.selfRetain = nil;
}

@end
