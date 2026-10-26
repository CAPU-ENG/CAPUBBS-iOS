//
//  ListViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ListViewController.h"
#import "ListCell.h"
#import "ContentViewController.h"
#import "ComposeViewController.h"
#import "SearchViewController.h"
#import "WebViewController.h"
#import "AnimatedImageView.h"

//#define NUMBER_EMOJI @[@"1⃣️", @"2⃣️", @"3⃣️", @"4⃣️", @"5⃣️", @"6⃣️", @"7⃣️", @"8⃣️", @"9⃣️", @"🔟"]

@interface ListViewController ()

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    hudSofa = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hudSofa];
    
    if ([self isHotList]) {
        if (LIQUID_GLASS) {
            self.toolbarItems = @[self.buttonAction, self.buttonCompose];
        }
        // Load from cache
//        NSArray *dataCache = [GROUP_DEFAULTS objectForKey:@"hotPosts"];
//        if (dataCache && dataCache.count > 0) {
//            data = dataCache;
//            globalTopCount = [[GROUP_DEFAULTS objectForKey:@"globalTopCount"] integerValue];
//        }
    } else {
        if (!SIMPLE_VIEW) {
            AnimatedImageView *backgroundView = [[AnimatedImageView alloc] init];
            [backgroundView setImage:[UIImage imageNamed:[@"b" stringByAppendingString:self.bid]] blurred:YES animated:NO];
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            self.tableView.backgroundView = backgroundView;
        }
    }
    [self.tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    [NOTIFICATION addObserver:self selector:@selector(doRefresh) name:@"refreshList" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(reloadTableView) name:@"collectionChanged" object:nil];
    
    self.title = ([self isHotList] ? @"论坛热点" : [Helper getBoardTitle:self.bid]);
    oriTitle = self.title;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (self.page <= 0) {
        self.page = 1;
    }
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:beijingTimeZone];
    
    [self jumpTo:self.page];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".list"]];
    activity.webpageURL = [self getCurrentUrl];
    [activity becomeCurrent];
    
    if (![self isHotList]) {
//        if (![[DEFAULTS objectForKey:@"FeatureSwipe2.0"] boolValue]) {
//            [self showAlertWithTitle:@"新功能！" message:@"帖子和列表界面可以左右滑动翻页" cancelTitle:@"我知道了"];
//            [DEFAULTS setObject:@(YES) forKey:@"FeatureSwipe2.0"];
//        }
    } else {
        if (![[DEFAULTS objectForKey:@"FeatureViewOnline3.0"] boolValue]) {
            [self showAlertWithTitle:@"Tips" message:@"可以查看在线用户和签到统计\n点击右上方墨镜前往" cancelTitle:@"我知道了"];
            [DEFAULTS setObject:@(YES) forKey:@"FeatureViewOnline3.0"];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    isRobbingSofa = NO;
    [hudSofa hideWithFailureMessage:@"页面退出"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)reloadTableView {
    dispatch_main_sync_safe(^{
        [self.tableView reloadData];
    });
}

- (BOOL)isHotList {
    return [self.bid isEqualToString:@"hot"];
}

- (NSURL *)getCurrentUrl {
    NSString *url;
    if ([self isHotList]) {
        url = [NSString stringWithFormat:@"%@/bbs/index", CHEXIE];
    } else {
        url = [NSString stringWithFormat:@"%@/bbs/main/?bid=%@&p=%ld", CHEXIE, self.bid, self.page];
    }
    return [NSURL URLWithString:url];
}

- (void)doRefresh {
    [self jumpTo:self.page];
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [self jumpTo:self.page];
}

- (void)jumpTo:(NSInteger)pageNum {
    [hud showWithProgressMessage:@"加载中"];
    NSInteger oldPage = self.page;
    self.page = pageNum;
    self.buttonAction.enabled = NO;
    self.buttonCompose.enabled = [Helper checkLogin:NO];
    self.buttonBack.enabled = NO;
    self.buttonJump.enabled = NO;
    self.buttonForward.enabled = NO;
    if (![self isHotList]) {
        NSDictionary *dict = @{
            @"bid" : self.bid,
            @"p" : [NSString stringWithFormat:@"%ld", (long)pageNum],
            @"raw": @"YES"
        };
        [Helper callApiWithParams:dict toURL:@"show" callback:^(NSArray *result, NSError *err) {
            if (self.refreshControl.isRefreshing) {
                [self.refreshControl endRefreshing];
            }

            self.buttonAction.enabled = YES;
            self.buttonBack.enabled = self.page != 1;
            if (err || result.count == 0) {
                failCount++;
                self.page = oldPage;
                [hud hideWithFailureMessage:@"加载失败"];
                NSLog(@"%@",err);
            } else {
                NSString *pages = [result lastObject][@"pages"];
                if (pages.length == 0) {
                    failCount++;
                    isLast = YES;
                    if (![Helper checkLogin:NO]) {
                        self.title = [NSString stringWithFormat:@"%@（未登录）", oriTitle];
                        [self showAlertWithTitle:@"错误" message:@"您未登录，不能查看本版！\n请登录或者前往其它版面"];
                    }
                    self.tableView.userInteractionEnabled = NO;
                    [hud hideWithFailureMessage:@"加载失败"];
                } else {
                    data = result;
                    isLast = [data[0][@"nextpage"] isEqualToString:@"false"];
                    self.title = [NSString stringWithFormat:@"%@(%ld/%@)", oriTitle, self.page, [data lastObject][@"pages"]];
                    self.tableView.userInteractionEnabled = YES;
                    [hud hideWithSuccessMessage:@"加载成功"];
                }
                
                activity.webpageURL = [self getCurrentUrl];
                self.buttonForward.enabled = !isLast;
                self.buttonJump.enabled = ([pages integerValue] > 1);
                if ([self.tableView numberOfRowsInSection:0] == 0) {
                    [self.tableView reloadData];
                } else {
                    UITableViewRowAnimation rowAnimation = UITableViewRowAnimationFade;
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
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
            }
            [self checkRobSofa];
        }];
    } else {
        [Helper fetchHotPostsWithCallback:^(NSArray *result, NSInteger topCount, NSError *err) {
            if (self.refreshControl.isRefreshing) {
                self.page = 1;
                [self.refreshControl endRefreshing];
            }
            self.buttonAction.enabled = YES;
            if (err || result.count == 0) {
                failCount++;
                [hud hideWithFailureMessage:@"加载失败"];
                if (err) {
                    NSLog(@"hot posts error: %@", err);
                } else if (result.count == 0) {
                    NSLog(@"hot posts not found");
                }
            } else {
                [hud hideWithSuccessMessage:@"加载成功"];
                data = result;
                globalTopCount = topCount;
                [WidgetManager reloadWidgets];
                
                if ([self.tableView numberOfRowsInSection:0] == 0) {
                    [self.tableView reloadData];
                } else {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                }
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            [self checkRobSofa];
        }];
    }
}

- (void)checkRobSofa {
    if (isRobbingSofa) {
        if (failCount > 10) {
            [self showAlertWithTitle:@"抢沙发失败" message:@"错误次数过多，请检查您的网络连接！"];
            isRobbingSofa = NO;
            [hudSofa hideWithFailureMessage:@"错误次数过多"];
            return;
        }
        if (data.count > 0) {
            for (NSDictionary *dict in data) {
                BOOL isNew = NO;
                if ([self isHotList]) {
                    if (![dict[@"bid"] isEqualToString:@"1"] && ([dict[@"replyer"] length] == 0 || [dict[@"replyer"] isEqualToString:@"Array"])) {  // 不允许抢工作区沙发
                        isNew = YES;
                    }
                } else {
                    NSString *author = dict[@"author"];
                    author = [author stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if ([author hasSuffix:@"/"]) {
                        isNew = YES;
                    }
                }
                if (isNew) {
                    NSDate *currentTime = [NSDate date];
                    NSDate *postTime = [formatter dateFromString:dict[@"time"]];
                    NSTimeInterval time = [currentTime timeIntervalSinceDate:postTime];
                    // NSLog(@"%d", (int)time);
                    if ((int)time <= 60) { // 一分钟之内的帖子(允许服务器时间误差)
                        NSLog(@"New Post Found");
                        dispatch_global_default_async(^{
                            [self robSofa:dict];
                        });
                        return;
                    }
                }
            }
            float delay = 1 + (float)(arc4random() % 200) / 100; // 随机在1~3秒后刷新
            dispatch_main_after(isFastRobSofa ? delay * 0.1 : delay, ^{
                [self refresh];
            });
        }
        [UIApplication sharedApplication].idleTimerDisabled = YES; // 关闭自动锁屏
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO; // 恢复自动锁屏
    }
}

- (void)robSofa:(NSDictionary *)postInfo {
    NSDictionary *dict = @{
        @"bid" : postInfo[@"bid"],
        @"tid" : postInfo[@"tid"],
        @"title" : [NSString stringWithFormat:@"Re: %@", postInfo[@"text"]],
        @"text" : sofaContent,
        @"sig" : @"0"
    };
    [Helper callApiWithParams:dict toURL:@"post" callback:^(NSArray *result, NSError *err) {
        BOOL fail = NO;
        if (err || result.count == 0) {
            fail = YES;
        }
        if (!fail && ![result[0][@"code"] isEqualToString:@"0"]) {
            fail = YES;
        }
        if (fail) {
            failCount++;
        } else {
            [self showAlertWithTitle:@"抢沙发成功" message:[NSString stringWithFormat:@"您成功在帖子“%@”中抢到了沙发", [postInfo objectForKey:@"text"]]];
            isRobbingSofa = NO;
            [hudSofa hideWithSuccessMessage:@"抢沙发成功"];
        }
        dispatch_main_after(0.5, ^{
            [self refresh];
        });
    }];
}

- (BOOL)isCollection:(NSString *)bid tid:(NSString *)tid {
    for (NSDictionary *dic in [DEFAULTS objectForKey:@"collection"]) {
        if ([dic[@"bid"] isEqualToString:bid] && [dic[@"tid"] isEqualToString:tid]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"list"];
    
    NSDictionary *dict = data[indexPath.row];
    NSString *titleText = [Helper restoreTitle:dict[@"text"]] ?: @"";
    BOOL isTop = NO;
    BOOL isCollection = [self isCollection:dict[@"bid"] tid:dict[@"tid"]];
    NSMutableArray *titlePrefixes = [NSMutableArray array];
    if (isCollection) {
        if (LIQUID_GLASS) {
            [titlePrefixes addObject:@"💚"];
        } else {
            [titlePrefixes addObject:@"💙"];
        }
    }
    if ([self isHotList]) {
        if (indexPath.row < globalTopCount) {
            isTop = YES;
            [titlePrefixes addObject:@"⬆️"];
        }
//        else if (indexPath.row < globalTopCount + 10) {
//            [titlePrefixes addObject:NUMBER_EMOJI[indexPath.row - globalTopCount]];
//        }
        
        NSString *author = dict[@"author"];
        NSString *replyer = dict[@"replyer"];
        // pid is reply num
        if ([dict[@"pid"] integerValue] == 0 || [replyer isEqualToString:@"Array"]) {
            cell.authorText.text = author;
        } else {
            cell.authorText.text = [NSString stringWithFormat:@"%@ / %@", author, replyer];
        }
        NSString *time = [dict[@"time"] substringWithRange:NSMakeRange(5, 11)];
        if (SIMPLE_VIEW) {
            cell.timeText.text = time;
        } else {
            cell.timeText.text = [NSString stringWithFormat:@"%@ • %@", [Helper getBoardTitle:dict[@"bid"]], time];
        }
    } else {
        if ([dict[@"top"] integerValue] == 1 || [dict[@"extr"] integerValue] == 1 || [dict[@"lock"] integerValue] == 1 || isCollection) {
            if ([dict[@"top"] integerValue] == 1) {
                isTop = YES;
                [titlePrefixes addObject:@"⬆️"];
            }
            if ([dict[@"lock"] integerValue] == 1) {
                [titlePrefixes addObject:@"🔒"];
            }
            if ([dict[@"extr"] integerValue] == 1) {
                [titlePrefixes addObject:@"⭐️"];
            }
        }
        
        NSString *author = dict[@"author"];
        NSString *replyer = dict[@"replyer"];
        if (SIMPLE_VIEW) {
            if (replyer.length > 0) {
                cell.authorText.text = [NSString stringWithFormat:@"%@ / %@", author, replyer];
            } else {
                cell.authorText.text = author;
            }
            cell.timeText.text = dict[@"time"];
        } else {
            cell.authorText.numberOfLines = 2;
            cell.timeText.numberOfLines = 2;
            cell.timeText.text = [NSString stringWithFormat:@"%@ • %@\n查看：%@ 回复：%@", author, dict[@"postdate"], dict[@"click"], dict[@"reply"]];
            if (replyer) {
                cell.authorText.text = [NSString stringWithFormat:@"%@\n%@", replyer, [dict[@"time"] substringToIndex:16]];
            } else {
                cell.authorText.text = @"";
            }
        }
    }
    if (titlePrefixes.count > 0) {
        cell.titleText.text = [NSString stringWithFormat:@"%@ %@", [titlePrefixes componentsJoinedByString:@""], titleText];
    } else {
        cell.titleText.text = titleText;
    }
    if (!SIMPLE_VIEW) {
        cell.backgroundColor = isTop ? [UIColor colorWithWhite:1.0 alpha:0.5] : [UIColor clearColor];
        cell.titleText.font = isTop ? [UIFont systemFontOfSize:cell.titleText.font.pointSize weight:UIFontWeightMedium] : [UIFont systemFontOfSize:cell.titleText.font.pointSize weight:UIFontWeightRegular];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)back:(id)sender {
    [self jumpTo:self.page - 1];
}

- (IBAction)forward:(id)sender {
    [self jumpTo:self.page + 1];
}

- (IBAction)action:(id)sender {
    NSString *URL = [NSString stringWithFormat:@"%@/bbs/main/?p=%ld&bid=%@", CHEXIE, self.page, self.bid];
    if ([self isHotList]) {
        URL = [NSString stringWithFormat:@"%@/bbs/index", CHEXIE];
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *shareURL = [[NSURL alloc] initWithString:URL];
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[self.title, shareURL] applicationActivities:nil];
        activityViewController.popoverPresentationController.barButtonItem = self.buttonAction;
        [self presentViewControllerSafe:activityViewController];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"打开网页版" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [AppDelegate openURL:URL fullScreen:YES];
    }]];
    if (IS_SUPER_USER && ![self.bid isEqualToString:@"1"] && [Helper checkLogin:NO]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"抢沙发模式" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UIAlertController *alertControllerSofa = [UIAlertController alertControllerWithTitle:@"进入抢沙发模式" message:@"版面将持续刷新直至刷出非工作区新帖并且成功回复指定内容为止" preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(alertControllerSofa) weakAlertController = alertControllerSofa; // 避免循环引用
            [alertControllerSofa addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"请指定回复内容，默认为“沙发”";
            }];
            [alertControllerSofa addAction:[UIAlertAction actionWithTitle:@"取消"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [alertControllerSofa addAction:[UIAlertAction actionWithTitle:@"开始"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                __strong typeof(weakAlertController) strongAlertController = weakAlertController;
                if (!strongAlertController) {
                    return;
                }
                sofaContent = strongAlertController.textFields[0].text;
                if ([sofaContent hasPrefix:@"fast"]) {
                    isFastRobSofa = YES;
                    sofaContent = [sofaContent substringFromIndex:@"fast".length];
                } else {
                    isFastRobSofa = NO;
                }
                if (sofaContent.length == 0) {
                    sofaContent = @"沙发";
                }
                isRobbingSofa = YES;
                failCount = 0;
                [hudSofa showWithProgressMessage:@"抢沙发中"];
                [self showAlertWithTitle:@"已开始抢沙发" message:@"屏幕将常亮，请勿退出软件或者锁屏\n晃动设备可以随时终止抢沙发模式"];
                [self refresh];
            }]];
            [self presentViewControllerSafe:alertControllerSofa];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    alertController.popoverPresentationController.barButtonItem = self.buttonAction;
    [self presentViewControllerSafe:alertController];
}

- (IBAction)jump:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[data lastObject][@"pages"]] preferredStyle:UIAlertControllerStyleAlert];
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
        NSInteger pagen = [pageip integerValue];
        if (pagen <= 0 || pagen > [[data lastObject][@"pages"] integerValue]) {
            [self showAlertWithTitle:@"错误" message:@"输入不合法"];
            return;
        }
        [self jumpTo:pagen];
    }]];
    [self presentViewControllerSafe:alertController];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled && swipeDirection == 0)
            [self jumpTo:self.page + 1];
        if (self.page > 1 && swipeDirection == 1)
            [self jumpTo:self.page - 1];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.buttonForward.enabled && swipeDirection == 1)
            [self jumpTo:self.page + 1];
        if (self.page > 1 && swipeDirection == 0)
            [self jumpTo:self.page - 1];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            return;
        }
        if ([Helper checkRight] < 2) {
            return;
        }
        
        selectedRow = indexPath.row;
        NSDictionary *info = data[selectedRow];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        if (![self isHotList]) {
            [alertController addAction:[UIAlertAction actionWithTitle:([info[@"extr"] integerValue] == 1) ? @"取消加精" : @"加精" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"extr"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:([info[@"top"] integerValue] == 1) ? @"取消置顶" : @"置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"top"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"首页置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"global_top_action"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:([info[@"lock"] integerValue] == 1) ? @"取消锁定" : @"锁定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"lock"];
            }]];
        } else {
            [alertController addAction:[UIAlertAction actionWithTitle:indexPath.row < globalTopCount ? @"取消首页置顶" : @"首页置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"global_top_action"];
            }]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSString *author = [info[@"author"] stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSRange range = [author rangeOfString:@"/"];
            if (range.location != NSNotFound) {
                author = [author substringToIndex:range.location];
            }
            NSString *title = info[@"text"];
            [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确定要删除该帖子吗？\n删除操作不可逆！\n\n作者：%@\n标题：%@", author, title] confirmTitle:@"删除" confirmAction:^(UIAlertAction *action) {
                [self deletePost];
            }];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        ListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UIView *view = cell.titleText;
        alertController.popoverPresentationController.sourceView = view;
        alertController.popoverPresentationController.sourceRect = view.bounds;
        [self presentViewControllerSafe:alertController];
    }
}

