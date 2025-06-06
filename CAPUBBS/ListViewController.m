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
#import "AsyncImageView.h"

@interface ListViewController ()

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    // Auto height
    self.tableView.estimatedRowHeight = 50;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    hudSofa = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hudSofa];
    
    if ([self.bid isEqualToString:@"hot"]) {
        self.navigationItem.rightBarButtonItems = @[self.buttonViewOnline];
    } else {
        self.navigationItem.rightBarButtonItems = @[self.buttonSearch];
        
        if (SIMPLE_VIEW == NO) {
            AsyncImageView *backgroundView = [[AsyncImageView alloc] init];
            [backgroundView setBlurredImage:[UIImage imageNamed:[@"b" stringByAppendingString:self.bid]] animated:NO];
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            self.tableView.backgroundView = backgroundView;
        }
    }
//    numberEmoji = @[@"1⃣️", @"2⃣️", @"3⃣️", @"4⃣️", @"5⃣️", @"6⃣️", @"7⃣️", @"8⃣️", @"9⃣️", @"🔟"];
    isFirstTime = YES;
    page = 1;
    performer = [[ActionPerformer alloc] init];
    performerReply = [[ActionPerformer alloc] init];
    [NOTIFICATION addObserver:self selector:@selector(shouldRefresh) name:@"refreshList" object:nil];
    self.title = ([self.bid isEqualToString:@"hot"] ? @"🔥论坛热点🔥" : [ActionPerformer getBoardTitle:self.bid]);
    oriTitle = self.title;
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self jumpTo:page];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    if (![self.bid isEqualToString:@"hot"]) {
//        if (![[DEFAULTS objectForKey:@"FeatureSwipe2.0"] boolValue]) {
//            [self showAlertWithTitle:@"新功能！" message:@"帖子和列表界面可以左右滑动翻页" cancelTitle:@"我知道了"];
//            [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureSwipe2.0"];
//        }
    } else {
        if (![[DEFAULTS objectForKey:@"FeatureViewOnline3.0"] boolValue]) {
            [self showAlertWithTitle:@"新功能！" message:@"可以查看在线用户和签到统计\n点击右上方墨镜前往" cancelTitle:@"我知道了"];
            [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureViewOnline3.0"];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    isRobbingSofa = NO;
    [hudSofa hideWithFailureMessage:@"页面退出"];
}

- (void)shouldRefresh{
    [self jumpTo:page];
}

- (void)refreshControlValueChanged:(UIRefreshControl*)sender{
    self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"刷新"];
    [self jumpTo:page];
}

- (void)jumpTo:(NSInteger)pageNum {
    [hud showWithProgressMessage:@"读取中"];
    NSInteger oldPage = page;
    page = pageNum;
    self.buttonCompose.enabled = [ActionPerformer checkLogin:NO];
    self.buttonSearch.enabled = (![self.bid isEqualToString:@"1" ] || [ActionPerformer checkLogin:NO]);
    if (![self.bid isEqualToString: @"hot"]) {
        self.buttonBack.enabled = (page != 1);
        NSDictionary *dict = @{
            @"bid" : self.bid,
            @"p" : [NSString stringWithFormat:@"%ld", (long)pageNum]
        };
        [performer performActionWithDictionary:dict toURL:@"show" withBlock:^(NSArray *result, NSError *err) {
            if (self.refreshControl.isRefreshing) {
                [self.refreshControl endRefreshing];
            }

            if (err || result.count == 0) {
                failCount++;
                page = oldPage;
                self.buttonBack.enabled = page != 1;
                [hud hideWithFailureMessage:@"读取失败"];
                NSLog(@"%@",err);
            } else {
                data = [NSMutableArray arrayWithArray:result];
                if ([[[data lastObject] objectForKey:@"pages"] length]==0) {
                    failCount++;
                    isLast = YES;
                    self.title = [NSString stringWithFormat:@"%@(未登录)", oriTitle];
                    self.tableView.userInteractionEnabled = NO;
                    [self showAlertWithTitle:@"警告" message:@"您未登录，不能查看本版！\n请登录或者前往其它版面"];
                    [hud hideWithFailureMessage:@"读取失败"];
                } else {
                    isLast = [[data[0] objectForKey:@"nextpage"] isEqualToString:@"false"];
                    self.title = [NSString stringWithFormat:@"%@(%ld/%@)", oriTitle,(long)page, [[data lastObject] objectForKey:@"pages"]];
                    [hud hideWithSuccessMessage:@"读取成功"];
                }
                
                self.buttonForward.enabled = !isLast;
                self.buttonJump.enabled = ([[[data lastObject] objectForKey:@"pages"] integerValue] > 1);
                if (isFirstTime) {
                    [self.tableView reloadData];
                } else {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                isFirstTime = NO;
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            [self checkRobSofa];
        }];
    } else {
        self.buttonBack.enabled = NO;
        self.buttonForward.enabled = NO;
        self.buttonJump.enabled = NO;
        [performer performActionWithDictionary:nil toURL:@"globaltop" withBlock:^(NSArray *topResult, NSError *topErr) {
            [performer performActionWithDictionary:@{@"hotnum":[NSString stringWithFormat:@"%d", HOT_NUM]} toURL:@"hot" withBlock:^(NSArray *hotResult, NSError *hotErr) {
                if (self.refreshControl.isRefreshing) {
                    page = 1;
                    [self.refreshControl endRefreshing];
                }
                if (topErr || hotErr || hotResult.count == 0) {
                    failCount++;
                    page = oldPage;
                    self.buttonBack.enabled = page != 1;
                    [hud hideWithFailureMessage:@"读取失败"];
                    if (topErr) {
                        NSLog(@"globaltop error: %@",topErr);
                    }
                    if (hotErr) {
                        NSLog(@"hot error: %@",hotErr);
                    }
                    if (hotResult.count == 0) {
                        NSLog(@"hot not found");
                    }
                } else {
                    [hud hideWithSuccessMessage:@"读取成功"];
                    
                    data = [NSMutableArray arrayWithArray:topResult];
                    globalTopCount = data.count;
                    [data addObjectsFromArray:hotResult];
                    [GROUP_DEFAULTS setObject:[NSNumber numberWithLong:globalTopCount] forKey:@"globalTopCount"];
                    [GROUP_DEFAULTS setObject:data forKey:@"hotPosts"];
                    if (isFirstTime) {
                        [self.tableView reloadData];
                    } else {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    isFirstTime = NO;
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                [self checkRobSofa];
            }];
        }];
    }
}

- (void)checkRobSofa {
    if (isRobbingSofa) {
        if (failCount > 10) {
            [self showAlertWithTitle:@"抢沙发失败" message:@"错误次数过多，请检查原因！"];
            isRobbingSofa = NO;
            [hudSofa hideWithFailureMessage:@"错误次数过多"];
            return;
        }
        if (data.count > 0) {
            for (NSDictionary *dict in data) {
                BOOL isNew = NO;
                if ([self.bid isEqualToString:@"hot"]) {
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
                if (isNew == YES) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
                    [formatter setTimeZone:beijingTimeZone];
                    NSDate *currentTime = [NSDate date];
                    NSDate *postTime =[formatter dateFromString:dict[@"time"]];
                    NSTimeInterval time = [currentTime timeIntervalSinceDate:postTime];
                    // NSLog(@"%d", (int)time);
                    if ((int)time <= 60) { // 一分钟之内的帖子(允许服务器时间误差)
                        NSLog(@"New Post Found");
                        [self performSelector:@selector(robSofa:) withObject:dict afterDelay:0];
                        return;
                    }
                }
            }
            float delay = 1 + (float)(arc4random() % 200) / 100; // 随机在1~3秒后刷新
            [self performSelector:@selector(refresh) withObject:nil afterDelay:isFastRobSofa ? delay * 0.1 : delay];
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
    [performerReply performActionWithDictionary:dict toURL:@"post" withBlock:^(NSArray *result, NSError *err) {
        BOOL fail = NO;
        if (err || result.count == 0) {
            fail = YES;
        }
        if (fail == NO && ![[[result firstObject] objectForKey:@"code"] isEqualToString:@"0"]) {
            fail = YES;
        }
        if (fail == NO) {
            [self showAlertWithTitle:@"抢沙发成功" message:[NSString stringWithFormat:@"您成功在帖子“%@”中抢到了沙发", [postInfo objectForKey:@"text"]]];
            isRobbingSofa = NO;
            [hudSofa hideWithSuccessMessage:@"抢沙发成功"];
        } else {
            failCount++;
        }
        [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
    }];
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
    NSString *titleText = dict[@"text"];
    titleText = [ActionPerformer removeRe:titleText];
    if ([dict[@"top"] integerValue] == 1 || [dict[@"extr"] integerValue] == 1 || [dict[@"lock"] integerValue] == 1) {
        titleText = [@" " stringByAppendingString:titleText];
        if ([dict[@"top"] integerValue] == 1) {
            titleText = [@"⬆️" stringByAppendingString:titleText];
        }
        if ([dict[@"extr"] integerValue] == 1) {
            titleText = [@"⭐️" stringByAppendingString:titleText];
        }
        if ([dict[@"lock"] integerValue] == 1) {
            titleText = [@"🔒" stringByAppendingString:titleText];
        }
    }
    if (!titleText) {
        titleText = @"";
    }
    if ([self.bid isEqualToString:@"hot"]) {
        if (indexPath.row < globalTopCount) {
            titleText = [@"⬆️ " stringByAppendingString:titleText];
        }
        
        NSString *author = dict[@"author"];
        NSString *replyer = dict[@"replyer"];
        if ([dict[@"pid"] integerValue] == 0 || [replyer isEqualToString:@"Array"]) {
            cell.authorText.text = author;
        } else {
            cell.authorText.text = [NSString stringWithFormat:@"%@/%@", author, replyer];
        }
//        else if (indexPath.row < globalTopCount + 10) {
//            titleText = [numberEmoji[indexPath.row - globalTopCount] stringByAppendingString:[@" " stringByAppendingString:titleText]];
//        }
    } else {
        NSString *author = [dict[@"author"] stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([author hasSuffix:@"/"]) {
            cell.authorText.text = [author substringToIndex:author.length - 1];
        } else {
            cell.authorText.text = author;
        }
    }
    cell.titleText.text = titleText;
    cell.timeText.text = dict[@"time"];
    
    if (cell.gestureRecognizers.count == 0) {
        [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    }
    // Configure the cell...
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)back:(id)sender {
    [self jumpTo:page-1];
}

- (IBAction)forward:(id)sender {
    [self jumpTo:page+1];
}

- (IBAction)action:(id)sender {
    NSString *URL = [NSString stringWithFormat:@"%@/bbs/main/?p=%d&bid=%@", CHEXIE, (int)page, self.bid];
    if ([self.bid isEqualToString:@"hot"]) {
        URL = [NSString stringWithFormat:@"%@/bbs/index", CHEXIE];
    }
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *shareURL = [[NSURL alloc] initWithString:URL];
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[self.title, shareURL] applicationActivities:nil];
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
    if (IS_SUPER_USER && ![self.bid isEqualToString:@"1"]) {
        [action addAction:[UIAlertAction actionWithTitle:@"抢沙发模式" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"进入抢沙发模式" message:@"版面将持续刷新直至刷出非工作区新帖并且成功回复指定内容为止" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"请指定回复内容，默认为“沙发”";
            }];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"开始"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                sofaContent = alert.textFields.firstObject.text;
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
            [self presentViewControllerSafe:alert];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonAction;
    [self presentViewControllerSafe:action];
}

- (IBAction)jump:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[[data lastObject] objectForKey:@"pages"]] preferredStyle:UIAlertControllerStyleAlert];
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
        NSInteger pagen = [pageip integerValue];
        if (pagen <= 0 || pagen > [[[data lastObject] objectForKey:@"pages"] integerValue]) {
            [self showAlertWithTitle:@"错误" message:@"输入不合法"];
            return;
        }
        [self jumpTo:pagen];
    }]];
    [self presentViewControllerSafe:alert];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.buttonForward.enabled == YES && ![[DEFAULTS objectForKey:@"oppositeSwipe"] boolValue])
            [self jumpTo:page + 1];
        if (self.buttonBack.enabled == YES && [[DEFAULTS objectForKey:@"oppositeSwipe"] boolValue])
            [self jumpTo:page - 1];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.buttonForward.enabled == YES && [[DEFAULTS objectForKey:@"oppositeSwipe"] boolValue])
            [self jumpTo:page + 1];
        if (self.buttonBack.enabled == YES && ![[DEFAULTS objectForKey:@"oppositeSwipe"] boolValue])
            [self jumpTo:page - 1];
    }
}

- (void)longPress:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) return ;
        selectedRow = indexPath.row;
        
        NSDictionary *info = data[selectedRow];
        if ([ActionPerformer checkRight] < 2) {
            return;
        }
        
        UIAlertController *action = [UIAlertController alertControllerWithTitle:@"选择操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        if (![self.bid isEqualToString:@"hot"]) {
            [action addAction:[UIAlertAction actionWithTitle:([[info objectForKey:@"extr"] integerValue] == 1) ? @"取消加精" : @"加精" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"extr"];
            }]];
            [action addAction:[UIAlertAction actionWithTitle:([[info objectForKey:@"top"] integerValue] == 1) ? @"取消置顶" : @"置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"top"];
            }]];
            [action addAction:[UIAlertAction actionWithTitle:@"首页置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"global_top_action"];
            }]];
            [action addAction:[UIAlertAction actionWithTitle:([[info objectForKey:@"lock"] integerValue] == 1) ? @"取消锁定" : @"锁定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"lock"];
            }]];
        } else {
            [action addAction:[UIAlertAction actionWithTitle:indexPath.row < globalTopCount ? @"取消首页置顶" : @"首页置顶" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self operate:@"global_top_action"];
            }]];
        }
        [action addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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
        [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        ListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UIView *view = cell.titleText;
        action.popoverPresentationController.sourceView = view;
        action.popoverPresentationController.sourceRect = view.bounds;
        [self presentViewControllerSafe:action];
    }
}

