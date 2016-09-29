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

#define IOS_9_SMALL_SIZE 120
#define IOS_9_LARGE_SIZE 250
#define IOS_10_LARGE_SIZE 250

@interface TodayViewController () <NCWidgetProviding> {
    float iOS;
    float height;
    ActionPerformer *performer;
    NSDictionary *userInfo;
}

@property (strong, nonatomic) IBOutlet AsyncImageView *imageIcon;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicatorLoading;
@property (strong, nonatomic) IBOutlet UIButton *buttonMessages;
@property (strong, nonatomic) IBOutlet UIButton *buttonMore;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintIndicatorWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintMoreButtonWidth;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_imageIcon setRounded:YES];
    iOS = [[[UIDevice currentDevice] systemVersion] floatValue];
    performer = [ActionPerformer new];
    
    if (iOS < 10.0) {
        height = IOS_9_SMALL_SIZE;
        [self setPreferredContentSize:CGSizeMake(0, height)];
    } else {
        _constraintMoreButtonWidth.constant = 0;
        [self.extensionContext setWidgetLargestAvailableDisplayMode:NCWidgetDisplayModeExpanded];
        self.preferredContentSize = [self.extensionContext widgetMaximumSizeForDisplayMode:NCWidgetDisplayModeCompact];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets{
    return UIEdgeInsetsMake(0, 15, 0, 15);
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        [self setPreferredContentSize:maxSize];
    } else {
        [self setPreferredContentSize:CGSizeMake(0, IOS_10_LARGE_SIZE)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    [self refreshView];
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (void)refreshView {
    dispatch_global_default_async(^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            _constraintIndicatorWidth.constant = 20;
            [_indicatorLoading startAnimating];
        });
        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
        [self refreshUserInfoWithBlock:^{
            dispatch_semaphore_signal(signal);
        }];
        [self refreshHotPostWithBlock:^{
            dispatch_semaphore_signal(signal);
        }];
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        dispatch_sync(dispatch_get_main_queue(), ^{
            _constraintIndicatorWidth.constant = 0;
            [_indicatorLoading stopAnimating];
        });
    });
}

- (void)refreshUserInfoWithBlock:(void (^)())block {
    void(^failBlock)() = ^() {
        [_imageIcon setImage:PLACEHOLDER];
        [_labelName setText:@"请在app内登录"];
        [_buttonMessages setTitle:@"点击打开app" forState:UIControlStateNormal];
        userInfo = nil;
    };
    void(^updateInfoBlock)() = ^() {
        [_imageIcon setUrl:userInfo[@"icon"]];
        [_labelName setText:userInfo[@"username"]];
        int newMessageNum = [userInfo[@"newmsg"] intValue];
        if (newMessageNum > 0) {
            [_buttonMessages setTitle:[NSString stringWithFormat:@"您有 %d 条新消息", newMessageNum] forState:UIControlStateNormal];
        } else {
            [_buttonMessages setTitle:@"您暂时没有新消息" forState:UIControlStateNormal];
        }
    };
    
    if (![ActionPerformer checkLogin:NO] || (!userInfo && (!UID || !PASS))) {
        failBlock();
        block();
        return;
    }
    
    [_buttonMessages setHidden:NO];
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

- (void)refreshHotPostWithBlock:(void (^)())block {
    dispatch_global_default_async(^{
        block();
    });
}

- (IBAction)showMessage:(id)sender {
    if (!userInfo || [userInfo[@"newmsg"] intValue] == 0) {
        [[self extensionContext] openURL:[NSURL URLWithString:@"capubbs://"] completionHandler:nil];
    } else {
        [[self extensionContext] openURL:[NSURL URLWithString:@"capubbs://open=message"] completionHandler:nil];
    }
}

- (IBAction)showMore:(id)sender {
    if (height == IOS_9_SMALL_SIZE) {
        height = IOS_9_LARGE_SIZE;
        [_buttonMore setTitle:@"精简" forState:UIControlStateNormal];
    } else {
        height = IOS_9_SMALL_SIZE;
        [_buttonMore setTitle:@"更多" forState:UIControlStateNormal];
    }
    [self setPreferredContentSize:CGSizeMake(0, height)];
}

@end