- (void)operate:(NSString *)method {
    NSDictionary *dict = @{
        @"bid" : data[selectedRow][@"bid"],
        @"tid" : data[selectedRow][@"tid"],
        @"method" : method
    };
    [hud showWithProgressMessage:@"正在操作"];
    [Helper callApiWithParams:dict toURL:@"action" callback:^(NSArray *result, NSError *err) {
        if (result.count > 0 && [result[0][@"code"] integerValue] == 0) {
            [hud hideWithSuccessMessage:@"操作成功"];
            dispatch_main_after(0.5, ^{
                [self refresh];
            });
        } else {
            [hud hideWithFailureMessage:@"操作失败"];
            [self showAlertWithTitle:@"错误" message:result.count > 0 ? result[0][@"msg"] : @"未知错误"];
        }
    }];
}

- (void)deletePost {
    NSDictionary *dict = @{
        @"bid" : data[selectedRow][@"bid"],
        @"tid" : data[selectedRow][@"tid"]
    };
    [hud showWithProgressMessage:@"正在操作"];
    [Helper callApiWithParams:dict toURL:@"delete" callback:^(NSArray *result, NSError *err) {
        if (result.count > 0 && [result[0][@"code"] integerValue] == 0) {
            [hud hideWithSuccessMessage:@"操作成功"];
            NSMutableArray *tmpData = [NSMutableArray arrayWithArray:data];
            [tmpData removeObjectAtIndex:selectedRow];
            data = [tmpData copy];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedRow inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            dispatch_main_after(0.5, ^{
                [self refresh];
            });
        } else {
            [hud hideWithFailureMessage:@"操作失败"];
            [self showAlertWithTitle:@"错误" message:result.count > 0 ? result[0][@"msg"] : @"未知错误"];
        }
    }];
}

- (void)refresh {
    [self jumpTo:self.page];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) { // 如果是摇手机类型的事件
        NSLog(@"Shake Phone");
        isRobbingSofa = NO;
        [hudSofa hideWithFailureMessage:@"进程终止"];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
        dest.bid = self.bid;
    }
    if ([segue.identifier isEqualToString:@"search"]) {
        SearchViewController *dest = [segue destinationViewController];
        dest.bid = [self isHotList] ? @"-1" : self.bid;
    }
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        NSDictionary *dict = data[indexPath.row];
        dest.tid = dict[@"tid"];
        dest.bid = dict[@"bid"];
        if ([self isHotList] && indexPath.row >= globalTopCount) {
            // pid is reply num, floor # is reply num + 1
            dest.destinationFloor = [NSString stringWithFormat:@"%ld", [dict[@"pid"] integerValue] + 1];
        }
        dest.title = [Helper restoreTitle:dict[@"text"]];
        dest.isCollection = [self isCollection:dict[@"bid"] tid:dict[@"tid"]];
    }
    if ([segue.identifier isEqualToString:@"viewOnline"]) {
        UIViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:sender halfScreen:NO];
    }

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
