//
//  UserViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/15.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "UserViewController.h"
#import "WebViewController.h"
#import "RegisterViewController.h"
#import "ChatViewController.h"
#import "ContentViewController.h"
#import "RecentViewController.h"

@interface UserViewController ()

@end

@implementation UserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(400, 0);
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    textSize = [[DEFAULTS objectForKey:@"textSize"] intValue];
    if (self.iconData.length > 0) {
        [self.icon setImage:[UIImage imageWithData:self.iconData]];
        [self refreshBackgroundViewAnimated:NO];
    }
    
    [self.icon setRounded:YES];
    if (self.noRightBarItem) {
        self.navigationItem.rightBarButtonItems = nil;
    } else {
        if ([self.ID isEqualToString:UID]) {
            self.navigationItem.rightBarButtonItems = @[self.buttoonEdit];
        } else {
            self.navigationItem.rightBarButtonItems = @[self.buttonChat];
        }
    }
    if ([self.ID isEqualToString:UID]) {
        self.labelReport.text = @"申请删除账号";
        self.title = @"个人信息";
    }
    labels = @[self.rights, self.sign, self.hobby, self.qq, self.mailBtn, self.from, self.regDate, self.lastDate, self.post, self.reply, self.water, self.extr];
    webViewContainers = @[self.intro, self.sig1, self.sig2, self.sig3];
    heights = [[NSMutableArray alloc] initWithArray:@[@0, @0, @0, @0]];
    for (int i = 0; i < webViewContainers.count; i++) {
        CustomWebViewContainer *webViewContainer = webViewContainers[i];
        [webViewContainer initiateWebViewForToken:nil];
        [webViewContainer setBackgroundColor:[UIColor clearColor]];
        [webViewContainer setOpaque:NO];
        [webViewContainer.webView setTag:i];
        [webViewContainer.webView setNavigationDelegate:self];
        [webViewContainer.webView.scrollView setScrollEnabled:NO];
    }
    
    recentPost = [NSMutableArray array];
    recentReply = [NSMutableArray array];
    property = @[@"rights", @"sign", @"hobby", @"qq", @"mail", @"place", @"regdate", @"lastdate", @"post", @"reply", @"water", @"extr"];
    performer = [[ActionPerformer alloc] init];
    [NOTIFICATION addObserver:self selector:@selector(getInformation) name:@"userUpdated" object:nil];
    control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
//    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self getInformation];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.ID isEqualToString:UID]) {
//        if (![[DEFAULTS objectForKey:@"FeatureEditUser3.0"] boolValue]) {
//            [self showAlertWithTitle:@"新功能！" message:@"可以编辑个人信息\n点击右上方铅笔前往" cancelTitle:@"我知道了"];
//            [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureEditUser3.0"];
//        }
    }
}

- (void)refresh:(NSNotification *)noti {
    if (self.iconData.length == 0) {
        self.iconData = noti.userInfo[@"data"];
        dispatch_main_async_safe(^{
            [self refreshBackgroundViewAnimated:YES];
        });
    }
}

