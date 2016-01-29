//
//  WebViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/5/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "WebViewController.h"
#import "ActionPerformer.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.webView setDelegate:self];
    [self.webView.scrollView setDelegate:self];
    [self.webView setScalesPageToFit:YES];
    if (IOS >= 9.0) {
        [self.webView setAllowsLinkPreview:YES];
    }
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URL]];
    if ([ActionPerformer checkLogin:NO]) {
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary]; // 设置cookie保留登录状态
        [cookieProperties setObject:@"token" forKey:NSHTTPCookieName];
        [cookieProperties setObject:TOKEN forKey:NSHTTPCookieValue];
        [cookieProperties setObject:CHEXIE forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
    self.buttonBack.enabled = NO;
    self.buttonForward.enabled = NO;
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".web"]];
    activity.webpageURL = [NSURL URLWithString:self.URL];
    [activity becomeCurrent];
    [self.webView loadRequest:newRequest];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.title = @"加载中";
    self.navigationItem.rightBarButtonItems = @[self.buttonStop];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (webView.request.URL.absoluteString.length > 0) {
        activity.webpageURL = webView.request.URL;
    }
    NSLog(@"Web Request Started");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.buttonBack.enabled = [webView canGoBack];
    self.buttonForward.enabled = [webView canGoForward];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.URL = webView.request.URL.absoluteString;
    self.navigationItem.rightBarButtonItems = @[self.buttonRefresh];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"Web Request Finished");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.buttonBack.enabled = [webView canGoBack];
    self.buttonForward.enabled = [webView canGoForward];
    if (webView.request.URL.absoluteString.length > 0) {
        self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.URL = webView.request.URL.absoluteString;
    }else {
        self.title = self.URL;
    }
    self.navigationItem.rightBarButtonItems = @[self.buttonRefresh];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (error.code != -999) { // 999:主动终止加载
        if (self.URL && !([self.URL hasPrefix:@"http://"] || [self.URL hasPrefix:@"https://"] || [self.URL hasPrefix:@"ftp://"])) { // 可能是因为链接不完整导致打开失败
            self.URL = [@"http://" stringByAppendingString:self.URL];
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URL]]];
        }else {
            [[[UIAlertView alloc] initWithTitle:@"加载错误" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self.navigationController setToolbarHidden:NO animated:YES];
    return YES;
}

- (IBAction)stop:(id)sender {
    [self.webView stopLoading];
}

- (IBAction)refresh:(id)sender {
    [self.webView reload];
}

- (IBAction)close:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)back:(id)sender {
    [self.webView goBack];
}

- (IBAction)forward:(id)sender {
    [self.webView goForward];
}

- (IBAction)openInSafari:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.URL]];
}

- (IBAction)share:(id)sender {
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[self.title, [NSURL URLWithString:self.URL]] applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = self.buttonShare;
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

// 开始拖拽视图
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    contentOffsetY = scrollView.contentOffset.y;
    isAtEnd = NO;
}

// 滚动时调用此方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // NSLog(@"scrollView.contentOffset:%f, %f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (isAtEnd == NO && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height) {
        [self.navigationController setToolbarHidden:NO animated:YES];
        isAtEnd = YES;
    }
    if (isAtEnd == NO && scrollView.dragging) { // 拖拽
        if ((scrollView.contentOffset.y - contentOffsetY) > 5.0f) { // 向上拖拽
            [self.navigationController setToolbarHidden:YES animated:YES];
        }else if ((contentOffsetY - scrollView.contentOffset.y) > 5.0f) { // 向下拖拽
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

@end
