//
//  CustomWebView.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/6/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "CustomWebViewContainer.h"
#import <CommonCrypto/CommonCrypto.h>
#import "AppDelegate.h"

@interface WKWebView (Extension)

- (NSString *)getAlertTitle;

@end

@implementation WKWebView (Extension)

- (NSString *)getAlertTitle {
    if (self.URL && self.URL.host) {
        return [NSString stringWithFormat:@"来自%@的消息", self.URL.host];
    }
    return @"来自网页的消息";
}

@end

@implementation CustomWebViewContainer

static NSMutableDictionary *sharedTokenPools = nil;
static dispatch_once_t onceSharedProcessPool;
static NSMutableDictionary *sharedDataSources = nil;
static dispatch_once_t onceSharedDataSource;

+ (NSUUID *)uuidFromString:(NSString *)str {
    // Generate SHA256 hash
    const char *cStr = [str UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, (CC_LONG)strlen(cStr), result);

    // Use first 16 bytes as UUID
    uuid_t uuidBytes;
    memcpy(uuidBytes, result, 16);

    // Set variant and version bits to make a valid UUID (version 4)
    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40; // Version 4
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80; // Variant 1

    return [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
}

+ (WKProcessPool *)sharedProcessPoolForToken:(NSString *)token {
    dispatch_once(&onceSharedProcessPool, ^{
        sharedTokenPools = [[NSMutableDictionary alloc] init];
    });
    @synchronized (sharedTokenPools) {
        if (!token) {
            token = @"";
        }
        if (!sharedTokenPools[token]) {
            sharedTokenPools[token] = [[WKProcessPool alloc] init];
        }
        return sharedTokenPools[token];
    }
}

+ (WKWebsiteDataStore *)sharedDataSourceForToken:(NSString *)token {
    dispatch_once(&onceSharedDataSource, ^{
        sharedDataSources = [[NSMutableDictionary alloc] init];
    });
    @synchronized (sharedDataSources) {
        if (!token) {
            token = @"";
        }
        if (!sharedDataSources[token]) {
            if (token.length == 0) {
                sharedDataSources[token] = [WKWebsiteDataStore defaultDataStore];
            } else {
                if (@available(iOS 17.0, *)) {
                    sharedDataSources[token] = [WKWebsiteDataStore dataStoreForIdentifier:[CustomWebViewContainer uuidFromString:token]];
                } else {
                    sharedDataSources[token] = [WKWebsiteDataStore nonPersistentDataStore];
                }
                NSURL *url = [NSURL URLWithString:CHEXIE];
                if (!url || !url.host) {
                    NSString *fixedString = [@"https://" stringByAppendingString:CHEXIE];
                    url = [NSURL URLWithString:fixedString];
                }
                if (url && url.host) {
                    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
                        NSHTTPCookieDomain: url.host,
                        NSHTTPCookiePath: @"/",
                        NSHTTPCookieName: @"token",
                        NSHTTPCookieValue: token
                    }];
                    WKWebsiteDataStore *dataStore = sharedDataSources[token];
                    [dataStore.httpCookieStore setCookie:cookie completionHandler:nil];
                }
            }
        }
        return sharedDataSources[token];
    }
}

+ (NSArray<WKWebsiteDataStore *> *)getAllDataSources {
    dispatch_once(&onceSharedDataSource, ^{
        sharedDataSources = [[NSMutableDictionary alloc] init];
    });
    @synchronized (sharedDataSources) {
        return sharedDataSources.allValues;
    }
}

- (void)initiateWebViewForToken:(NSString *)token {
    WKProcessPool *processPool = [CustomWebViewContainer sharedProcessPoolForToken:token];
    WKWebsiteDataStore *dataStore = [CustomWebViewContainer sharedDataSourceForToken:token];
    
    if (_webView) {
        WKWebViewConfiguration *config = _webView.configuration;
        // No need to update here
        if (config.processPool == processPool && config.websiteDataStore == dataStore) {
            return;
        }
        
        [_webView stopLoading];
        _webView.navigationDelegate = nil;
        _webView.UIDelegate = nil;
        [_webView removeConstraints:_webView.constraints];
        [_webView removeFromSuperview];
    }
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.dataDetectorTypes = WKDataDetectorTypeAll;
    config.processPool = processPool;
    config.websiteDataStore = dataStore;
    config.allowsInlineMediaPlayback = YES;
    
    NSError *error = nil;
    NSString *injectionContent = [NSString stringWithContentsOfFile:INJECTION_JS encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:injectionContent
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                       forMainFrameOnly:NO];
        [userContentController addUserScript:userScript];
        config.userContentController = userContentController;
    } else {
        NSLog(@"Failed to load injection script: %@", error);
    }

    _webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:config];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.UIDelegate = self;
    [self addSubview:_webView];
    [NSLayoutConstraint activateConstraints:@[
        [_webView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(WK_SWIFT_UI_ACTOR void (^)(void))completionHandler {
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        completionHandler();
        return;
    }
    [viewController showAlertWithTitle:[webView getAlertTitle] message:message confirmTitle:nil confirmAction:nil cancelTitle:@"好" cancelAction:^(UIAlertAction *action) {
        completionHandler();
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull WK_SWIFT_UI_ACTOR void (^)(BOOL))completionHandler {
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        completionHandler(NO);
        return;
    }
    [viewController showAlertWithTitle:[webView getAlertTitle] message:message confirmTitle:@"确定" confirmAction:^(UIAlertAction *action) {
        completionHandler(YES);
    } cancelTitle:@"取消" cancelAction:^(UIAlertAction *action) {
        completionHandler(NO);
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(WK_SWIFT_UI_ACTOR void (^)(NSString * _Nullable))completionHandler {
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        completionHandler(nil);
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[webView getAlertTitle] message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.text = defaultText;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
        completionHandler(nil);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        NSString *input = alert.textFields.firstObject.text;
        completionHandler(input);
    }]];
    [viewController presentViewControllerSafe:alert];
}

@end
