//
//  TodayViewController.m
//  CAPUBBS TodayExtension
//
//  Created by 范志康 on 2016/9/29.
//  Copyright © 2016年 熊典. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "CommonDefinitions.h"
#import "ActionPerformer.h"
#import "AsyncImageView.h"
#import "TodayTableViewCell.h"

#define TOP_VIEW_HEIGHT 44
#define DEFAULT_ROW_HEIGHT 33
#define TEXT_INFO_COLOR [UIColor colorWithWhite:1.0 alpha:1.0]
#define TEXT_HINT_COLOR [UIColor colorWithWhite:0.75 alpha:1.0]

@interface TodayViewController () <NCWidgetProviding, UITableViewDelegate, UITableViewDataSource> {
    float iOS;
    float height;
    float rowHeight;
    ActionPerformer *performer;
    NSDictionary *userInfo;
    NSArray *hotPosts;
}

@property (strong, nonatomic) IBOutlet AsyncImageView *imageIcon;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicatorLoading;
@property (strong, nonatomic) IBOutlet UIButton *buttonMessages;
@property (strong, nonatomic) IBOutlet UIButton *buttonMore;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintIndicatorWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintMoreButtonWidth;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_imageIcon setRounded:YES];
    iOS = [[[UIDevice currentDevice] systemVersion] floatValue];
    performer = [ActionPerformer new];
    
    if (iOS < 10.0) {
        height = [[DEFAULTS objectForKey:@"height"] floatValue];
        if (height == 0) {
            height = TOP_VIEW_HEIGHT + 2 * DEFAULT_ROW_HEIGHT;
        }
        [self _refreshShowMoreButtonTitle];
        [self setPreferredContentSize:CGSizeMake(0, height)];
        [_labelName setTextColor:TEXT_INFO_COLOR];
        [_buttonMessages setTitleColor:TEXT_HINT_COLOR forState:UIControlStateNormal];
        [_buttonMore setTintColor:TEXT_HINT_COLOR];
    } else {
        rowHeight = [[DEFAULTS objectForKey:@"rowHeight"] floatValue];
        _constraintMoreButtonWidth.constant = 0;
        [self.extensionContext setWidgetLargestAvailableDisplayMode:NCWidgetDisplayModeExpanded];
        self.preferredContentSize = [self.extensionContext widgetMaximumSizeForDisplayMode:NCWidgetDisplayModeCompact];
    }
    
    // Do any additional setup after loading the view from its nib.
}

// iOS 8-9 起作用
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(0, 15, 0, 15);
}

// iOS 10+ 起作用
- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    CGFloat originalRowHeight = rowHeight;
    if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        rowHeight = (maxSize.height - TOP_VIEW_HEIGHT) / 2;
        [self setPreferredContentSize:CGSizeMake(0, TOP_VIEW_HEIGHT + 2 * rowHeight)];
    } else {
        rowHeight = DEFAULT_ROW_HEIGHT;
        [self setPreferredContentSize:CGSizeMake(0, TOP_VIEW_HEIGHT + 5 * rowHeight)];
    }
    if (rowHeight != originalRowHeight) {
        [DEFAULTS setObject:@(rowHeight) forKey:@"rowHeight"];
        [_tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    [self _refreshView];
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    
    completionHandler(NCUpdateResultNewData);
}

- (void)_refreshView {
    dispatch_global_default_async(^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _constraintIndicatorWidth.constant = 20;
            [_indicatorLoading startAnimating];
        });
        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
        [self _refreshUserInfoWithBlock:^{
            dispatch_semaphore_signal(signal);
        }];
        [self _refreshHotPostWithBlock:^{
            dispatch_semaphore_signal(signal);
        }];
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            _constraintIndicatorWidth.constant = 0;
            [_indicatorLoading stopAnimating];
        });
    });
}

