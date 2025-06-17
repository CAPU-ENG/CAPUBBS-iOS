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

static const CGFloat kOtherViewHeight = 118;
static const CGFloat kWebViewMinHeight = 40;

@interface ContentViewController ()

@end

@implementation ContentViewController

#pragma mark - View control

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    textSize = [[DEFAULTS objectForKey:@"textSize"] intValue];
    performer = [[ActionPerformer alloc] init];
    if ([self.floor integerValue] > 0) { // 进入时直接跳至指定页
        page = ceil([self.floor floatValue] / 12);
    } else {
        page = 1;
    }
    selectedIndex = -1;
    isEdit = NO;
    scrollTargetRow = -1;
    heights = [[NSMutableArray alloc] init];
    tempHeights = [[NSMutableArray alloc] init];
    HTMLStrings = [[NSMutableArray alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [NOTIFICATION addObserver:self selector:@selector(refreshLzl:) name:@"refreshLzl" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(shouldRefresh:) name:@"refreshContent" object:nil];
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
    activity.webpageURL = [NSURL URLWithString:URL];
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

- (void)jumpTo:(int)pageNum {
    [hud showWithProgressMessage:@"加载中"];
    int oldPage = page;
    if ((page = pageNum) == 1) {
        self.toolbarItems = @[self.buttonCollection, self.barFreeSpace, self.buttonJump, self.barFreeSpace, self.buttonAction, self.barFreeSpace, self.buttonCompose, self.barFreeSpace, self.buttonForward];
    } else {
        self.toolbarItems = @[self.buttonBack, self.barFreeSpace, self.buttonJump, self.barFreeSpace, self.buttonAction, self.barFreeSpace, self.buttonCompose, self.barFreeSpace, self.buttonForward];
    }
    self.buttonBack.enabled = (page > 1);
    self.buttonForward.enabled = NO;
    self.buttonLatest.enabled = NO;
    self.buttonJump.enabled = NO;
    self.buttonCompose.enabled = NO;
    URL = [NSString stringWithFormat:@"%@/bbs/content/?tid=%@&bid=%@&p=%ld", CHEXIE, self.tid, self.bid, (long)page];
    activity.webpageURL = [NSURL URLWithString:URL];
    activity.title = self.title;
    NSDictionary *dict = @{
        @"p" : [NSString stringWithFormat:@"%ld", (long)pageNum],
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"raw" : @"YES",
    };
    [performer performActionWithDictionary:dict toURL:@"show" withBlock:^(NSArray *result, NSError *err) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        if (err || result.count == 0 || [result[0][@"time"] hasPrefix:@"1970"]) {
            page = oldPage;
            if (!err && (result.count == 0 || [result[0][@"time"] hasPrefix:@"1970"])) {
                self.title = @"没有这个帖子";
            }
            self.buttonCollection.enabled = NO;
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
            [self showAlertWithTitle:@"读取失败" message:result[0][@"msg"]];
            [hud hideWithFailureMessage:@"加载失败"];
            return;
        }
        data = [NSMutableArray array];
        for (NSDictionary *entry in result) {
            NSMutableDictionary *fixedEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
            id lzlDetail = fixedEntry[@"lzldetail"];
            if (!lzlDetail) {
                fixedEntry[@"lzldetail"] = @[];
            } else if (![lzlDetail isKindOfClass:[NSArray class]]) {
                fixedEntry[@"lzldetail"] = @[lzlDetail];
            }
            // text
            NSString *textraw = fixedEntry[@"textraw"];
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
            if (!fixedEntry[@"sigraw"] || [fixedEntry[@"sigraw"] isEqualToString:@"Array"]) {
                fixedEntry[@"sig"] = @"";
            } else {
                fixedEntry[@"sig"] = fixedEntry[@"sigraw"];
            }
            [fixedEntry removeObjectForKey:@"sigraw"];
            
            [data addObject:fixedEntry];
        }
        
        if (!(self.isCollection && page > 1)) {
            [self updateCollection];
        }

        NSString *titleText = data.firstObject[@"title"];
        self.title = [ActionPerformer restoreTitle:titleText];
        isLast = [data[0][@"nextpage"] isEqualToString:@"false"];
        self.buttonForward.enabled = !isLast;
        self.buttonLatest.enabled = !isLast;
        self.buttonJump.enabled = ([[data lastObject][@"pages"] integerValue] > 1);
        self.buttonCompose.enabled = [ActionPerformer checkLogin:NO];
        [self clearHeightsAndHTMLCaches:^{
            [hud hideWithSuccessMessage:@"加载成功"];
            for (int i = 0; i < data.count; i++) {
                ContentCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                if (cell) {
                    if (cell.webViewContainer.webView.isLoading) {
                        [cell.webViewContainer.webView stopLoading];
                    }
                    if (cell.webviewUpdateTimer && [cell.webviewUpdateTimer isValid]) {
                        [cell.webviewUpdateTimer invalidate];
                    }
                    // 加载空HTML以快速清空，防止reuse后还短暂显示之前的内容
                    [cell.webViewContainer.webView loadHTMLString:EMPTY_HTML baseURL:[NSURL URLWithString:CHEXIE]];
                }
            }
            [self.tableView reloadData];
            if (data.count != 0) {
                if (self.willScrollToBottom) {
                    self.willScrollToBottom = NO;
                    [self tryScrollTo:data.count - 1 animated:NO];
                } else {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
                for (int i = 0; i < data.count; i++) {
                    NSDictionary *dict = data[i];
                    if (self.destinationFloor.length > 0 && [dict[@"floor"] isEqualToString:self.destinationFloor]) {
                        [self tryScrollTo:i animated:NO];
                        if (self.openDestinationLzl) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                selectedIndex = [data indexOfObject:dict];
                                [self performSegueWithIdentifier:@"lzl" sender:nil];
                            });
                        }
                    }
                }
                self.openDestinationLzl = NO;
                self.destinationFloor = @"";
            }
        }];
    }];
}

