//
//  ContentViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentCell.h"
#import "ComposeViewController.h"
#import "LzlViewController.h"
#import "UserViewController.h"
#import "WebViewController.h"

#define WEB_VIEW_MIN_HEIGHT 40
#define MAX_LZL_ROWS 8

@interface ContentViewController ()

@end

@implementation ContentViewController

#pragma mark - View control

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever; // Do not show large title
    self.view.backgroundColor = GRAY_PATTERN;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    textSize = [[DEFAULTS objectForKey:@"textSize"] intValue];
    if ([self.destinationPage intValue] > 0) { // 进入时直接跳至指定页
        page = [self.destinationPage intValue];
    } else if ([self.destinationFloor intValue] > 0) {
        page = ceil([self.destinationFloor floatValue] / 12);
    } else {
        page = 1;
    }
    selectedIndex = -1;
    isEdit = NO;
    [self cancelScroll];
    heights = [NSMutableArray array];
    tempHeights = [NSMutableArray array];
    HTMLStrings = [NSMutableArray array];
    webViews = [NSHashTable weakObjectsHashTable]; // Use weak reference
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapWeb:)];
    [tapTwice setNumberOfTapsRequired:2];
    [self.tableView addGestureRecognizer:tapTwice];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:longPress];
    
    [NOTIFICATION addObserver:self selector:@selector(refreshLzl:) name:@"refreshLzl" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(doRefresh:) name:@"refreshContent" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(cancelScroll) name:@"globalTap" object:nil];
    
    [self jumpTo:page];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".content"]];
    activity.webpageURL = [self getCurrentUrl];
    activity.title = self.title;
    [activity becomeCurrent];
    
//    if (![[DEFAULTS objectForKey:@"FeatureSize2.1"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"底栏中可以调整页面缩放\n设置中还可选择默认大小" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:@(YES) forKey:@"FeatureSize2.1"];
//    }
    if (![[DEFAULTS objectForKey:@"FeatureLzl4.0"] boolValue]) {
        if (SIMPLE_VIEW) {
            [self showAlertWithTitle:@"新功能！" message:@"帖子中现在会直接展示楼中楼\n关闭简洁版后可用" cancelTitle:@"我知道了"];
        }
        [DEFAULTS setObject:@(YES) forKey:@"FeatureLzl4.0"];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self clearHeightsAndHTMLCaches:nil];
}

#pragma mark - Web request

- (NSURL *)getCurrentUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/?tid=%@&bid=%@&p=%d", CHEXIE, self.tid, self.bid, page]];
}

- (void)jumpTo:(int)pageNum {
    [hud showWithProgressMessage:@"加载中"];
    int oldPage = page;
    page = pageNum;
    [self updateBackOrCollectIcon];
    self.buttonBackOrCollect.enabled = NO;
    self.buttonForward.enabled = NO;
    self.buttonLatest.enabled = NO;
    self.buttonJump.enabled = NO;
    self.buttonAction.enabled = NO;
    self.buttonCompose.enabled = [Helper checkLogin:NO];
    activity.webpageURL = [self getCurrentUrl];
    activity.title = self.title;
    NSDictionary *dict = @{
        @"p" : [NSString stringWithFormat:@"%d", page],
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"raw" : @"YES",
    };
    [Helper callApiWithParams:dict toURL:@"show" callback:^(NSArray *result, NSError *err) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        if (err || result.count == 0 || [result[0][@"time"] hasPrefix:@"1970"]) {
            page = oldPage;
            if (!err && (result.count == 0 || [result[0][@"time"] hasPrefix:@"1970"])) {
                self.title = @"没有这个帖子";
            }
            [hud hideWithFailureMessage:@"加载失败"];
            NSLog(@"%@", err);
            if (err.code == 111) {
                tempPath = [NSString stringWithFormat:@"%@/bbs/content/?tid=%@&bid=%@&p=%ld", CHEXIE, self.tid, self.bid, (long)page];
                [self performSegueWithIdentifier:@"web" sender:nil];
            }
            return;
        }
        
        // NSLog(@"%@", result);
        int code = [result[0][@"code"] intValue];
        if (code != -1 && code != 0) {
            if (code == 1 && page > 1) {
                [self jumpTo:page - 1];
                return;
            }
            [self showAlertWithTitle:@"加载失败" message:result[0][@"msg"]];
            [hud hideWithFailureMessage:@"加载失败"];
            return;
        }
        
        NSMutableArray *tmpData = [NSMutableArray array];
        for (NSDictionary *entry in result) {
            NSMutableDictionary *fixedEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
            for (NSString *key in @[@"lzldetail", @"attach"]) {
                id value = fixedEntry[key];
                if (!value) {
                    fixedEntry[key] = @[];
                } else if (![value isKindOfClass:[NSArray class]]) {
                    fixedEntry[key] = @[value];
                }
            }
            // text
            NSString *textraw = fixedEntry[@"textraw"];
            if (!textraw || [textraw isEqualToString:@"Array"]) {
                textraw = @"";
            }
            if (![fixedEntry[@"ishtml"] isEqualToString:@"YES"]) {
                NSData *data = [textraw dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *options = @{
                    NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                };
                NSAttributedString *decoded = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:nil error:nil];
                textraw = decoded.string;
            }
            fixedEntry[@"text"] = textraw;
            [fixedEntry removeObjectForKey:@"textraw"];
            [fixedEntry removeObjectForKey:@"ishtml"];
            // sig
            NSString *sigRaw = fixedEntry[@"sigraw"];
            if (!sigRaw || [sigRaw isEqualToString:@"Array"]) {
                sigRaw = @"";
            }
            fixedEntry[@"sig"] = sigRaw;
            [fixedEntry removeObjectForKey:@"sigraw"];
            
            [tmpData addObject:fixedEntry];
        }
        data = [tmpData copy];
        if (!(self.isCollection && page > 1)) {
            [self updateCollection:YES];
        }
        
        for (WKWebView *webView in webViews.allObjects) {
            [webView clearForReuse];
        }
        isUpdating = YES;
        [self clearHeightsAndHTMLCaches:^{
            NSString *titleText = data.firstObject[@"title"];
            self.title = [Helper restoreTitle:titleText];
            BOOL isLast = [data[0][@"nextpage"] isEqualToString:@"false"];
            self.buttonBackOrCollect.enabled = YES;
            self.buttonForward.enabled = !isLast;
            self.buttonLatest.enabled = !isLast;
            self.buttonJump.enabled = ([[data lastObject][@"pages"] integerValue] > 1);
            self.buttonAction.enabled = YES;
            [hud hideWithSuccessMessage:@"加载成功"];
            isUpdating = NO;
            
            if ([self.tableView numberOfRowsInSection:0] == 0) {
                [self.tableView reloadData];
            } else {
                UITableViewRowAnimation rowAnimation = UITableViewRowAnimationNone;
                if (!SIMPLE_VIEW) {
                    if (oldPage > pageNum) {
                        rowAnimation = UITableViewRowAnimationRight;
                    }
                    if (oldPage < pageNum) {
                        rowAnimation = UITableViewRowAnimationLeft;
                    }
                }
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnimation];
            }
            
            if (data.count > 0) {
                if (self.willScrollToBottom) {
                    self.willScrollToBottom = NO;
                    [self tryScrollTo:data.count - 1 animated:NO];
                } else {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
                for (int i = 0; i < data.count; i++) {
                    NSDictionary *dict = data[i];
                    if (self.destinationFloor.length > 0 && [dict[@"floor"] isEqualToString:self.destinationFloor]) {
                        if (self.openDestinationLzl) {
                            scrollTargetPosition = UITableViewScrollPositionBottom;
                            dispatch_main_after(0.5, ^{
                                selectedIndex = [data indexOfObject:dict];
                                [self performSegueWithIdentifier:@"lzl" sender:nil];
                            });
                        }
                        [self tryScrollTo:i animated:NO];
                    }
                }
                self.openDestinationLzl = NO;
                self.destinationFloor = @"";
            }
        }];
    }];
}

