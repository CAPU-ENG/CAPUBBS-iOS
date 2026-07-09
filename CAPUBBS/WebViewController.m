//
//  WebViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/5/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "WebViewController.h"
#import <Foundation/NSURLError.h>

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    if (LIQUID_GLASS) {
        self.toolbarItems = @[self.buttonBack, self.buttonRefreshOrStop, self.buttonForward, [UIBarButtonItem flexibleSpaceItem], self.buttonShare, self.buttonSafari];
    }
    [self.webViewContainer initiateWebViewWithToken:YES];
    self.webViewContainer.backgroundColor = [UIColor whiteColor];
    [self.webViewContainer.webView setNavigationDelegate:self];
    [self.webViewContainer.webView.scrollView setDelegate:self];
    [self.webViewContainer.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    [self updateButtonStatus];
    NSURL *url = [NSURL URLWithString:self.URL];
    if (!url || !url.host || !url.scheme) {
        self.URL = [@"https://" stringByAppendingString:self.URL];
        url = [NSURL URLWithString:self.URL];
    }
    
    [self.webViewContainer.webView loadRequest:[NSURLRequest requestWithURL:url]];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".web"]];
    [self setSafeActivityUrl:[NSURL URLWithString:self.URL]];
    [activity becomeCurrent];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)dealloc {
    [self.webViewContainer.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (NSString *)getDisplayUrl:(NSString *)urlString {
    NSString *displayURL = urlString;
    if (urlString.length > 200) {
        NSString *head = [urlString substringToIndex:100];
        NSString *tail = [urlString substringFromIndex:urlString.length - 100];
        displayURL = [NSString stringWithFormat:@"%@\n...\n%@", head, tail];
    }
    return displayURL;
}

- (void)setSafeActivityUrl:(NSURL *)url {
    if (url && [Helper isHttpScheme:url.scheme.lowercaseString]) {
        activity.webpageURL = url;
    } else {
        activity.webpageURL = nil;
    }
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
            dispatch_main_after(0.25, ^{
                [self.progressView setProgress:0.0 animated:NO];
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateButtonStatus {
    WKWebView *webView = self.webViewContainer.webView;
    self.buttonForward.enabled = webView.canGoForward;
    self.buttonBack.enabled = webView.canGoBack;
    self.buttonRefreshOrStop.image = [UIImage systemImageNamed:webView.isLoading ? @"xmark" : @"arrow.clockwise"];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *path = url.absoluteString;
    
    if ([path hasPrefix:@"about:"] || [path hasPrefix:@"data:"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    // 允许其他类型加载（如 form submit、reload）
    if (navigationAction.navigationType != WKNavigationTypeLinkActivated && navigationAction.navigationType != WKNavigationTypeOther) {
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
    
    if ([path hasPrefix:@"tel:"] || [path hasPrefix:@"sms:"] || [path hasPrefix:@"facetime:"] || [path hasPrefix:@"maps:"]) {
        // Directly open
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
        return;
    }
    
    // 非 http / https 链接：尝试用系统打开
    if (![Helper isHttpScheme:url.scheme.lowercaseString]) {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [self showAlertWithTitle:@"是否跳转至" message:path confirmTitle:@"确定" confirmAction:^(UIAlertAction *action) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法打开链接" message:[NSString stringWithFormat:@"可能未安装相应App\n%@", [self getDisplayUrl:path]] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"复制链接"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                [[UIPasteboard generalPasteboard] setString:path];
                [hud showAndHideWithSuccessMessage:@"复制成功"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"返回"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewControllerSafe:alertController];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(WK_SWIFT_UI_ACTOR void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSURLResponse *response = navigationResponse.response;
    NSString *contentDisposition = [(NSHTTPURLResponse *)response allHeaderFields][@"Content-Disposition"];
    BOOL canShow = navigationResponse.canShowMIMEType;
    // Is download request or type can not be rendered in webview
    if ([contentDisposition.lowercaseString hasPrefix:@"attachment"] || !canShow) {
        NSURL *url = response.URL;
        NSString *fileName = response.suggestedFilename ?: [Helper fileNameFromURL:url] ?: @"未知";
        if (fileName.pathExtension.length == 0) {
            NSString *extension = url.absoluteString.pathExtension;
            if (extension.length > 0) {
                fileName = [fileName stringByAppendingPathExtension:extension];
            }
        }
        
        NSString *description = fileName;
        if (url.host.length > 0) {
            description = [NSString stringWithFormat:@"%@\n来自：%@", description, url.host];
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"是否下载文件" message:description preferredStyle:UIAlertControllerStyleAlert];
        if (canShow) {
            [alertController addAction:[UIAlertAction actionWithTitle:@"直接查看"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                decisionHandler(WKNavigationResponsePolicyAllow);
            }]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:@"下载文件"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
            decisionHandler(WKNavigationResponsePolicyCancel);
            [self downloadWithUrl:url fileName:fileName webView:webView];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            decisionHandler(WKNavigationResponsePolicyCancel);
        }]];
        [self presentViewControllerSafe:alertController];
        return;
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)downloadWithUrl:(NSURL *)url fileName:(NSString *)fileName webView:(WKWebView *)webView {
    [hud showWithProgressMessage:@"下载中"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    WKHTTPCookieStore *cookieStore = webView.configuration.websiteDataStore.httpCookieStore;
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
        NSMutableArray<NSString *> *cookieParts = [NSMutableArray array];
        for (NSHTTPCookie *cookie in cookies) {
            // 只附加目标域名的 cookie
            if ([url.host hasSuffix:cookie.domain]) {
                [cookieParts addObject:[NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value]];
            }
        }
        if (cookieParts.count > 0) {
            NSString *cookieHeader = [cookieParts componentsJoinedByString:@"; "];
            [request setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
        }
        
        [Downloader loadRequest:request progress:^(float progress, NSUInteger expectedBytes) {
            [hud updateToProgress:progress];
        } completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error || !data || data.length == 0) {
                [hud hideWithFailureMessage:@"下载失败"];
                [self showAlertWithTitle:@"错误" message:error ? error.localizedDescription : @"文件下载失败，请检查您的网络连接！" confirmTitle:@"重试" confirmAction:^(UIAlertAction *action) {
                    dispatch_global_after(0.5, ^{
                        [self downloadWithUrl:url fileName:fileName webView:webView];
                    });
                }];
                return;
            }
            [hud hideWithSuccessMessage:@"下载成功"];
            [NOTIFICATION postNotificationName:@"previewFile" object:nil userInfo:@{
                @"fileData": data,
                @"fileName": fileName
            }];
        }];
    }];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.title = @"加载中";
    [self updateButtonStatus];
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self setSafeActivityUrl:webView.URL];

    if (titleCheckTimer && titleCheckTimer.isValid) {
        [titleCheckTimer invalidate];
    }
    
    // 使用 weakSelf 防止循环引用导致不能 dealloc
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
    [self updateButtonStatus];
    self.URL = webView.URL.absoluteString;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"⚠️ WebView 加载失败: %@", error);
    [self handleWebView:webView error:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"⚠️ WebView 导航失败: %@", error);
    [self handleWebView:webView error:error];
}

- (void)handleWebView:(WKWebView *)webView error:(NSError *)error {
    [self updateButtonStatus];
    [self.progressView setProgress:0 animated:YES];
    self.progressView.hidden = YES;
        
    if (!error || ![error.domain isEqualToString:NSURLErrorDomain] || error.code == NSURLErrorCancelled) {
        return;
    }
    
    NSURL *failingUrl = error.userInfo[NSURLErrorFailingURLErrorKey];
    
//    if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection && [failingUrl.scheme isEqualToString:@"http"]) { // http不安全链接 尝试使用https重连
//        NSString *httpsUrl = [failingUrl.absoluteString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
//        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:httpsUrl]]];
//        return;
//    }
    
    NSString *errorMessage = [error localizedDescription];
    switch (error.code) {
        case NSURLErrorTimedOut:
            errorMessage = @"请求超时";
            break;
        case NSURLErrorNotConnectedToInternet:
            errorMessage = @"无网络连接";
            break;
        case NSURLErrorNetworkConnectionLost:
            errorMessage = @"网络连接中断";
            break;
        case NSURLErrorCannotFindHost:
            errorMessage = @"无法找到服务器";
            break;
        case NSURLErrorCannotConnectToHost:
            errorMessage = @"无法连接到服务器";
            break;
        case NSURLErrorBadServerResponse:
            errorMessage = @"服务器响应异常";
            break;
        case NSURLErrorDataNotAllowed:
            errorMessage = @"数据访问受限，检查是否开启了网络访问权限";
            break;
        case NSURLErrorAppTransportSecurityRequiresSecureConnection:
            errorMessage = @"安全连接失败：不安全的 HTTP 网址被系统拒绝";
            break;
        case NSURLErrorSecureConnectionFailed:
            errorMessage = @"安全连接失败：可能为 HTTPS 证书问题";
            break;
        case NSURLErrorServerCertificateHasBadDate:
        case NSURLErrorServerCertificateUntrusted:
        case NSURLErrorServerCertificateHasUnknownRoot:
        case NSURLErrorServerCertificateNotYetValid:
        case NSURLErrorClientCertificateRejected:
        case NSURLErrorClientCertificateRequired:
            errorMessage = @"安全连接失败：HTTPS 证书异常";
            break;
        case NSURLErrorBadURL:
            errorMessage = @"无效的链接";
            break;
        case NSURLErrorUnsupportedURL: {
            NSString *scheme = failingUrl.scheme.lowercaseString;
            if (scheme && ![Helper isHttpScheme:scheme]) {
                errorMessage = @"不支持该链接，可能未安装相应App";
            } else {
                errorMessage = @"不支持该链接";
            }
            break;
        }
        default:
            break;
    }
    if (failingUrl.absoluteString) {
        NSString *urlString = failingUrl.absoluteString;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"加载错误" message:[NSString stringWithFormat:@"%@ (%ld)\n\n%@", errorMessage, error.code, [self getDisplayUrl:urlString]] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"复制链接"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
            [[UIPasteboard generalPasteboard] setString:urlString];
            [hud showAndHideWithSuccessMessage:@"复制成功"];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"重新加载"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
            dispatch_main_after(0.25, ^{
                [webView loadRequest:[NSURLRequest requestWithURL:failingUrl]];
            });
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"返回"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewControllerSafe:alertController];
    } else {
        [self showAlertWithTitle:@"加载错误" message:errorMessage];
    }
}

- (IBAction)refreshOrStop:(id)sender {
    WKWebView *webView = self.webViewContainer.webView;
    if (webView.isLoading) {
        [webView stopLoading];
    } else {
        [webView reload];
    }
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

// 点击系统状态栏回到顶部
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self.navigationController setToolbarHidden:NO animated:YES];
    return YES;
}

// 滚动时调用此方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // NSLog(@"scrollView.contentOffset:%f, %f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (isAtEnd) {
        return;
    }
    CGFloat newOffsetY = scrollView.contentOffset.y;
    if (newOffsetY >= scrollView.contentSize.height - scrollView.frame.size.height) {
        [self.navigationController setToolbarHidden:NO animated:YES];
        isAtEnd = YES;
        return;
    }
    if (scrollView.dragging) { // 拖拽
        CGFloat newOffsetY = scrollView.contentOffset.y;
        if (newOffsetY > 0 && (newOffsetY - contentOffsetY) > 5.0f) { // 向上拖拽
            contentOffsetY = newOffsetY;
            [self.navigationController setToolbarHidden:YES animated:YES];
        } else if ((contentOffsetY - newOffsetY) > 5.0f) { // 向下拖拽
            contentOffsetY = newOffsetY;
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

@end