- (void)_refreshUserInfoWithBlock:(void (^)())block {
    void(^failBlock)() = ^() {
        dispatch_main_async_safe(^{
            [_imageIcon setImage:PLACEHOLDER];
            [_labelName setText:@"未登录"];
            [_buttonMessages setTitle:@"点击打开app" forState:UIControlStateNormal];
            userInfo = nil;
        });
    };
    void(^updateInfoBlock)() = ^() {
        int newMessageNum = [userInfo[@"newmsg"] intValue];
        NSString *newMessageTitle = [NSString stringWithFormat:@"您有 %d 条新消息", newMessageNum];
        dispatch_main_async_safe(^{
            [_imageIcon setUrl:userInfo[@"icon"] withPlaceholder:NO];
            [_labelName setText:userInfo[@"username"]];
            if (newMessageNum > 0) {
                [_buttonMessages setTitle:newMessageTitle forState:UIControlStateNormal];
            } else {
                [_buttonMessages setTitle:@"您暂时没有新消息" forState:UIControlStateNormal];
            }
        });
    };
    
    if (![ActionPerformer checkLogin:NO] || (!userInfo && (!UID || !PASS))) {
        failBlock();
        block();
        return;
    }
    
    userInfo = USERINFO;
    if (userInfo) {
        updateInfoBlock();
    }
    [performer performActionWithDictionary:@{@"uid": UID} toURL:@"userinfo" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            if (!userInfo) {
                failBlock();
            }
        } else {
            userInfo = [result firstObject];
            [GROUP_DEFAULTS setObject:userInfo forKey:@"userinfo"];
            updateInfoBlock();
        }
        block();
    }];
}

- (void)_refreshHotPostWithBlock:(void (^)())block {
    hotPosts = HOTPOSTS;
    if (hotPosts.count > 0) {
        dispatch_main_async_safe(^{
            [_tableView reloadData];
        });
    }
    [performer performActionWithDictionary:@{@"hotnum": @"5"} toURL:@"hot" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            if (!hotPosts) {
                TodayTableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
                dispatch_main_async_safe(^{
                    [cell.labelAuthor setText:@"网络异常"];
                });
            }
        } else {
            hotPosts = [NSMutableArray arrayWithArray:result];
            [GROUP_DEFAULTS setObject:hotPosts forKey:@"hotPosts"];
            dispatch_main_async_safe(^{
                [self.tableView reloadData];
            });
        }
        block();
    }];
}

- (IBAction)showMessage:(id)sender {
    if (!userInfo || [userInfo[@"newmsg"] intValue] == 0) {
        [[self extensionContext] openURL:[NSURL URLWithString:@"capubbs://"] completionHandler:nil];
    } else {
        [[self extensionContext] openURL:[NSURL URLWithString:@"capubbs://open=message"] completionHandler:nil];
    }
}

- (IBAction)showMore:(id)sender {
    assert(iOS < 10);
    height = (height == TOP_VIEW_HEIGHT + 2 * DEFAULT_ROW_HEIGHT ? TOP_VIEW_HEIGHT + 5 * DEFAULT_ROW_HEIGHT: TOP_VIEW_HEIGHT + 2 * DEFAULT_ROW_HEIGHT);
    [DEFAULTS setObject:@(height) forKey:@"height"];
    [self _refreshShowMoreButtonTitle];
    [self setPreferredContentSize:CGSizeMake(0, height)];
}

- (void)_refreshShowMoreButtonTitle {
    [_buttonMore setImage:[UIImage imageNamed:(height == TOP_VIEW_HEIGHT + 2 * DEFAULT_ROW_HEIGHT ? @"down": @"up")] forState:UIControlStateNormal];
}

#pragma mark Table View delegate & Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (iOS < 10) {
        return DEFAULT_ROW_HEIGHT;
    } else {
        return rowHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TodayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hot"];
    if (iOS < 10.0) {
        [cell.labelTitle setTextColor:TEXT_INFO_COLOR];
        [cell.labelAuthor setTextColor:TEXT_HINT_COLOR];
    }
    if (!hotPosts || ! hotPosts[indexPath.row]) {
        [cell.labelTitle setText:(indexPath.row == 0 ? @"加载中..." : @"")];
        [cell.labelAuthor setText:@""];
        [cell setUserInteractionEnabled:NO];
    } else {
        NSDictionary *dict = hotPosts[indexPath.row];
        
        NSString *title = [NSString stringWithFormat:@"%ld. %@", indexPath.row + 1, [ActionPerformer removeRe:dict[@"text"]]];
        [cell.labelTitle setText:title];
        
        NSString *detailText;
        if ([dict[@"pid"] integerValue] == 0 || [dict[@"replyer"] isEqualToString:@"Array"]) {
            detailText = dict[@"author"];
        }else {
            detailText = dict[@"replyer"];
        }
        [cell.labelAuthor setText:detailText];
        [cell setUserInteractionEnabled:YES];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = hotPosts[indexPath.row];
    NSString *urlString = [NSString stringWithFormat:@"capubbs://open=post&bid=%@&tid=%@&page=%d", dict[@"bid"], dict[@"tid"], [dict[@"pid"] intValue] / 12];
    [[self extensionContext] openURL:[NSURL URLWithString:urlString] completionHandler:nil];
}

@end