- (void)updateCollection:(BOOL)notification {
    self.isCollection = NO;
    if (data.count == 0) {
        [self updateBackOrCollectIcon];
        return;
    }
    if (page == 1) { // 更新楼主信息
        NSMutableArray *collections = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"collection"]];
        for (NSMutableDictionary *mdic in collections) {
            if ([self.bid isEqualToString:mdic[@"bid"]] && [self.tid isEqualToString:mdic[@"tid"]]) {
                NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:mdic];
                [tmp addEntriesFromDictionary:data[0]];
                tmp[@"text"] = [self getCollectionText:tmp[@"text"]];
                tmp[@"title"] = [Helper restoreTitle:tmp[@"title"]];
                
                BOOL hasChange = NO;
                for (NSString *keyword in @[@"title", @"text", @"author", @"icon"]) {
                    if (!([tmp[keyword] isEqualToString:mdic[keyword]])) {
                        hasChange = YES;
                    }
                }
                // Remove unnecessary fields to save storage
                for (NSString *keyword in @[@"lzldetail", @"sig", @"attach"]) {
                    [tmp removeObjectForKey:keyword];
                }
                
                [collections removeObject:mdic];
                [collections addObject:tmp];
                [DEFAULTS setObject:collections forKey:@"collection"];
                if (hasChange && notification) {
                    NSLog(@"Update Collection");
                    [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
                }
                self.isCollection = YES;
                break;
            }
        }
    }
    [self updateBackOrCollectIcon];
}

- (void)updateBackOrCollectIcon {
    if (page == 1) {
        self.buttonBackOrCollect.image = [UIImage systemImageNamed:self.isCollection ? @"heart.fill" : @"heart"];
        self.buttonBackOrCollect.style = self.isCollection ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain;
    } else {
        self.buttonBackOrCollect.image = [UIImage systemImageNamed:@"chevron.left"];
        self.buttonBackOrCollect.style = UIBarButtonItemStylePlain;
    }
}

- (void)clearHeightsAndHTMLCaches:(void (^)(void))callback {
    CGFloat tableViewWidth = self.tableView.frame.size.width;
    dispatch_global_default_async(^{
        NSMutableArray *newHTMLStrings = [NSMutableArray array];
        NSMutableArray *newTempHeights = [NSMutableArray array];
        for (int i = 0; i < data.count; i++) {
            if (tempHeights.count <= i) {
                [tempHeights addObject:@0];
            }
            [newTempHeights addObject:@(0)];
            NSDictionary *dict = data[i];
            NSString *text = [Helper transToHTML:dict[@"text"]];
            NSString *sig = [Helper transToHTML:dict[@"sig"]];
            NSString *html = [Helper htmlStringWithText:text attachments:dict[@"attach"] sig:sig textSize:textSize];
            // NSLog(@"%@", html);
            [newHTMLStrings addObject:html];
            if ([tempHeights[i] floatValue] == 0) {
                // 这只是一个非常粗略的估计
                NSError *error = nil;
                // 去除img和iframe，严重拖慢速度
                NSString *sanitizedHTML = [html stringByReplacingOccurrencesOfString:@"(?i)(<img\\b[^>]*?>|<iframe\\b[^>]*>[\\s\\S]*?<\\/iframe>)" withString:@"<div>block placeholder</div>" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
                
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[sanitizedHTML dataUsingEncoding:NSUTF8StringEncoding] options:@{
                    NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                } documentAttributes:nil error:&error];
                if (error) {
                    NSLog(@"HTML height estimation parse error: %@", error);
                } else {
                    CGSize constraint = CGSizeMake(tableViewWidth - 40, WEB_VIEW_MAX_HEIGHT);
                    CGSize size = [attributedString boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
                    newTempHeights[i] = @(size.height * (textSize / 100.0));
                }
            }
        }
        
        // Do not clear array to avoid multi thread race condition
        for (int i = 0; i < data.count; i++) {
            heights[i] = @0;
            HTMLStrings[i] = newHTMLStrings[i];
            if ([newTempHeights[i] floatValue] > 0) {
                tempHeights[i] = newTempHeights[i];
            }
        }
        if (callback) {
            dispatch_main_async_safe(^{
                callback();
            });
        }
    });
}

- (void)doRefresh:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo[@"isEdit"] boolValue]) {
        self.destinationFloor = userInfo[@"floor"];
        [self jumpTo:page];
    } else {
        // User just sent a new post
        self.willScrollToBottom = YES;
        [self jumpTo:[[data lastObject] [@"pages"] intValue]];
    }
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [self jumpTo:page];
}