- (void)updateCollection {
    if (data.count == 0) {
        return;
    }
    NSMutableArray *collections = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"collection"]];
    for (NSMutableDictionary *mdic in collections) {
        if ([self.bid isEqualToString:mdic[@"bid"]] && [self.tid isEqualToString:mdic[@"tid"]]) {
            if (page == 1) { // 更新楼主信息
                NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:mdic];
                [tmp addEntriesFromDictionary:data[0]];
                tmp[@"text"] = [self getCollectionText:tmp[@"text"]];
                tmp[@"title"] = [ActionPerformer restoreTitle:tmp[@"title"]];
                
                BOOL hasChange = NO;
                for (NSString *keyword in @[@"title", @"text", @"author", @"icon"]) {
                    if (!([tmp[keyword] isEqualToString:mdic[keyword]])) {
                        hasChange = YES;
                    }
                }
                // Remove unnecessary fields to save storage
                for (NSString *keyword in @[@"lzldetail", @"sig"]) {
                    [tmp removeObjectForKey:keyword];
                }
                
                [collections removeObject:mdic];
                [collections addObject:tmp];
                [DEFAULTS setObject:collections forKey:@"collection"];
                if (hasChange) {
                    NSLog(@"Update Collection");
                    [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
                }
            }
            self.isCollection = YES;
            break;
        }
        self.isCollection = NO;
    }
    [self.buttonCollection setImage:[UIImage imageNamed:(self.isCollection ? @"star-full" : @"star-empty")]];
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
            NSString *text = [ActionPerformer transToHTML:dict[@"text"]];
            NSString *sig = [ActionPerformer transToHTML:dict[@"sig"]];
            NSString *html = [ActionPerformer htmlStringWithText:text sig:sig textSize:textSize];
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
        
        // Do not clear tempHeights
        [heights removeAllObjects];
        [HTMLStrings removeAllObjects];
        for (int i = 0; i < data.count; i++) {
            [heights addObject:@0];
            [HTMLStrings addObject:newHTMLStrings[i]];
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

- (void)shouldRefresh:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo[@"isEdit"] boolValue] == YES) {
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[data lastObject] [@"pages"]] preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"页码";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"好"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *pageip = alert.textFields.firstObject.text;
        int pagen = [pageip intValue];
        if (pagen <= 0 || pagen > [[data lastObject] [@"pages"] integerValue]) {
            [self showAlertWithTitle:@"错误" message:@"输入不合法"];
            return;
        }
        [self jumpTo:pagen];
    }]];
    [self presentViewControllerSafe:alert];
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
    if (!lzlDetail || lzlDetail.count == 0) {
        return 0;
    }
    // Show at most 5 rows
    return MIN(8, lzlDetail.count) * 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat lzlHeight = [self getLzlHeightForRow:indexPath.row];
    CGFloat webViewHeight = 0;
    for (NSArray *candidate in @[heights, tempHeights]) {
        if (candidate.count > indexPath.row && [candidate[indexPath.row] floatValue] > 0) {
            webViewHeight = [candidate[indexPath.row] floatValue];
            break;
        }
    }
    return kOtherViewHeight + lzlHeight + (lzlHeight > 0 ? 8 : 0) + MIN(MAX(kWebViewMinHeight, webViewHeight), WEB_VIEW_MAX_HEIGHT);
}

