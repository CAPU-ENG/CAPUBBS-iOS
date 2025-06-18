//
//  CustomWebView.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/6/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "CustomWebViewContainer.h"
//#import <CommonCrypto/CommonCrypto.h>
#import "AppDelegate.h"

// Just a random UUID
#define UUID @"1ff24b67-2a92-41d9-9139-18be48987f3a"

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

static NSMutableDictionary *sharedProcessPools = nil;
static dispatch_once_t onceSharedProcessPool;
static NSMutableDictionary *sharedDataSources = nil;
static dispatch_once_t onceSharedDataSource;

//+ (NSUUID *)uuidFromString:(NSString *)str {
//    // Generate SHA256 hash
//    const char *cStr = [str UTF8String];
//    unsigned char result[CC_SHA256_DIGEST_LENGTH];
//    CC_SHA256(cStr, (CC_LONG)strlen(cStr), result);
//
//    // Use first 16 bytes as UUID
//    uuid_t uuidBytes;
//    memcpy(uuidBytes, result, 16);
//
//    // Set variant and version bits to make a valid UUID (version 4)
//    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40; // Version 4
//    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80; // Variant 1
//
//    return [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
//}

+ (void)clearAllDataStores:(void (^)(void))completionHandler {
    dispatch_main_sync_safe(^{
        NSMutableArray<WKWebsiteDataStore *> *dataStores = [NSMutableArray arrayWithObject:[WKWebsiteDataStore defaultDataStore]];
        dispatch_group_t group = dispatch_group_create();
        if (@available(iOS 17.0, *)) {
            dispatch_group_enter(group);
            [WKWebsiteDataStore fetchAllDataStoreIdentifiers:^(NSArray<NSUUID *> *uuids) {
                for (NSUUID *uuid in uuids) {
                    dispatch_group_enter(group);
                    [WKWebsiteDataStore removeDataStoreForIdentifier:uuid completionHandler:^(NSError *error) {
                        if (error) {
                            NSLog(@"Error removing data store for UUID: %@. Error: %@", uuid, error);
                        }
                        dispatch_group_leave(group);
                    }];
                }
                dispatch_group_leave(group);
            }];
        } else {
            [dataStores addObject:[WKWebsiteDataStore nonPersistentDataStore]];
        }
        
        NSSet *types = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *since = [NSDate dateWithTimeIntervalSince1970:0];
        for (WKWebsiteDataStore *dataStore in dataStores) {
            dispatch_group_enter(group);
            [dataStore removeDataOfTypes:types modifiedSince:since completionHandler:^{
                dispatch_group_leave(group);
            }];
        }
        // wait for all removal to complete
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

+ (WKProcessPool *)sharedProcessPoolWithToken:(BOOL)hasToken {
    dispatch_once(&onceSharedProcessPool, ^{
        sharedProcessPools = [[NSMutableDictionary alloc] init];
    });
    @synchronized (sharedProcessPools) {
        NSNumber *key = @(hasToken);
        if (!sharedProcessPools[key]) {
            sharedProcessPools[key] = [[WKProcessPool alloc] init];
        }
        return sharedProcessPools[key];
    }
}

+ (WKWebsiteDataStore *)sharedDataSourceWithToken:(BOOL)hasToken {
    dispatch_once(&onceSharedDataSource, ^{
        sharedDataSources = [[NSMutableDictionary alloc] init];
    });
    @synchronized (sharedDataSources) {
        NSNumber *key = @(hasToken);
        if (!sharedDataSources[key]) {
            if (!hasToken) {
                sharedDataSources[key] = [WKWebsiteDataStore defaultDataStore];
            } else {
                if (@available(iOS 17.0, *)) {
                    sharedDataSources[key] = [WKWebsiteDataStore dataStoreForIdentifier:[[NSUUID alloc] initWithUUIDString:UUID]];
                } else {
                    sharedDataSources[key] = [WKWebsiteDataStore nonPersistentDataStore];
                }
            }
        }
        return sharedDataSources[key];
    }
}

- (void)initiateWebViewWithToken:(BOOL)hasToken {
    WKProcessPool *processPool = [CustomWebViewContainer sharedProcessPoolWithToken:hasToken];
    WKWebsiteDataStore *dataStore = [CustomWebViewContainer sharedDataSourceWithToken:hasToken];
    if (hasToken) {
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
                NSHTTPCookieValue: TOKEN
            }];
            [dataStore.httpCookieStore setCookie:cookie completionHandler:nil];
        }
    }
    
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