- (void)refresh {
    [self jumpTo:page];
}

- (IBAction)jump:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[data lastObject] [@"pages"]] preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(alertController) weakAlertController = alertController; // 避免循环引用
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"页码";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakAlertController) strongAlertController = weakAlertController;
        if (!strongAlertController) {
            return;
        }
        NSString *pageip = strongAlertController.textFields[0].text;
        int pagen = [pageip intValue];
        if (pagen <= 0 || pagen > [[data lastObject] [@"pages"] integerValue]) {
            [self showAlertWithTitle:@"错误" message:@"输入不合法"];
            return;
        }
        [self jumpTo:pagen];
    }]];
    [self presentViewControllerSafe:alertController];
}

- (IBAction)gotoLatest:(id)sender {
    self.willScrollToBottom = YES;
    [self jumpTo:[[data lastObject] [@"pages"] intValue]];
}

#pragma mark - Table view data source

- (CGFloat)getLzlHeightForRow:(NSUInteger)row {
    if (SIMPLE_VIEW) {
        return 0;
    }
    NSArray *lzlDetail = data[row][@"lzldetail"];
    // Show at most 8 rows
    return MIN(MAX_LZL_ROWS, lzlDetail.count) * 44;
}

- (CGFloat)getWebViewHeightForRow:(NSUInteger)row {
    CGFloat webViewHeight = 0;
    for (NSArray *candidate in @[heights, tempHeights]) {
        if (candidate.count > row && [candidate[row] floatValue] > 0) {
            webViewHeight = [candidate[row] floatValue];
            break;
        }
    }
    return MIN(MAX(WEB_VIEW_MIN_HEIGHT, webViewHeight), WEB_VIEW_MAX_HEIGHT);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return MIN(data.count, HTMLStrings.count);
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CGFloat lzlHeight = [self getLzlHeightForRow:indexPath.row];
    CGFloat webViewHeight = [self getWebViewHeightForRow:indexPath.row];
    return 109 + lzlHeight + webViewHeight;
}

- (ContentCell *)getCellForView:(UIView *)view {
    UIView *currentView = view;
    while (currentView != nil) {
        if ([currentView isKindOfClass:[ContentCell class]]) {
            return (ContentCell *)currentView;
        }
        currentView = currentView.superview;
    }
    return nil;
}

- (BOOL)tableViewIsAtTop {
    UITableView *tableView = self.tableView;
    return tableView.contentOffset.y <= 1.0;
}

- (BOOL)tableViewIsAtBottom {
    UITableView *tableView = self.tableView;
    return tableView.contentOffset.y >= tableView.contentSize.height - tableView.bounds.size.height - 1.0;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    ContentCell *cell = [self getCellForView:webView];
    if (!cell) {
        return;
    }
    [cell invalidateTimer];
    // 使用 weakSelf 防止循环引用导致不能 dealloc
    __weak typeof(self) weakSelf = self;
    // Do not trigger immediately, the webview might still be showing the previous content.
    cell.webviewUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [timer invalidate];
            return;
        }
        [strongSelf updateWebView:webView];
    }];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    dispatch_main_async_safe((^{
        [webView setWeakScriptMessageHandler:self forNames:@[@"imageClickHandler", @"heightHandler"]];
        [webView evaluateJavaScript:@"window._imageClickHandlerAvailable=true;window._lastReportedHeight=0;" completionHandler:nil];
    }));
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    ContentCell *cell = [self getCellForView:webView];
    if (!cell) {
        return;
    }
    [cell.indicatorLoading stopAnimating];
}

- (void)updateWebView:(WKWebView *)webView {
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.body.style.zoom='%d%%';window._lastReportedHeight=0;", textSize] completionHandler:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"imageClickHandler"]) {
        [AppDelegate handleImageClickWithMessage:message hud:hud];
    }
    if ([message.name isEqualToString:@"heightHandler"]) {
        [self handleHeightWithMessage:message];
    }
}

