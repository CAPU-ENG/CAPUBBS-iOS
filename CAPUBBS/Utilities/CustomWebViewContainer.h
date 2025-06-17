//
//  CustomWebView.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/6/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface CustomWebViewContainer : UIView <WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;

+ (void)clearAllDataStores:(void (^)(void))completionHandler;

// Token should be excluded in most cases
- (void)initiateWebViewWithToken:(BOOL)hasToken;

@end
