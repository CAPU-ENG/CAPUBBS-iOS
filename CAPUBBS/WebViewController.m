//
//  WebViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/5/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.webView setDelegate:self];
    [self.webView.scrollView setDelegate:self];
    [self.webView setScalesPageToFit:YES];
    [self.webView setAllowsLinkPreview:YES];
    self.buttonBack.enabled = NO;
    self.buttonForward.enabled = NO;
    if (!([self.URL hasPrefix:@"http://"] || [self.URL hasPrefix:@"https://"])) {
        self.URL = [@"https://" stringByAppendingString:self.URL];
    }
    
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".web"]];
    activity.webpageURL = [NSURL URLWithString:self.URL];
    [activity becomeCurrent];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URL]];
    if ([ActionPerformer checkLogin:NO]) {
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary]; // 设置cookie保留登录状态
        [cookieProperties setObject:@"token" forKey:NSHTTPCookieName];
        [cookieProperties setObject:TOKEN forKey:NSHTTPCookieValue];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        NSString *domain = CHEXIE;
        domain = [domain stringByReplacingOccurrencesOfString:@"https?://" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, domain.length)];
        domain = [domain stringByReplacingOccurrencesOfString:@":[0-9]{1,5}$" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, domain.length)];
        [cookieProperties setObject:domain forKey:NSHTTPCookieDomain];
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
    [self.webView loadRequest:request];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%@", [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]);
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
    } else {
        self.title = self.URL;
    }
    self.navigationItem.rightBarButtonItems = @[self.buttonRefresh];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//    if (error.code == -1022) { // http不安全链接 尝试使用https重连
//        NSString *httpUrl = error.userInfo[NSURLErrorFailingURLStringErrorKey];
//        self.URL = [httpUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
//        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URL]]];
//        return;
//    }
    if (error.code != -999) { // 999:主动终止加载
        [self showAlertWithTitle:@"加载错误" message:[NSString stringWithFormat:@"%@", [error localizedDescription]]];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.URL] options:@{} completionHandler:nil];
}

- (IBAction)share:(id)sender {
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[self.title, [NSURL URLWithString:self.URL]] applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = self.buttonShare;
    [self presentViewControllerSafe:activityViewController];
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
        } else if ((contentOffsetY - scrollView.contentOffset.y) > 5.0f) { // 向下拖拽
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

@end