- (void)handleHeightWithMessage:(WKScriptMessage *)message {
    if (isUpdating) {
        return;
    }
    float height = [message.body floatValue];
    if (height <= 0) {
        return;
    }
    
    WKWebView *webView = message.webView;
    NSUInteger row = webView.tag;
    ContentCell *cell = [self getCellForView:webView];
    if (row >= heights.count || !cell || !cell.webviewUpdateTimer.valid) {
        return;
    }
    
    height = (height + 14) * (textSize / 100.0);
    if (height - [heights[row] floatValue] >= 1) {
        heights[row] = @(height);
        tempHeights[row] = @(height);
        float targetHeight = MIN(MAX(height, WEB_VIEW_MIN_HEIGHT), WEB_VIEW_MAX_HEIGHT);
        if (scrollTargetRow >= 0) {
            [UIView performWithoutAnimation:^{
                [self.tableView beginUpdates];
                [cell.webviewHeight setConstant:targetHeight];
                [self.tableView endUpdates];
                [self maybeTriggerTableViewScrollAnimated:NO];
            }];
        } else {
            [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.tableView beginUpdates];
                [cell.webviewHeight setConstant:targetHeight];
                [self.tableView endUpdates];
                [self maybeTriggerTableViewScrollAnimated:NO];
            } completion:nil];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = @"";
    if (!SIMPLE_VIEW && data.count > 0) {
        header = [NSString stringWithFormat:@"%@ 第%ld/%@页", [Helper getBoardTitle:self.bid], (long)page, [data lastObject] [@"pages"]];
        if ([data[0][@"click"] length] > 0) {
            header = [NSString stringWithFormat:@"%@ 查看：%@ 回复：%@%@", header, data[0][@"click"], data[0][@"reply"], self.isCollection ? @" 已收藏": @""];
        }
    }
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"Cell in row %d", (int)indexPath.row);
    ContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"content" forIndexPath:indexPath];
    
    cell.buttonAction.tag = indexPath.row;
    cell.buttonLzl.tag = indexPath.row;
    cell.buttonIcon.tag = indexPath.row;
    cell.webViewContainer.webView.tag = indexPath.row;
    
    NSDictionary *dict = data[indexPath.row];
    NSString *author = [dict[@"author"] stringByAppendingString:@" "];
    int star = [dict[@"star"] intValue];
    for (int i = 1; i <= star; i++) {
        author = [author stringByAppendingString:@"★"];
    }
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:author];
    [attr addAttribute:(NSString *)NSForegroundColorAttributeName value:[UIColor colorWithWhite:0 alpha:0.25] range:NSMakeRange(author.length-star,star)];
    cell.labelAuthor.attributedText = attr;
    NSString *floor;
    switch ([dict[@"floor"] integerValue]) {
        case 1:
            floor = @"楼主";
            break;
        case 2:
            floor = @"沙发";
            break;
        case 3:
            floor = @"板凳";
            break;
        case 4:
            floor = @"地席";
            break;
        default:
            floor = [NSString stringWithFormat:@"%@楼",dict[@"floor"]];
            break;
    }
    cell.labelInfo.text = floor;
    NSArray *lzlDetail = dict[@"lzldetail"];
    NSUInteger lzlCount = lzlDetail.count;
    [cell.buttonLzl setTitle:[NSString stringWithFormat:@"评论 (%ld)", lzlCount] forState:UIControlStateNormal];
    if (lzlCount == 0) {
        [cell.buttonLzl setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    } else {
        [cell.buttonLzl setTitleColor:nil forState:UIControlStateNormal]; // use default color
    }
    
    if (!SIMPLE_VIEW) {
        if (dict[@"edittime"] && ![dict[@"edittime"] isEqualToString:dict[@"time"]]) {
            cell.labelDate.text = [NSString stringWithFormat:@"发布: %@\n编辑: %@", dict[@"time"], dict[@"edittime"]];
        } else {
            cell.labelDate.text = [NSString stringWithFormat:@"发布: %@", dict[@"time"]];
        }
        if ([dict[@"type"] isEqualToString:@"web"]) {
            cell.labelInfo.text = [NSString stringWithFormat:@"%@\n🖥", floor];
        } else if ([dict[@"type"] isEqualToString:@"android"]) {
            cell.labelInfo.text = [NSString stringWithFormat:@"%@\n📱", floor];
        } else if ([dict[@"type"] isEqualToString:@"ios"]) {
            cell.labelInfo.text = [NSString stringWithFormat:@"%@\n📱", floor];
        } else {
            cell.labelInfo.text = floor;
        }
    } else {
        cell.labelDate.text = dict[@"time"];
        cell.labelInfo.text = floor;
    }
    
    [cell.icon setUrl:dict[@"icon"]];
    
    [cell.webViewContainer.webView setNavigationDelegate:self];
    [cell.webViewContainer.webView loadHTMLString:HTMLStrings[indexPath.row] baseURL:[self getCurrentUrl]];
    [webViews addObject:cell.webViewContainer.webView];
    [cell.webviewHeight setConstant:[self getWebViewHeightForRow:indexPath.row]];
    
    
    if (heights.count > indexPath.row && [heights[indexPath.row] floatValue] > 0) {
        [cell.indicatorLoading stopAnimating];
    } else {
        [cell.indicatorLoading startAnimating];
    }
    
    CGFloat lzlHeight = [self getLzlHeightForRow:indexPath.row];
    if (lzlHeight > 0) {
        cell.lzlTableView.hidden = NO;
        cell.lzlDetail = lzlDetail;
        [cell.lzlHeight setConstant:[self getLzlHeightForRow:indexPath.row]];
    } else {
        cell.lzlTableView.hidden = YES;
        cell.lzlDetail = @[];
        [cell.lzlHeight setConstant:0];
    }
    [cell.lzlTableView reloadData];
    
    return cell;
}

#pragma mark - Content view

/// Recommend to set animated to false as animation could be very choppy
- (void)tryScrollTo:(NSUInteger)row animated:(BOOL)animated {
    scrollTargetRow = row;
    [self maybeTriggerTableViewScrollAnimated:animated];
}

- (void)maybeTriggerTableViewScrollAnimated:(BOOL)animated {
    if (scrollTargetRow < 0 || scrollTargetRow >= data.count) {
        return;
    }
    dispatch_main_sync_safe(^{
        if ([self.tableView numberOfRowsInSection:0] < scrollTargetRow) {
            return;
        }
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollTargetRow inSection:0] atScrollPosition:scrollTargetPosition animated:animated];
    });
}