- (UITableViewCell *)getCellForView:(UIView *)view {
    UIView *currentView = view;
    while (currentView != nil) {
        if ([currentView isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)currentView;
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

- (void)updateWebView:(WKWebView *)webView {
    NSUInteger row = webView.tag;
    if (!self.isViewLoaded || !self.view.window ||
        !self.tableView || !self.tableView.window) { // Fix occasional crash
        return;
    }
    UITableViewCell *cell = [self getCellForView:webView];
    if (!cell || [self.tableView indexPathForCell:cell].row != row) {
        return;
    }
    
    [webView evaluateJavaScript:[NSString stringWithFormat:@"if(document.getElementById('body-wrapper')){document.body.style.zoom= '%d%%';document.getElementById('body-wrapper').scrollHeight;}", textSize] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"JS 执行失败: %@", error);
            return;
        }
        float height = 0;
        if (result && [result isKindOfClass:[NSNumber class]]) {
            height = [result floatValue] * (textSize / 100.0);
        }
        if (height > 0 && row < heights.count && height - [heights[row] floatValue] >= 1) {
            heights[row] = @(height);
            tempHeights[row] = @(height);
            if (scrollTargetRow >= 0) {
                [UIView performWithoutAnimation:^{
                    [self.tableView beginUpdates];
                    [self.tableView endUpdates];
                    [self maybeTriggerTableViewScrollAnimated:NO];
                }];
            } else {
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
                [self maybeTriggerTableViewScrollAnimated:NO];
            }
        }
    }];
}

