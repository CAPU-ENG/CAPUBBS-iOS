//
//  PreviewViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "PreviewViewController.h"
#import "ContentViewController.h"
#import "WebViewController.h"

@interface PreviewViewController ()

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;

    [self.webViewContainer initiateWebViewWithToken:NO];
    self.webViewContainer.layer.borderColor = GREEN_LIGHT.CGColor;
    self.webViewContainer.layer.borderWidth = 1;
    self.webViewContainer.layer.masksToBounds = YES;
    self.webViewContainer.layer.cornerRadius = 10;
    [self.webViewContainer.webView setNavigationDelegate:self];
    self.labelTitle.text = self.textTitle;
    NSString *sig = nil;
    if (self.sig > 0) {
        NSDictionary *dict = USERINFO;
        NSString *sigKey = [NSString stringWithFormat:@"sig%d", self.sig];
        if (!dict || [dict isEqual:@""] || [dict[sigKey] length] == 0 || [dict[sigKey] isEqualToString:@"Array"]) {
            sig = [NSString stringWithFormat:@"[您选择了第%d个签名档]", self.sig];
        } else {
            sig = [Helper transToHTML:dict[sigKey]];
        }
    }
    NSString *html = [Helper htmlStringWithText:[Helper transToHTML:self.textBody] attachments:self.attachments sig:sig textSize:[[DEFAULTS objectForKey:@"textSize"] intValue]];
    [self.webViewContainer.webView loadHTMLString:html baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/", CHEXIE]]];
    // Do any additional setup after loading the view.
}

- (IBAction)done:(id)sender {
    [NOTIFICATION postNotificationName:@"publishContent" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *path = url.absoluteString;
    
    // 允许其他类型加载（如 form submit、reload）
    if (navigationAction.navigationType != WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    if ([path hasPrefix:@"x-apple"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([path hasPrefix:@"mailto:"]) {
        NSString *mailAddress = [path substringFromIndex:@"mailto:".length];
        [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
            @"recipients": @[mailAddress]
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([path hasPrefix:@"capubbs-attach:"]) {
        [self showAlertWithTitle:@"提示" message:@"预览模式中不会下载附件"];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (![Helper isHttpScheme:url.scheme]) {
        // Directly open
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    [AppDelegate openURL:path fullScreen:YES];
    decisionHandler(WKNavigationActionPolicyCancel);
}

@end