- (void)cancelScroll {
    // 用户有任何操作都取消scroll
    scrollTargetRow = -1;
    scrollTargetPosition = UITableViewScrollPositionTop;
}

// 开始拖拽视图
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    contentOffsetY = scrollView.contentOffset.y;
    isAtEnd = NO;
    [self cancelScroll];
}

// 点击系统状态栏回到顶部
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self cancelScroll];
    [self.navigationController setToolbarHidden:NO animated:YES];
    return YES;
}

// 滚动时调用此方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (LIQUID_GLASS) {
        return;
    }
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
        if (newOffsetY > 0 && (newOffsetY - contentOffsetY) > 5.0f) { // 向上拖拽
            contentOffsetY = newOffsetY;
            [self.navigationController setToolbarHidden:YES animated:YES];
        } else if ((contentOffsetY - newOffsetY) > 5.0f) { // 向下拖拽
            contentOffsetY = newOffsetY;
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

- (void)askForDownloadAttachment:(NSString *)path {
    NSDictionary *userInfo = USERINFO;
    if (![Helper checkLogin:NO] || !userInfo || [userInfo isEqual:@""]) {
        [self showAlertWithTitle:@"错误" message:@"您未登录，无法下载附件"];
        return;
    }
    
    NSString *base64Payload = [path stringByReplacingOccurrencesOfString:@"capubbs-attach://" withString:@""];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64Payload options:0];
    if (!decodedData) {
        return;
    }
    NSDictionary *attach = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:nil];
    NSString *fileSize = [Helper fileSizeStr:[attach[@"size"] intValue]];
    NSString *generalInfo = [NSString stringWithFormat:@"%@\n下载后请及时保存", attach[@"name"]];
    if ([attach[@"price"] intValue] == 0 || [attach[@"free"] isEqualToString:@"YES"]) {
        [self showAlertWithTitle:[NSString stringWithFormat:@"确认下载附件 (%@)", fileSize] message:generalInfo confirmTitle:@"确认" confirmAction:^(UIAlertAction *action) {
            [self getInfoAndDownloadAttachment:attach];
        }];
        return;
    }
    int userScore = [userInfo[@"score"] intValue];
    int minScore = [attach[@"minscore"] intValue];
    if (minScore > userScore) {
        [self showAlertWithTitle:@"无法购买该附件" message:[NSString stringWithFormat:@"您的权限不足：\n附件要求至少有%d积分，您当前有%d积分", minScore, userScore]];
        return;
    }
    int price = [attach[@"price"] intValue];
    if (price > userScore) {
        [self showAlertWithTitle:@"无法购买该附件" message:[NSString stringWithFormat:@"您的积分不足：\n附件售价为%d积分，您当前有%d积分", price, userScore]];
        return;
    }
    [self showAlertWithTitle:[NSString stringWithFormat:@"确认购买附件 (%@)", fileSize] message:[NSString stringWithFormat:@"附件售价为%d积分，您当前有%d积分，购买后将剩余%d积分\n\n%@", price, userScore, userScore - price, generalInfo] confirmTitle:@"确认" confirmAction:^(UIAlertAction *action) {
        [self getInfoAndDownloadAttachment:attach];
    }];
}

- (void)getInfoAndDownloadAttachment:(NSDictionary *)attach {
    [hud showWithProgressMessage:@"正在下载"];
    NSDictionary *params = @{
        @"method": @"download",
        @"id": attach[@"id"]
    };
    [Helper callApiWithParams:params toURL:@"attach" callback:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            [hud hideWithFailureMessage:@"下载失败"];
            [self showAlertWithTitle:@"错误" message:err.localizedDescription];
            return;
        }
        NSInteger code = [result[0][@"code"] integerValue];
        if (code != 0 || [result[0][@"path"] length] == 0) {
            [hud hideWithFailureMessage:@"下载失败"];
            NSString *errorMessage = @"未知错误";
            switch (code) {
                case 1:
                    errorMessage = @"非法请求";
                    break;
                case 2:
                    errorMessage = @"服务器错误";
                    break;
                case 3:
                    errorMessage = @"您未登录";
                    break;
                case 4:
                    errorMessage = @"权限不足";
                    break;
                case 5:
                    errorMessage = @"积分不足";
                    break;
                default:
                    break;
            }
            [self showAlertWithTitle:@"错误" message:errorMessage];
            return;
        }
        
        [self downloadAttachment:attach[@"name"] path:result[0][@"path"]];
    }];
}