- (void)timerFiredupdateWebView:(NSTimer *)timer {
    [self updateWebView:timer.userInfo];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSUInteger row = webView.tag;
    if (!self.isViewLoaded || !self.view.window ||
        !self.tableView || !self.tableView.window) { // Fix occasional crash
        return;
    }
    ContentCell *cell = (ContentCell *)[self getCellForView:webView];
    if (!cell || [self.tableView indexPathForCell:cell].row != row) {
        return;
    }
    if (cell.webviewUpdateTimer && [cell.webviewUpdateTimer isValid]) {
        [cell.webviewUpdateTimer invalidate];
    }
    // Do not trigger immediately, the webview might still be showing the previous content.
    cell.webviewUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timerFiredupdateWebView:) userInfo:webView repeats:YES];
    [cell.webViewContainer.webView.configuration.userContentController removeScriptMessageHandlerForName:@"imageClickHandler"];
    [cell.webViewContainer.webView.configuration.userContentController addScriptMessageHandler:self name:@"imageClickHandler"];
    [cell.webViewContainer.webView evaluateJavaScript:@"window._imageClickHandlerAvailable = true;" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSUInteger row = webView.tag;
    if (!self.isViewLoaded || !self.view.window ||
        !self.tableView || !self.tableView.window) { // Fix occasional crash
        return;
    }
    ContentCell *cell = (ContentCell *)[self getCellForView:webView];
    if (!cell || [self.tableView indexPathForCell:cell].row != row) {
        return;
    }
    [cell.indicatorLoading stopAnimating];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = @"";
    if (SIMPLE_VIEW == NO && data.count > 0) {
        header = [NSString stringWithFormat:@"%@ 第%ld/%@页", [ActionPerformer getBoardTitle:self.bid], (long)page, [data lastObject] [@"pages"]];
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
    [cell.buttonLzl setTitle:[NSString stringWithFormat:@"评论 (%@)",dict[@"lzl"]] forState:UIControlStateNormal];
    if ([dict[@"lzl"] isEqualToString:@"0"]) {
        [cell.buttonLzl setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    } else {
        [cell.buttonLzl setTitleColor:BLUE forState:UIControlStateNormal];
    }
    
    if (SIMPLE_VIEW== NO) {
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
    [cell.webViewContainer.webView loadHTMLString:HTMLStrings[indexPath.row] baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/?", CHEXIE]]];
    
    
    if (heights.count > indexPath.row && [heights[indexPath.row] floatValue] > 0) {
        [cell.indicatorLoading stopAnimating];
    } else {
        [cell.indicatorLoading startAnimating];
    }
    
    if (cell.gestureRecognizers.count == 0 && cell.topView.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapWeb:)];
        [tapTwice setNumberOfTapsRequired:2];
        [cell addGestureRecognizer:tapTwice];
        [cell.topView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTop:)]];
    }
    NSArray *lzlDetail = dict[@"lzldetail"];
    if (!lzlDetail || lzlDetail.count == 0 || SIMPLE_VIEW) {
        cell.lzlTableView.hidden = YES;
    } else {
        cell.lzlTableView.hidden = NO;
        cell.lzlDetail = dict[@"lzldetail"];
        [cell.lzlTableView reloadData];
    }
    CGFloat lzlHeight = [self getLzlHeightForRow:indexPath.row];
    [cell.webviewBottomSpacing setConstant:lzlHeight ? 12 + lzlHeight : 5];
    [cell layoutIfNeeded];
    
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollTargetRow inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    });
}

- (void)cancelScroll {
    // 用户有任何操作都取消scroll
    scrollTargetRow = -1;
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
    return YES;
}

// 滚动时调用此方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // NSLog(@"scrollView.contentOffset:%f, %f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (isAtEnd == NO && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height) {
        if (heights.count > 0 && [[heights lastObject] floatValue] > 0) {
            [self.navigationController setToolbarHidden:NO animated:YES];
            isAtEnd = YES;
        }
    }
    if (isAtEnd == NO && scrollView.dragging) { // 拖拽
        if ((scrollView.contentOffset.y - contentOffsetY) > 5.0f) { // 向上拖拽
            [self.navigationController setToolbarHidden:YES animated:YES];
        } else if ((contentOffsetY - scrollView.contentOffset.y) > 5.0f) { // 向下拖拽
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"imageClickHandler"]) {
        [self handleImageClickWithPayload:message.body];
    }
}