- (void)refreshBackgroundViewAnimated:(BOOL)animated {
    if (SIMPLE_VIEW) {
        return;
    }
    if (!backgroundView) {
        backgroundView = [[AsyncImageView alloc] init];
        [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
        self.tableView.backgroundView = backgroundView;
    }
    [backgroundView setBlurredImage:[UIImage imageWithData:self.iconData] animated:animated];
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    control.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [self getInformation];
}

- (void)setDefault {
    self.username.text = self.ID;
    self.star.text = @"未知";
    iconURL = @"";
    for (int i = 0; i < labels.count; i++) {
        if (i != 4) {
            UILabel *label = [labels objectAtIndex:i];
            if (i >= 1 && i <= 5) {
                label.text = @"不告诉你";
            } else {
                label.text = @"未知";
            }
        } else {
            UIButton *button = [labels objectAtIndex:i];
            [button setTitle:@"不告诉你" forState:UIControlStateNormal];
            [button setEnabled:NO];
        }
    }
}

- (NSString *)extractValidEmail:(NSString *)rawEmailString {
    if (!rawEmailString || rawEmailString.length == 0) {
        return @"";
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:rawEmailString options:0 range:NSMakeRange(0, rawEmailString.length)];
    if (match) {
        return [rawEmailString substringWithRange:match.range];
    }
    return @"";
}

- (void)getInformation {
    [self setDefault];
    [hud showWithProgressMessage:@"查询中"];
    [performer performActionWithDictionary:@{@"uid": self.ID, @"recent": @"YES", @"raw": @"YES"} toURL:@"userinfo" withBlock:^(NSArray *result, NSError *err) {
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        if (err || result.count == 0) {
            [hud hideWithFailureMessage:@"查询失败"];
            NSLog(@"%@",err);
            self.username.text = [self.username.text stringByAppendingString:@"❗️"];
            return;
        }
        
        // NSLog(@"%@", result);
        [hud hideWithSuccessMessage:@"查询成功"];
        NSDictionary *dict = [result firstObject];
        if ([dict[@"username"] length] == 0) {
            [self showAlertWithTitle:@"查询错误！" message:@"没有这个ID或者您还未登录！"];
            self.username.text = [self.username.text stringByAppendingString:@"❌"];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        } else {
            if ([dict[@"username"] isEqualToString:UID]) {
                [GROUP_DEFAULTS setObject:[NSDictionary dictionaryWithDictionary:dict] forKey:@"userInfo"];
                NSLog(@"User Info Refreshed");
                dispatch_main_async_safe(^{
                    [NOTIFICATION postNotificationName:@"infoRefreshed" object:nil];
                });
            }
            if ([dict[@"sex"] isEqualToString:@"男"]) {
                self.username.text = [dict[@"username"] stringByAppendingString:@" 🚹"];
            } else if ([[[result objectAtIndex:0] objectForKey:@"sex"] isEqualToString:@"女"]) {
                self.username.text = [dict[@"username"] stringByAppendingString:@" 🚺"];
            }
            self.star.text = @"";
            for (int i = 1; i<= [dict[@"star"] intValue]; i++) {
                self.star.text = [self.star.text stringByAppendingString:@"⭐️"];
            }
            for (int i = 0; i < labels.count; i++) {
                if (!([dict[[property objectAtIndex:i]] length] == 0 || [dict[[property objectAtIndex:i]] isEqualToString:@"Array"])) {
                    if (i != 4) {
                        UILabel *label = [labels objectAtIndex:i];
                        label.text = [dict[[property objectAtIndex:i]] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                    } else {
                        UIButton *button = [labels objectAtIndex:i];
                        NSString *email = dict[[property objectAtIndex:i]];
                        NSString *validEmail = [self extractValidEmail:email];
                        if (validEmail) {
                            [button setTitle:validEmail forState:UIControlStateNormal];
                            [button setEnabled:YES];
                        } else {
                            [button setTitle:email forState:UIControlStateNormal];
                            [button setEnabled:NO];
                        }
                    }
                }
            }
            iconURL = dict[@"icon"];
            if (self.iconData.length == 0) {
                [NOTIFICATION addObserver:self selector:@selector(refresh:) name:[@"imageSet" stringByAppendingString:[AsyncImageView transIconURL:iconURL]] object:nil];
            }
            [self.icon setUrl:iconURL];
            
            for (int i = 0; i < webViewContainers.count; i++) {
                heights[i] = @0;
                CustomWebViewContainer *webViewContainer = webViewContainers[i];
                NSString *content = i == 0 ? dict[@"intro"] : dict[[NSString stringWithFormat:@"sig%d", i]];
                if ([content isEqualToString:@"Array"] || content.length == 0) {
                    content = @"<font color='gray'>暂无</font>";
                }
                content = [ContentViewController transToHTML:content];
                NSString *html = [ContentViewController htmlStringWithText:nil sig:content textSize:textSize];
                if (webViewContainer.webView.isLoading) {
                    [webViewContainer.webView stopLoading];
                }
                [webViewContainer.webView loadHTMLString:html baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/?", CHEXIE]]];
            }
            if (heightCheckTimer && [heightCheckTimer isValid]) {
                [heightCheckTimer invalidate];
            }
            // Do not trigger immediately, the webview might still be showing the previous content.
            heightCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateWebViewHeight) userInfo:nil repeats:YES];
            for (int i = 1; i < result.count; i++) {
                if (result[i] && result[i][@"info"]) {
                    id info = result[i][@"info"];
                    if (![info isKindOfClass:[NSArray class]]) {
                        info = @[info];
                    }
                    for (NSDictionary *dict in info) {
                        if ([dict[@"type"] isEqualToString:@"post"]) {
                            [recentPost addObject:dict];
                        }
                        if ([dict[@"type"] isEqualToString:@"reply"]) {
                            [recentReply addObject:dict];
                        }
                    }
                }
            }
        }
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    for (int i = 0; i < webViewContainers.count; i++) {
        heights[i] = @0;
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return UITableViewAutomaticDimension;
    } else if (indexPath.row <= 4) {
        return MIN(MAX([[heights objectAtIndex:indexPath.row - 1] floatValue], 14) + 35, WEB_VIEW_MAX_HEIGHT);
    } else {
        return 55;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 7) {
        if ([self.ID isEqualToString:UID]) {
            [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
                @"recipients": REPORT_EMAIL,
                @"subject": @"CAPUBBS 申请删除账号",
                @"body": [NSString stringWithFormat:@"您好，我是%@，我申请删除该账号，希望尽快处理，谢谢！", UID],
                @"fallbackMessage": @"请前往网络维护板块反馈"
            }];
        } else {
            [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
                @"recipients": REPORT_EMAIL,
                @"subject": @"CAPUBBS 举报违规用户",
                @"body": [NSString stringWithFormat:@"您好，我是%@，我发现用户 <a href=\"%@/bbs/user/?name=%@\">%@</a> 存在违规行为，希望尽快处理，谢谢！", ([UID length] > 0) ? UID : @"匿名用户", CHEXIE, self.ID, self.ID],
                @"isHTML": @(YES),
                @"fallbackMessage": @"请前往网络维护板块反馈"
            }];
        }
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
    
    WebViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"webview"];
    CustomNavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
    dest.URL = path;
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewControllerSafe:navi];
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)updateWebViewHeight {
    if (!self.isViewLoaded || !self.view.window ||
        !self.tableView || !self.tableView.window) { // Fix occasional crash
        return;
    }
    
    for (int i = 0; i < webViewContainers.count; i++) {
        CustomWebViewContainer *webviewContainer = webViewContainers[i];
        [webviewContainer.webView evaluateJavaScript:@"if(document.getElementById('body-wrapper')){document.getElementById('body-wrapper').scrollHeight;}" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"JS 执行失败: %@", error);
                return;
            }
            float height = 0;
            if (result && [result isKindOfClass:[NSNumber class]]) {
                height = [result floatValue] * (textSize / 100.0);
            }
            if (height > 0 && height - [[heights objectAtIndex:i] floatValue] >= 1) {
                heights[i] = @(height);
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
        }];
    }
}