- (void)downloadAttachment:(NSString *)fileName path:(NSString *)path {
    if (hud.isHidden) {
        [hud showWithProgressMessage:@"正在下载"];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/bbs/attachment/%@", CHEXIE, path];
    [Downloader loadURLString:filePath progress:^(float progress, NSUInteger expectedBytes) {
        [hud updateToProgress:progress];
    } completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || !data || data.length == 0) {
            [hud hideWithFailureMessage:@"下载失败"];
            [self showAlertWithTitle:@"错误" message:error ? error.localizedDescription : @"文件下载失败，请检查您的网络连接！" confirmTitle:@"重试" confirmAction:^(UIAlertAction *action) {
                dispatch_global_after(0.5, ^{
                    [self downloadAttachment:fileName path:path];
                });
            }];
            return;
        }
        [hud hideWithSuccessMessage:@"下载成功"];
        [NOTIFICATION postNotificationName:@"previewFile" object:nil userInfo:@{
            @"fileData": data,
            @"fileName": fileName,
            @"fileTitle": [NSString stringWithFormat:@"附件：%@", fileName]
        }];
    }];
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
    
    if ([path hasPrefix:@"capubbs-attach:"]) {
        [self askForDownloadAttachment:path];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([path containsString:@"/bbs/user"]) {
        NSRange range = [path rangeOfString:@"name="];
        if (range.location != NSNotFound) {
            NSString *uid = [path substringFromIndex:range.location + range.length];
            uid = [uid stringByRemovingPercentEncoding];
            [self performSegueWithIdentifier:@"userInfo" sender:uid];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSDictionary *dict = [Helper getLink:path];
    if (dict.count > 0 && [dict[@"tid"] length] > 0) {
        int p = [dict[@"p"] intValue];
        int floor = [dict[@"floor"] intValue];
        if ([dict[@"bid"] isEqualToString:self.bid] && [dict[@"tid"] isEqualToString:self.tid] && p == page) {
            BOOL hasScrolled = NO;
            if (floor > 0) {
                for (int i = 0; i < data.count; i++) {
                    if ([data[i][@"floor"] intValue] == floor) {
                        hasScrolled = YES;
                        [self tryScrollTo:i animated:NO];
                    }
                }
            }
            if (!hasScrolled) {
                [self showAlertWithTitle:@"提示" message:floor > 0 ? [NSString stringWithFormat:@"该链接指向本页第%d楼", floor] : @"该链接指向本页"];
            }
        } else {
            ContentViewController *next = [self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            next.bid = dict[@"bid"];
            next.tid = dict[@"tid"];
            if (p > 0) {
                next.destinationPage = dict[@"p"];
            }
            if (floor > 0) {
                next.destinationFloor = dict[@"floor"];
            }
            next.title = @"帖子跳转中";
            [self.navigationController pushViewController:next animated:YES];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // 默认跳转外链页面
    tempPath = path;
    [self performSegueWithIdentifier:@"web" sender:nil];
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)deletePost {
    if (![Helper checkLogin:YES]) {
        return;
    }
    [hud showWithProgressMessage:@"正在删除"];
    NSDictionary *dict = @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"pid" : data[selectedIndex][@"floor"]
    };
    [Helper callApiWithParams:dict toURL:@"delete" callback:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            [hud hideWithFailureMessage:@"删除失败"];
            [self showAlertWithTitle:@"错误" message:err.localizedDescription];
            return;
        }
        NSInteger code = [result[0][@"code"] integerValue];
        if (code == 0) {
            [hud hideWithSuccessMessage:@"删除成功"];
        } else {
            [hud hideWithFailureMessage:@"删除失败"];
        }
        switch (code) {
            case 0:{
                [self.tableView setEditing:NO];
                NSMutableArray *tmpData = [NSMutableArray arrayWithArray:data];
                [tmpData removeObjectAtIndex:selectedIndex];
                data = [tmpData copy];
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                if ([self.tableView numberOfRowsInSection:0] == 0) {
                    if (page > 1) {
                        page--;
                        dispatch_main_after(0.5, ^{
                            [self refresh];
                        });
                    } else {
                        [NOTIFICATION postNotificationName:@"refreshList" object:nil];
                        dispatch_main_after(0.5, ^{
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    }
                } else {
                    dispatch_main_after(0.5, ^{
                        [self refresh];
                    });
                }
            }
                break;
            case 1:{
                [self showAlertWithTitle:@"错误" message:@"密码错误，请重新登录！"];
                return;
            }
                break;
            case 2:{
                [self showAlertWithTitle:@"错误" message:@"用户不存在，请重新登录！"];
                return;
            }
                break;
            case 3:{
                [self showAlertWithTitle:@"错误" message:@"您的账号被封禁，请联系管理员！"];
                return;
            }
                break;
            case 4:{
                [self showAlertWithTitle:@"错误" message:@"您的操作过频繁，请稍后再试！"];
                return;
            }
                break;
            case 5:{
                [self showAlertWithTitle:@"错误" message:@"文章被锁定，无法操作！"];
                return;
            }
                break;
            case 6:{
                [self showAlertWithTitle:@"错误" message:@"帖子不存在或服务器错误！"];
                return;
            }
                break;
            case 10:{
                [self showAlertWithTitle:@"错误" message:@"您的权限不够，无法操作！"];
                return;
            }
                break;
            case -25: {
                [self showAlertWithTitle:@"错误" message:@"您长时间未登录，请重新登录！"];
                return;
            }
                break;
            default:{
                [self showAlertWithTitle:@"错误" message:@"发生未知错误！"];
                return;
            }
        }
    }];
}

- (void)toggleCollection {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"collection"]];
    NSMutableDictionary *mdic;
    if (self.isCollection) {
        for (mdic in array) {
            if ([self.bid isEqualToString:mdic[@"bid"]] && [self.tid isEqualToString:mdic[@"tid"]]) {
                [array removeObject:mdic];
                self.isCollection = NO;
                [hud showAndHideWithSuccessMessage:@"取消收藏"];
                break;
            }
        }
    } else {
        mdic = [NSMutableDictionary dictionaryWithDictionary:@{
            @"collectionTime" : [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]],
            @"bid" : self.bid,
            @"tid" : self.tid,
            @"title" : [Helper restoreTitle:self.title]
        }];
        [array addObject:mdic];
        self.isCollection = YES;
        [hud showAndHideWithSuccessMessage:@"收藏完成"];
    }
    [DEFAULTS setObject:array forKey:@"collection"];
    [self updateCollection:NO];
    NSLog(@"Toggle Collection");
    [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
    if ([[self.tableView visibleCells] containsObject:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]]) {
        [self.tableView reloadData];
    }
}

- (IBAction)backOrCollect:(id)sender {
    if (page > 1) {
        [self jumpTo:page - 1];
    } else {
        [self toggleCollection];
    }
}

- (IBAction)forward:(id)sender {
    [self jumpTo:page + 1];
}

- (IBAction)action:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
            @"recipients": REPORT_EMAIL,
            @"subject": @"CAPUBBS 举报违规帖子",
            @"body": [NSString stringWithFormat:@"您好，我是%@，我在帖子 <a href=\"%@\">%@</a> 中发现了违规内容，希望尽快处理，谢谢！", ([UID length] > 0) ? UID : @"匿名用户", [[self getCurrentUrl] absoluteString], self.title],
            @"isHTML": @(YES),
            @"fallbackMessage": @"请前往网络维护板块反馈"
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:self.isCollection ? @"取消收藏" : @"收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self toggleCollection];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *title = self.title;
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[title, [self getCurrentUrl]] applicationActivities:nil];
        activityViewController.popoverPresentationController.barButtonItem = self.buttonAction;
        [self presentViewControllerSafe:activityViewController];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"打开网页版" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [AppDelegate openURL:[[self getCurrentUrl] absoluteString] fullScreen:YES];
    }]];
    int biggerSize = textSize + 10;
    int smallerSize = textSize - 10;
    if (biggerSize!= 100 && biggerSize <= 200) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"增大缩放至%d%%", biggerSize] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = biggerSize;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    if (smallerSize != 100 & smallerSize >= 20) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"减小缩放至%d%%", smallerSize] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = smallerSize;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    if (textSize != 100) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"恢复缩放至100%" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = 100;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    alertController.popoverPresentationController.barButtonItem = self.buttonAction;
    [self presentViewControllerSafe:alertController];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled && swipeDirection == 0)
            [self jumpTo:page + 1];
        if (page > 1 && swipeDirection == 1)
            [self jumpTo:page - 1];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled && swipeDirection == 1)
            [self jumpTo:page + 1];
        if (page > 1 && swipeDirection == 0)
            [self jumpTo:page - 1];
    }
}