- (void)handleImageClickWithPayload:(NSDictionary *)payload {
    if ([payload[@"loading"] boolValue]) {
        [hud showWithProgressMessage:@"图片加载中"];
        return;
    }
    NSString *base64Data = payload[@"data"] ?: @"";
    NSString *imgSrc = payload[@"src"] ?: @"";
    NSString *alt = payload[@"alt"] ?: @"";
    // 去掉前缀
    NSRange range = [base64Data rangeOfString:@","];
    if (range.location != NSNotFound) {
        NSString *alt = payload[@"alt"];
        NSString *base64String = [base64Data substringFromIndex:range.location + 1];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        ImageFileType type = [AnimatedImageView fileType:imageData];
        if (type != ImageFileTypeUnknown) {
            [hud hideWithSuccessMessage:@"图片加载成功"];
            NSString *fileName = [NSString stringWithFormat:@"%@.%@", [ActionPerformer md5:imgSrc], [AnimatedImageView fileExtension:type]];
            [self presentImage:imageData fileName:fileName alt:alt];
            return;
        }
    }
    
    NSString *errorMessage = payload[@"error"] ?: @"图片加载失败";
    // Try reload in app to overcome CORS. (Most external sites will fail the fetch request)
    NSURL *imageUrl = [NSURL URLWithString:imgSrc];
    if (imageUrl) {
        [hud showWithProgressMessage:@"图片加载中"];
        NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable idata, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            ImageFileType type = [AnimatedImageView fileType:idata];
            if (error || type == ImageFileTypeUnknown) {
                [hud hideWithFailureMessage:!error ? errorMessage : @"未知图片格式"];
                return;
            }
            [hud hideWithSuccessMessage:@"图片加载成功"];
            NSString *fileName = [NSString stringWithFormat:@"%@.%@", [ActionPerformer md5:imgSrc], [AnimatedImageView fileExtension:type]];
            [self presentImage:idata fileName:fileName alt:alt];
        }];
        [task resume];
    } else {
        [hud hideWithFailureMessage:errorMessage];
    }
}

