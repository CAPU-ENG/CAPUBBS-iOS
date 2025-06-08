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
    [self.webViewContainer initiateWebViewForToken:TOKEN];
    [self.webViewContainer.webView setNavigationDelegate:self];
    [self.webViewContainer.webView.scrollView setDelegate:self];
    [self.webViewContainer.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    self.buttonBack.enabled = NO;
    self.buttonForward.enabled = NO;
    NSURL *url = [NSURL URLWithString:self.URL];
    if (!url || !url.host) {
        self.URL = [@"https://" stringByAppendingString:self.URL];
    }
    
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".web"]];
    activity.webpageURL = [NSURL URLWithString:self.URL];
    [activity becomeCurrent];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URL]];
    [self.webViewContainer.webView loadRequest:request];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
    if (titleCheckTimer && titleCheckTimer.isValid) {
        [titleCheckTimer invalidate];
    }
}

- (void)dealloc {
    [self.webViewContainer.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webViewContainer.webView) {
        CGFloat progress = self.webViewContainer.webView.estimatedProgress;
        [self.progressView setProgress:progress animated:YES];
        self.progressView.hidden = progress >= 1.0;
        if (progress >= 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.progressView setProgress:0.0 animated:NO];
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 允许其他类型加载（如 form submit、reload）
    if (navigationAction.navigationType != WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    NSString *path = navigationAction.request.URL.absoluteString;
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
    
    if ([path hasPrefix:@"tel:"]) {
        // Directly open
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:path] options:@{} completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.title = @"加载中";
    self.navigationItem.rightBarButtonItems = @[self.buttonStop];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    NSURL *url = webView.URL;
    if (url.absoluteString.length > 0) {
        activity.webpageURL = url;
    }
    if (titleCheckTimer && titleCheckTimer.isValid) {
        [titleCheckTimer invalidate];
    }
    __weak typeof(self) weakSelf = self;
    titleCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || webView.estimatedProgress < 0.2) {
            return;
        }
        [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (!error && result && [result isKindOfClass:[NSString class]]) {
                strongSelf.title = result;
            }
        }];
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.buttonBack.enabled = [webView canGoBack];
    self.buttonForward.enabled = [webView canGoForward];
    self.URL = webView.URL.absoluteString;
    self.navigationItem.rightBarButtonItems = @[self.buttonRefresh];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"WebView 加载失败: %@", error);
    
    self.buttonBack.enabled = [webView canGoBack];
    self.buttonForward.enabled = [webView canGoForward];
    if (webView.URL.absoluteString.length > 0) {
        self.URL = webView.URL.absoluteString;
    }
    self.navigationItem.rightBarButtonItems = @[self.buttonRefresh];
    
//    if (error.code == -1022) { // http不安全链接 尝试使用https重连
//        NSString *httpUrl = error.userInfo[NSURLErrorFailingURLStringErrorKey];
//        self.URL = [httpUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
//        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URL]]];
//        return;
//    }
    if (error.code != -999) { // 999:主动终止加载
        [self showAlertWithTitle:@"加载错误" message:[error localizedDescription]];
    }
}

- (IBAction)stop:(id)sender {
    [self.webViewContainer.webView stopLoading];
}

- (IBAction)refresh:(id)sender {
    [self.webViewContainer.webView reload];
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)back:(id)sender {
    [self.webViewContainer.webView goBack];
}

- (IBAction)forward:(id)sender {
    [self.webViewContainer.webView goForward];
}

- (IBAction)openInSafari:(id)sender {
    NSURL *url = [NSURL URLWithString:self.URL];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
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