- (void)refreshLzl:(NSNotification *)notification {
    if (selectedIndex >= 0 && selectedIndex < data.count && notification && [[notification.userInfo objectForKey:@"fid"] isEqualToString:data[selectedIndex][@"fid"]]) {
        NSDictionary *details = notification.userInfo[@"details"];
        data[selectedIndex][@"lzldetail"] = details;
        dispatch_main_async_safe(^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)triggerBackgroundChange:(WKWebView *)webView {
    [webView evaluateJavaScript:@"(()=>{const bodyMask=document.getElementById('body-mask');if(!bodyMask){return;}if(bodyMask.style.backgroundColor){ bodyMask.style.backgroundColor='';}else{bodyMask.style.backgroundColor='rgba(127,127,127,0.5)';}})()" completionHandler:nil];
}

- (void)doubleTapWeb:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            return;
        }
        if ([[DEFAULTS objectForKey:@"changeBackground"] boolValue]) {
            ContentCell *cell = (ContentCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [hud showAndHideWithSuccessMessage:@"双击切换背景"];
            [self triggerBackgroundChange:cell.webViewContainer.webView];
        }
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            longPressIndexPath = nil;
            return;
        }
        ContentCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            longPressIndexPath = nil;
            return;
        }
        CGPoint pointInCell = [sender locationInView:cell.contentView];
        UIView *hitView = [cell.contentView hitTest:pointInCell withEvent:nil];
        if ([hitView isDescendantOfView:cell.topView]) {
            longPressIndexPath = nil;
            selectedIndex = indexPath.row;
            ContentCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self showMoreAction:cell.labelAuthor];
        } else if (hitView == cell.contentView && [[DEFAULTS objectForKey:@"changeBackground"] boolValue]) {
            longPressIndexPath = indexPath;
            [self triggerBackgroundChange:cell.webViewContainer.webView];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        if (longPressIndexPath) {
            ContentCell *cell = [self.tableView cellForRowAtIndexPath:longPressIndexPath];
            if (cell && [[DEFAULTS objectForKey:@"changeBackground"] boolValue]) {
                [self triggerBackgroundChange:cell.webViewContainer.webView];
            }
            longPressIndexPath = nil;
        }
    }
}

- (IBAction)moreAction:(UIButton *)sender {
    selectedIndex = sender.tag;
    [self showMoreAction:sender];
}

- (void)showMoreAction:(UIView *)view {
    NSDictionary *item = data[selectedIndex];
    NSString *text = item[@"text"];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"引用" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([Helper checkLogin:YES]) {
            NSString *content = text;
            content = [self getValidQuote:content];
            defaultContent = [NSString stringWithFormat:@"[quote=%@]%@[/quote]\n", item[@"author"], content];
            [self performSegueWithIdentifier:@"compose" sender:self.buttonCompose];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *content = text;
        content = [Helper removeHTML:content restoreFormat:NO];
        [[UIPasteboard generalPasteboard] setString:content];
        [hud showAndHideWithSuccessMessage:@"复制完成"];
    }]];
    if ([Helper checkRight] > 1 || [item[@"author"] isEqualToString:UID]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"编辑" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            defaultTitle = [item[@"floor"] isEqualToString:@"1"]?self.title:[NSString stringWithFormat:@"Re: %@",self.title];
            isEdit = YES;
            NSString *content = text;
            content = [Helper simpleEscapeHTML:content processLtGt:NO];
            defaultContent = content;
            [self performSegueWithIdentifier:@"compose" sender:nil];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if ([Helper checkLogin:YES]) {
                NSString *content = text;
                content = [self getCollectionText:content];
                if (content.length > 50) {
                    content = [[content substringToIndex:49] stringByAppendingString:@"..."];
                }
                [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确定要删除该楼层吗？\n删除操作不可逆！\n\n作者：%@\n正文：%@", item[@"author"], content] confirmTitle:@"删除" confirmAction:^(UIAlertAction *action) {
                    [self deletePost];
                }];
            }
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    alertController.popoverPresentationController.sourceView = view;
    alertController.popoverPresentationController.sourceRect = view.bounds;
    [self presentViewControllerSafe:alertController];
}

#pragma mark - HTML processing