- (void)presentImage:(NSData *)imageData fileName:(NSString *)fileName alt:(NSString *)alt {
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileName];
    [imageData writeToFile:filePath atomically:YES];
    [NOTIFICATION postNotificationName:@"previewFile" object:nil userInfo:@{
        @"filePath": filePath,
        @"fileName": alt.length > 0 ? alt : @"查看帖子图片",
    }];
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
    
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"((http://|https://)?/bbs/user)" options:0 error:nil];
    NSArray *matches = [regular matchesInString:path options:0 range:NSMakeRange(0, path.length)];
    if (matches.count != 0) {
        NSRange range = [path rangeOfString:@"name="];
        if (range.location != NSNotFound) {
            NSString *uid = [path substringFromIndex:range.location + range.length];
            uid = [uid stringByRemovingPercentEncoding];
            [self performSegueWithIdentifier:@"userInfo" sender:uid];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSDictionary *dict = [ActionPerformer getLink:path];
    if (dict.count > 0 && [dict[@"tid"] length] > 0) {
        int p = [dict[@"p"] intValue];
        int floor = [dict[@"floor"] intValue];
        if ([dict[@"bid"] isEqualToString:self.bid] && [dict[@"tid"] isEqualToString:self.tid] && p > 0) {
            if (p == page) {
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
                [self jumpTo:p];
            }
        } else {
            ContentViewController *next = [self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            next.bid = dict[@"bid"];
            next.tid = dict[@"tid"];
            next.floor = [NSString stringWithFormat:@"%d", page * 12];
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
    if (![ActionPerformer checkLogin:YES]) {
        return;
    }
    [hud showWithProgressMessage:@"正在删除"];
    NSDictionary *dict = @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"pid" : data[selectedIndex][@"floor"]
    };
    [performer performActionWithDictionary:dict toURL:@"delete" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            [hud hideWithFailureMessage:@"删除失败"];
            [self showAlertWithTitle:@"错误" message:err.localizedDescription];
            return;
        }
        NSInteger back=[result[0][@"code"] integerValue];
        if (back == 0) {
            [hud hideWithSuccessMessage:@"删除成功"];
        } else {
            [hud hideWithFailureMessage:@"删除失败"];
        }
        switch (back) {
            case 0:{
                [self.tableView setEditing:NO];
                [data removeObjectAtIndex:selectedIndex];
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                if ([self.tableView numberOfRowsInSection:0] == 0) {
                    if (page > 1) {
                        page--;
                        [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
                    } else {
                        [self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:@(YES) afterDelay:0.5];
                        [NOTIFICATION postNotificationName:@"refreshList" object:nil];
                    }
                } else {
                    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
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

- (IBAction)changeCollection:(id)sender {
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
            @"title" : [ActionPerformer restoreTitle:self.title]
        }];
        [array addObject:mdic];
        self.isCollection = YES;
        [hud showAndHideWithSuccessMessage:@"收藏完成"];
    }
    [DEFAULTS setObject:array forKey:@"collection"];
    if (self.isCollection == NO) {
        NSLog(@"Delete Collection");
        [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
    }
    [self updateCollection];
    if ([[self.tableView visibleCells] containsObject:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]]) {
        [self.tableView reloadData];
    }
}

- (IBAction)back:(id)sender {
    [self jumpTo:page - 1];
}

- (IBAction)forward:(id)sender {
    [self jumpTo:page + 1];
}

- (IBAction)action:(id)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
            @"recipients": REPORT_EMAIL,
            @"subject": @"CAPUBBS 举报违规帖子",
            @"body": [NSString stringWithFormat:@"您好，我是%@，我在帖子 <a href=\"%@\">%@</a> 中发现了违规内容，希望尽快处理，谢谢！", ([UID length] > 0) ? UID : @"匿名用户", URL, self.title],
            @"isHTML": @(YES),
            @"fallbackMessage": @"请前往网络维护板块反馈"
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:self.isCollection ? @"取消收藏" : @"收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeCollection:nil];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *shareURL = [[NSURL alloc] initWithString:URL];
        NSString *title = self.title;
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[title, shareURL] applicationActivities:nil];
        activityViewController.popoverPresentationController.barButtonItem = self.buttonAction;
        [self presentViewControllerSafe:activityViewController];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"打开网页版" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WebViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"webview"];
        CustomNavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
        dest.URL = URL;
        [navi setToolbarHidden:NO];
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewControllerSafe:navi];
    }]];
    int biggerSize = textSize + 10;
    int smallerSize = textSize - 10;
    if (biggerSize!= 100 && biggerSize <= 200) {
        [action addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"增大缩放至%d%%", biggerSize] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = biggerSize;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    if (smallerSize != 100 & smallerSize >= 20) {
        [action addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"减小缩放至%d%%", smallerSize] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = smallerSize;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    if (textSize != 100) {
        [action addAction:[UIAlertAction actionWithTitle:@"恢复缩放至100%" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            textSize = 100;
            [self clearHeightsAndHTMLCaches:nil];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonAction;
    [self presentViewControllerSafe:action];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled == YES && swipeDirection == 0)
            [self jumpTo:page + 1];
        if (self.buttonBack.enabled == YES && swipeDirection == 1)
            [self jumpTo:page - 1];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled == YES && swipeDirection == 1)
            [self jumpTo:page + 1];
        if (self.buttonBack.enabled == YES && swipeDirection == 0)
            [self jumpTo:page - 1];
    }
}

- (void)refreshLzl:(NSNotification *)notification {
    if (selectedIndex >= 0 && selectedIndex < data.count && notification && [[notification.userInfo objectForKey:@"fid"] isEqualToString:data[selectedIndex][@"fid"]]) {
        NSDictionary *details = notification.userInfo[@"details"];
        int num = (int)details.count;
        data[selectedIndex][@"lzldetail"] = details;
        data[selectedIndex][@"lzl"] = [NSString stringWithFormat:@"%d", num];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)doubleTapWeb:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            return ;
        }
        ContentCell *cell = (ContentCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [hud showAndHideWithSuccessMessage:@"双击切换背景"];
        [cell.webViewContainer.webView evaluateJavaScript:@"(()=>{const bodyMask=document.getElementById('body-mask');if(bodyMask.style.backgroundColor){ bodyMask.style.backgroundColor='';}else{bodyMask.style.backgroundColor='rgba(127, 127, 127, 0.75)';}})()" completionHandler:nil];
    }
}

- (IBAction)moreAction:(UIButton *)sender {
    selectedIndex = sender.tag;
    [self showMoreAction:sender];
}