- (IBAction)sendMail:(id)sender {
    [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
        @"recipients": @[self.mailBtn.titleLabel.text]
    }];
}

- (IBAction)tapPic:(UIButton *)sender {
    if (iconURL.length > 0) {
        [self showPic:[AsyncImageView transIconURL:iconURL]];
    }
}
- (void)showPic:(NSString *)url {
    NSString *md5Url = [ActionPerformer md5:url];
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, md5Url];
    if ([MANAGER fileExistsAtPath:cachePath]) { // GIF是未压缩的格式 可直接调取
        NSData *imageData = [MANAGER contentsAtPath:cachePath];
        if ([AsyncImageView fileType:imageData] == ImageFileTypeGIF) {
            [self presentImage:imageData fileName:[NSString stringWithFormat:@"%@.gif", md5Url]];
            return;
        }
    }
    [hud showWithProgressMessage:@"正在载入"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable idata, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        ImageFileType type = [AsyncImageView fileType:idata];
        if (error || type == ImageFileTypeUnknown) {
            [hud hideWithFailureMessage:@"载入失败"];
            return;
        }
        [hud hideWithSuccessMessage:@"载入成功"];
        [self presentImage:idata fileName:[NSString stringWithFormat:@"%@.%@", md5Url, [AsyncImageView fileExtension:type]]];
    }];
    [task resume];
}

- (void)presentImage:(NSData *)imageData fileName:(NSString *)fileName {
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileName];
    [imageData writeToFile:filePath atomically:YES];
    [NOTIFICATION postNotificationName:@"previewFile" object:self.icon userInfo:@{
        @"filePath": filePath,
        @"fileName": [NSString stringWithFormat:@"%@的头像", self.ID],
    }];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"chat"]) {
        ChatViewController *dest = [segue destinationViewController];
        dest.ID = self.ID;
        dest.directTalk = YES;
        dest.shouldHideInfo = YES;
        dest.iconData = self.iconData;
        dest.navigationItem.leftBarButtonItems = nil;
    }
    if ([segue.identifier isEqualToString:@"edit"]) {
        RegisterViewController *dest = [segue destinationViewController];
        dest.isEdit = YES;
        dest.navigationItem.leftBarButtonItems = nil;
    }
    if ([segue.identifier hasPrefix:@"recent"]) {
        RecentViewController *dest = [segue destinationViewController];
        dest.iconData = self.iconData;
        dest.iconUrl = [self.icon getUrl];
        if ([segue.identifier hasSuffix:@"Post"]) {
            dest.data = recentPost;
            dest.title = @"最近主题";
        } else if ([segue.identifier hasSuffix:@"Reply"]) {
            dest.data = recentReply;
            dest.title = @"最新回复";
        }
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