- (void)operate:(NSString *)method {
    NSDictionary *dict = @{
        @"bid" : data[selectedRow][@"bid"],
        @"tid" : data[selectedRow][@"tid"],
        @"method" : method
    };
    [hud showWithProgressMessage:@"正在操作"];
    [performer performActionWithDictionary:dict toURL:@"action" withBlock:^(NSArray *result, NSError *err) {
        if ([[result.firstObject objectForKey:@"code"]integerValue]==0) {
            [hud hideWithSuccessMessage:@"操作成功"];
            [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
        } else {
            [hud hideWithFailureMessage:@"操作失败"];
            [self showAlertWithTitle:@"错误" message:[result.firstObject objectForKey:@"msg"]];
        }
    }];
}

- (void)deletePost {
    NSDictionary *dict = @{
        @"bid" : data[selectedRow][@"bid"],
        @"tid" : data[selectedRow][@"tid"]
    };
    [hud showWithProgressMessage:@"正在操作"];
    [performer performActionWithDictionary:dict toURL:@"delete" withBlock:^(NSArray *result, NSError *err) {
        if ([[result.firstObject objectForKey:@"code"]integerValue] == 0) {
            [hud hideWithSuccessMessage:@"操作成功"];
            [data removeObjectAtIndex:selectedRow];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedRow inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
        } else {
            [hud hideWithFailureMessage:@"操作失败"];
            [self showAlertWithTitle:@"错误" message:[result.firstObject objectForKey:@"msg"]];
        }
    }];
}

- (void)refresh {
    [self jumpTo:page];
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        dest.bid = self.bid;
    } else if ([segue.identifier isEqualToString:@"search"]) {
        SearchViewController *dest = [segue destinationViewController];
        dest.bid = self.bid;
    } else if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        NSDictionary *one = [data objectAtIndex:indexPath.row];
        dest.tid = [one objectForKey:@"tid"];
        dest.bid = [one objectForKey:@"bid"];
        if ([self.bid isEqualToString: @"hot"] && indexPath.row > globalTopCount) {
            dest.floor = [one objectForKey:@"pid"];
            dest.willScroll = YES;
        }
        dest.title = [one objectForKey:@"text"];
    }

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