- (void)showMoreAction:(UIView *)view {
    NSDictionary *item = data[selectedIndex];
    NSString *text = item[@"text"];
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"引用" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([ActionPerformer checkLogin:YES]) {
            NSString *content = text;
            content = [self getValidQuote:content];
            defaultContent = [NSString stringWithFormat:@"[quote=%@]%@[/quote]\n", item[@"author"], content];
            [self performSegueWithIdentifier:@"compose" sender:self.buttonCompose];
        }
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *content = text;
        content = [ActionPerformer removeHTML:content];
        [[UIPasteboard generalPasteboard] setString:content];
        [hud showAndHideWithSuccessMessage:@"复制完成"];
    }]];
    if ([ActionPerformer checkRight] > 1 || [item[@"author"] isEqualToString:UID]) {
        [action addAction:[UIAlertAction actionWithTitle:@"编辑" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            defaultTitle = [item[@"floor"] isEqualToString:@"1"]?self.title:[NSString stringWithFormat:@"Re: %@",self.title];
            isEdit = YES;
            NSString *content = text;
            content = [ActionPerformer simpleEscapeHTML:content processLtGt:NO];
            defaultContent = content;
            [self performSegueWithIdentifier:@"compose" sender:nil];
        }]];
        [action addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if ([ActionPerformer checkLogin:YES]) {
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
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.sourceView = view;
    action.popoverPresentationController.sourceRect = view.bounds;
    [self presentViewControllerSafe:action];
}

#pragma mark - HTML processing

- (NSString *)getCollectionText:(NSString *)text {
    if (!text || text.length == 0) {
        return @"";
    }
    NSString *content = [ActionPerformer transToHTML:text];
    content = [ActionPerformer removeHTML:content];
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
    text = [ActionPerformer simpleEscapeHTML:text processLtGt:NO];
    
    NSString *expression = @"<quote>((.|[\r\n])*?)</quote>"; // 去除帖子中的引用
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    int maxLength = 100;
    int maxCountXIndex = 2 * maxLength * maxLength;
    if (text.length <= maxLength) {
        return text;
    }
    
    int index = 0, count = 0;
    NSMutableArray * htmlLabel = [[NSMutableArray alloc] init];
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
                    bool isBlank = NO;
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

- (void)longPressTop:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            return;
        }
        selectedIndex = indexPath.row;
        ContentCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self showMoreAction:cell.labelAuthor];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
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
            dest.showEditOthersAlert = ![data[selectedIndex][@"author"] isEqualToString:UID];
        }
        
        defaultTitle = nil;
        defaultContent = nil;
        selectedIndex = -1;
        isEdit = NO;
    } else if ([segue.identifier isEqualToString:@"lzl"]) {
        LzlViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        UIView *origin;
        if ([sender isKindOfClass:[UIButton class]]) {
            origin = sender;
            selectedIndex = origin.tag;
        } else if (selectedIndex >= 0) {
            ContentCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
            if (cell) {
                origin = cell.buttonLzl;
            }
        }
        if (origin) {
            dest.navigationController.modalPresentationStyle = UIModalPresentationPopover;
            dest.navigationController.popoverPresentationController.sourceView = origin;
            dest.navigationController.popoverPresentationController.sourceRect = origin.bounds;
        }
        dest.fid = data[selectedIndex][@"fid"];
        dest.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@#%@", URL, data[selectedIndex][@"floor"]]];
        if (data[selectedIndex][@"lzldetail"]) {
            dest.defaultData = data[selectedIndex][@"lzldetail"];
        } else {
            dest.defaultData = @[];
        }
    } else if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        if ([sender isKindOfClass:[UIButton class]]) {
            UIButton *button = sender;
            dest.ID = data[button.tag][@"author"];
            dest.navigationController.modalPresentationStyle = UIModalPresentationPopover;
            dest.navigationController.popoverPresentationController.sourceView = button;
            dest.navigationController.popoverPresentationController.sourceRect = button.bounds;
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

