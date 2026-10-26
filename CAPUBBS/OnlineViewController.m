//
//  OnlineViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/5/14.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "OnlineViewController.h"
#import "OnlineViewCell.h"
#import "ContentViewController.h"
#import "UserViewController.h"
#import "WebViewController.h"
#import "HTMLFetcher.h"

@interface OnlineViewController ()

@end

@implementation OnlineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(400, 650);
    
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    if (!([Helper checkRight] > 0)) {
        self.navigationItem.rightBarButtonItems = @[self.buttonStat];
    }
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self viewOnline];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [self viewOnline];
}

- (void)viewOnline {
    [hud showWithProgressMessage:@"加载中"];
    dispatch_global_default_async(^{
        [self getData:@"online"];
    });
}

- (void)loadOnline:(NSString *)HTMLString {
    data = [NSMutableArray array];
    NSArray *keys = @[@"user", @"time", @"ip", @"board", @"type"];
    BOOL fail = NO;
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    if (!HTMLString || ![HTMLString containsString:@"当前在线"]) {
        [hud hideWithFailureMessage:@"加载失败"];
//        [self showAlertWithTitle:@"网络错误" message:@"请检查您的网络连接！"];
        return;
    }
    
    // NSLog(@"%@", HTMLString);
    NSRange range = [HTMLString rangeOfString:@"<table((.|[\r\n])*?)</table>" options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        HTMLString = [HTMLString substringWithRange:range];
        while (YES) {
            range = [HTMLString rangeOfString:@"<tr bgcolor(.*?)</tr>" options:NSRegularExpressionSearch];
            if (range.location == NSNotFound) {
                break;
            }
            NSString *tempCell = [HTMLString substringWithRange:range];
            HTMLString = [HTMLString stringByReplacingCharactersInRange:range withString:@""];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            for (int i = 0; i < keys.count; i++) {
                range = [tempCell rangeOfString:@"<td>(.*?)</td>" options:NSRegularExpressionSearch];
                if (range.location == NSNotFound) {
                    fail = YES;
                    break;
                }
                NSString *tempInfo = [tempCell substringWithRange:range];
                tempCell = [tempCell stringByReplacingCharactersInRange:range withString:@""];
                tempInfo = [tempInfo substringWithRange:NSMakeRange(4, tempInfo.length - 9)];
                if (i == 0) {
                    range = [tempInfo rangeOfString:@">(.*?)<" options:NSRegularExpressionSearch];
                    if (range.location == NSNotFound) {
                        fail = YES;
                        break;
                    }
                    tempInfo = [tempInfo substringWithRange:range];
                    tempInfo = [tempInfo substringWithRange:NSMakeRange(1, tempInfo.length - 2)];
                }
                [dict setObject:tempInfo forKey:keys[i]];
            }
            [data addObject:dict];
        }
    } else {
        fail = YES;
    }
    if (fail) {
        [hud hideWithFailureMessage:@"加载失败"];
//        [self showAlertWithTitle:@"加载失败" message:@"当前功能暂不可用！"];
    } else {
        [hud hideWithSuccessMessage:@"加载成功"];
        
//        NSLog(@"%@", data);
        if ([self.tableView numberOfRowsInSection:0] == 0) {
            [self.tableView reloadData];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (IBAction)viewSign:(id)sender {
    self.buttonStat.enabled = NO;
    [hud showWithProgressMessage:@"加载中"];
    dispatch_global_default_async(^{
        [self getData:@"sign"];
    });
}

- (void)loadSign:(NSString *)HTMLString {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    if (HTMLString && [HTMLString containsString:@"签到统计"]) {
        [hud hideWithSuccessMessage:@"加载成功"];
        HTMLString = [[Helper removeHTML:HTMLString restoreFormat:NO] substringFromIndex:@"签到统计\n".length];
        HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"\n#" withString:@"\n"];
        [self showAlertWithTitle:@"签到统计" message:HTMLString];
    } else {
        [hud hideWithFailureMessage:@"加载失败"];
        // [self showAlertWithTitle:@"网络错误" message:@"请检查您的网络连接！"];
    }
}

- (void)getData:(NSString *)type {
    [HTMLFetcher fetchHTMLWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/%@", CHEXIE, type]]
                       cookieDict:@{@"capubbs_forum_mode": @"legacy"}
                            delay:0
                       completion:^(NSString * _Nullable html, NSError * _Nullable error) {
        if (error) {
            [hud hideWithFailureMessage:@"加载失败"];
            return;
        }
        
        if ([type isEqualToString:@"online"]) {
            [self loadOnline:html];
        } else if ([type isEqualToString:@"sign"]) {
            [self loadSign:html];
        }
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (data.count > 0) {
        return [NSString stringWithFormat:@"当前共%d人在线", (int)data.count];
    } else {
        return data ? @"当前没有人在线" : nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OnlineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"online" forIndexPath:indexPath];
    NSDictionary *dict = data[indexPath.row];
    cell.labelUser.text = dict[@"user"];
    cell.labelTime.text = dict[@"time"];
    cell.labelBoard.text = dict[@"board"];
    if (cell.labelBoard.text.length == 0) {
        cell.labelBoard.text = @"未知";
    }
    NSString *type = dict[@"type"];
    if ([type isEqualToString:@"网页端"]) {
        cell.labelType.text = @"🌐";
    } else if ([type isEqualToString:@"桌面端网页"]) {
        cell.labelType.text = @"💻🌐";
    } else if ([type isEqualToString:@"移动端网页"]) {
        cell.labelType.text = @"📱🌐";
    } else if ([type isEqualToString:@"Android客户端登录"]) {
        cell.labelType.text = @"📱";
    } else if ([type isEqualToString:@"iOS客户端登录"]) {
        cell.labelType.text = @"📱";
    } else {
        cell.labelType.text = type.length > 0 ? type : @"❓";
    }
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        dest.ID = [data[indexPath.row] objectForKey:@"user"];
        dest.navigationItem.leftBarButtonItems = nil;
    }
    if ([segue.identifier isEqualToString:@"web"]) {
        WebViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        bool legacyMode = [[GROUP_DEFAULTS objectForKey:@"webMode"] isEqualToString:@"legacy"];
        dest.URL = [NSString stringWithFormat:legacyMode ? @"%@/bbs/online" : @"%@/bbs/data", CHEXIE];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