- (NSString *)getCollectionText:(NSString *)text {
    if (!text || text.length == 0) {
        return @"";
    }
    NSString *content = [Helper transToHTML:text];
    content = [Helper removeHTML:content restoreFormat:NO];
    content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    while ([content hasPrefix:@" "] || [content hasPrefix:@"\t"]) {
        content = [content substringFromIndex:@" ".length];
    }
    return content;
}

- (NSString *)getValidQuote:(NSString *)text {
    if (!text || text.length == 0) {
        return @"";
    }
    text = [Helper simpleEscapeHTML:text processLtGt:NO];
    
    NSString *expression = @"<quote>((.|[\r\n])*?)</quote>"; // 去除帖子中的引用
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    int maxLength = 100;
    int maxCountXIndex = 2 * maxLength * maxLength;
    if (text.length <= maxLength) {
        return text;
    }
    
    int index = 0, count = 0;
    NSMutableArray * htmlLabel = [NSMutableArray array];
    NSArray *exception = @[@"br", @"br/", @"hr", @"img", @"input", @"isindex", @"area", @"base", @"basefont",@"bgsound", @"col", @"embed", @"frame", @"keygen", @"link",@"meta", @"nextid", @"param", @"plaintext", @"spacer", @"wbr"];
    while (YES) {
        if (index >= text.length) {
            break;
        }
        if (![[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@"<"]) {
            count++;
            if (count > maxLength || count * index >= maxCountXIndex) {
                // NSLog(@"Quote Count:%d Index:%d", count, index);
                break;
            } else {
                index++;
                continue;
            }
        } else {
            int tempIndex = index + 1;
            BOOL isRemove = NO;
            if ([[text substringWithRange:NSMakeRange(tempIndex, 1)] isEqualToString:@"/"]) {
                isRemove = YES;
                tempIndex++;
            }
            while (YES) {
                if ([[text substringWithRange:NSMakeRange(tempIndex, 1)] isEqualToString:@" "] || [[text substringWithRange:NSMakeRange(tempIndex, 1)] isEqualToString:@">"]) {
                    NSString *label = [text substringWithRange:NSMakeRange(index + 1 + isRemove, tempIndex - index - 1 - isRemove)];
                    BOOL isBlank = NO;
                    for (NSString *exc in exception) {
                        if ([label isEqualToString:exc]) {
                            isBlank = YES;
                        }
                    }
                    if (!isBlank) {
                        if (isRemove) {
                            for (int i = (int)htmlLabel.count - 1; i >= 0; i--) {
                                if ([htmlLabel[i] isEqualToString:label]) {
                                    [htmlLabel removeObjectAtIndex:i];
                                    break;
                                }
                            }
                        } else {
                            [htmlLabel addObject:label];
                        }
                    }
                    break;
                }
                tempIndex++;
            }
            
            while (YES) {
                if ([[text substringWithRange:NSMakeRange(index++, 1)] isEqualToString:@">"]) {
                    break;
                }
            }
        }
    }
    if (index + 1 < text.length) {
        text = [[text substringToIndex:index] stringByAppendingString:@"..."];
    } else {
        text = [text substringToIndex:index];
    }
    if (htmlLabel.count != 0) {
        for (int i = (int)htmlLabel.count - 1; i >= 0; i--) {
            text = [text stringByAppendingString:[NSString stringWithFormat:@"</%@>", htmlLabel[i]]];
        }
    }
    //NSLog(@"%@", text);
    return text;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
        if (sender != nil) {
            defaultTitle = [NSString stringWithFormat:@"Re: %@",self.title];
        }
        
        dest.tid = self.tid;
        dest.bid = self.bid;
        dest.defaultTitle = defaultTitle;
        dest.defaultContent = defaultContent;
        dest.isEdit = isEdit;
        
        if (isEdit) {
            dest.floor = [NSString stringWithFormat:@"%d",[data[selectedIndex][@"floor"] intValue]];
            dest.attachments = data[selectedIndex][@"attach"];
            if ([data[selectedIndex][@"author"] isEqualToString:UID]) {
                NSString *sig = data[selectedIndex][@"signum"];
                if ([Helper isPureInt:sig]) {
                    dest.defaultSigIndex = sig;
                }
            } else {
                dest.showEditOthersAlert = YES;
                dest.defaultSigIndex = @"0";
            }
        }
        
        defaultTitle = nil;
        defaultContent = nil;
        selectedIndex = -1;
        isEdit = NO;
    } else if ([segue.identifier isEqualToString:@"lzl"]) {
        LzlViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        UIView *source;
        if ([sender isKindOfClass:[UIButton class]]) {
            source = sender;
            selectedIndex = source.tag;
        } else if (selectedIndex >= 0) {
            ContentCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
            if (cell) {
                source = cell.buttonLzl;
            }
        }
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:source halfScreen:YES];
        dest.fid = data[selectedIndex][@"fid"];
        dest.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@#%@", [[self getCurrentUrl] absoluteString], data[selectedIndex][@"floor"]]];
        if (data[selectedIndex][@"lzldetail"]) {
            dest.defaultData = data[selectedIndex][@"lzldetail"];
        } else {
            dest.defaultData = @[];
        }
    } else if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:sender halfScreen:YES];
        if ([sender isKindOfClass:[UIButton class]]) {
            UIButton *button = sender;
            dest.ID = data[button.tag][@"author"];
            ContentCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:button.tag inSection:0]];
            if (cell && ![cell.icon.image isEqual:PLACEHOLDER]) {
                dest.iconData = UIImagePNGRepresentation(cell.icon.image);
            }
        } else if ([sender isKindOfClass:[NSString class]]) {
            dest.ID = sender;
        }
    } else if ([segue.identifier isEqualToString:@"web"]) {
        WebViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        dest.URL = tempPath;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end

