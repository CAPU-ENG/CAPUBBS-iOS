//
//  CustomWebView.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/6/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "CustomWebViewContainer.h"
#import "WebViewController.h"
//#import <CommonCrypto/CommonCrypto.h>

// Just a random UUID
#define UUID @"1ff24b67-2a92-41d9-9139-18be48987f3a"

@implementation CustomWebViewContainer

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

+ (NSString *)getAlertTitle:(WKFrameInfo *)frame {
    if (frame.request && frame.request.URL) {
        return [NSString stringWithFormat:@"来自%@的消息", frame.request.URL.host];
    }
    return @"来自网页的消息";
}

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

- (void)dealloc {
    if (_webView) {
        [_webView stopLoading];
        [_webView setNavigationDelegate:nil];
        [_webView setUIDelegate:nil];
        [_webView.configuration.userContentController removeAllScriptMessageHandlers];
    }
}

- (void)initiateWebViewWithToken:(BOOL)hasToken {
    WKWebsiteDataStore *dataStore = [CustomWebViewContainer sharedDataSourceWithToken:hasToken];
    if (hasToken) {
        NSURL *url = [NSURL URLWithString:CHEXIE];
        if (!url || !url.host) {
            NSString *fixedString = [@"https://" stringByAppendingString:CHEXIE];
            url = [NSURL URLWithString:fixedString];
        }
        if (url && url.host) {
            [dataStore.httpCookieStore setCookie:[NSHTTPCookie cookieWithProperties:@{
                NSHTTPCookieDomain: url.host,
                NSHTTPCookiePath: @"/",
                NSHTTPCookieName: @"token",
                NSHTTPCookieValue: TOKEN
            }] completionHandler:nil];
        }
    }
    
    if (_webView) {
        WKWebViewConfiguration *config = _webView.configuration;
        // No need to update here
        if (config.websiteDataStore == dataStore) {
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

- (void)showTimeoutMessage {
    [[AppDelegate getTopViewController] showAlertWithTitle:@"错误" message:@"您太久未选择操作，已超时自动取消对话"];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(WK_SWIFT_UI_ACTOR void (^)(void))completionHandler {
    // 此类型弹窗最常见，因不需要用户输入，直接调用 completionHandler，防止崩溃
    completionHandler();
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        return;
    }
    [viewController showAlertWithTitle:[CustomWebViewContainer getAlertTitle:frame] message:message];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull WK_SWIFT_UI_ACTOR void (^)(BOOL))completionHandler {
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        completionHandler(NO);
        return;
    }
    
    __block BOOL handlerCalled = NO;
    BOOL (^safeHandler)(BOOL) = ^(BOOL result) {
        if (handlerCalled) {
            return NO;
        }
        handlerCalled = YES;
        completionHandler(result);
        return YES;
    };
    
    [viewController showAlertWithTitle:[CustomWebViewContainer getAlertTitle:frame] message:message confirmTitle:@"确定" confirmAction:^(UIAlertAction *action) {
        if (!safeHandler(YES)) {
            [self showTimeoutMessage];
        }
    } cancelTitle:@"取消" cancelAction:^(UIAlertAction *action) {
        if (!safeHandler(NO)) {
            [self showTimeoutMessage];
        }
    }];
    
    // 延迟兜底调用 handler，注意这会保持对 completionHandler 的引用，VC会在计时结束后才dealloc
    // 考虑到此类型弹窗很罕见，可以接受
    dispatch_main_after(60, ^{
        if (safeHandler(NO)) {
            NSLog(@"completionHandler not called by user, fallback to call handler");
        }
    });
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(WK_SWIFT_UI_ACTOR void (^)(NSString * _Nullable))completionHandler {
    UIViewController *viewController = [AppDelegate getTopViewController];
    if (!viewController) {
        completionHandler(nil);
        return;
    }
    
    __block BOOL handlerCalled = NO;
    BOOL (^safeHandler)(NSString *) = ^(NSString *result) {
        if (handlerCalled) {
            return NO;
        }
        handlerCalled = YES;
        completionHandler(result);
        return YES;
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[CustomWebViewContainer getAlertTitle:frame] message:prompt preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(alertController) weakAlertController = alertController; // 避免循环引用
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        __strong typeof(weakAlertController) strongAlertController = weakAlertController;
        if (!strongAlertController) {
            return;
        }
        NSString *input = strongAlertController.textFields[0].text;
        if (!safeHandler(input)) {
            [self showTimeoutMessage];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
        if (!safeHandler(nil)) {
            [self showTimeoutMessage];
        }
    }]];
    [viewController presentViewControllerSafe:alertController];
    
    // 延迟兜底调用 handler，注意这会保持对 completionHandler 的引用，VC会在计时结束后才dealloc
    // 考虑到此类型弹窗很罕见，可以接受
    dispatch_main_after(60, ^{
        if (safeHandler(nil)) {
            NSLog(@"completionHandler not called by user, fallback to call handler");
        }
    });
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    // Open in new page request (like target='_blank')
    if (!navigationAction.targetFrame.isMainFrame && navigationAction.request.URL) {
        NSURL *sourceUrl = navigationAction.sourceFrame.request.URL;
        NSURL *newUrl = navigationAction.request.URL;
        if ([sourceUrl.host isEqualToString:newUrl.host]) {
            // Same host, navigate directly
            [webView loadRequest:navigationAction.request];
        } else if (![[AppDelegate viewControllerForView:webView] isKindOfClass:[WebViewController class]]) {
            [AppDelegate openURL:newUrl.absoluteString fullScreen:YES];
        } else if ([[UIApplication sharedApplication] canOpenURL:newUrl]) {
            // Ask for user confirmation
            NSString *scheme = newUrl.scheme.lowercaseString;
            NSString *displayUrl = newUrl.host ? [NSString stringWithFormat:@"%@://%@", scheme, newUrl.host] : newUrl.absoluteString;
            [[AppDelegate getTopViewController] showAlertWithTitle:@"是否跳转至" message:displayUrl confirmTitle:@"确定" confirmAction:^(UIAlertAction *action) {
                if ([Helper isHttpScheme:scheme]) {
                    [webView loadRequest:navigationAction.request];
                } else {
                    [[UIApplication sharedApplication] openURL:newUrl options:@{} completionHandler:nil];
                }
            }];
        } else {
            // Load and allow it to fail (trigger alert in VC), ideally never happens,
            // should already be handled in decidePolicyForNavigationAction
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil; // 不创建新 webView，防止空白页
}

@end

/// A delegate to avoid strong reference cycle
@interface WeakScriptMessageDelegate : NSObject <WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@property (nonatomic, weak, readonly) id<WKScriptMessageHandler> delegate;

@end

@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

// 实现 WKScriptMessageHandler 协议方法，并把消息转发给真正的代理
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([self.delegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

@implementation WKWebView (Custom)

- (void)clearForReuse {
    [self setNavigationDelegate:nil];
    [self loadHTMLString:@"" baseURL:nil];
}

- (void)setWeakScriptMessageHandler:(id<WKScriptMessageHandler>)delegate forNames:(NSArray<NSString *> *)handlerNames {
    WeakScriptMessageDelegate *weakDelegate = [delegate isKindOfClass:[WeakScriptMessageDelegate class]] ? delegate : [[WeakScriptMessageDelegate alloc] initWithDelegate:delegate];
    for (NSString *handlerName in handlerNames) {
        [self.configuration.userContentController removeScriptMessageHandlerForName:handlerName];
        [self.configuration.userContentController addScriptMessageHandler:weakDelegate name:handlerName];
    }
}

@end
