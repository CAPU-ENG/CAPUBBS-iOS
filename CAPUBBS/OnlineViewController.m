//
//  OnlineViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/5/14.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "OnlineViewController.h"
#import "ContentViewController.h"
#import "UserViewController.h"
#import "WebViewController.h"

@interface OnlineViewController ()

@end

@implementation OnlineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(360, 0);
    if (!([ActionPerformer checkRight] > 0)) {
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

- (void)refreshControlValueChanged:(UIRefreshControl*)sender{
    self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"刷新"];
    [self viewOnline];
}

- (void)viewOnline {
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"加载中";
    [hud show:YES];
    [self performSelectorInBackground:@selector(getData:) withObject:@"online"];
}

- (void)loadOnline:(NSString *)HTMLString {
    data = [[NSMutableArray alloc] init];
    NSArray *keys = @[@"user", @"time", @"ip", @"board", @"type"];
    BOOL fail = NO;
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    if (HTMLString && [HTMLString containsString:@"当前在线"]) {
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
                    [dict setObject:tempInfo forKey:[keys objectAtIndex:i]];
                }
                [data addObject:dict];
            }
        }else {
            fail = YES;
        }
        if (fail) {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.labelText = @"加载失败";
            // [[[UIAlertView alloc] initWithTitle:@"加载失败" message:@"当前功能暂不可用！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        }else {
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.labelText = @"加载成功";
            if (data.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"当前没有人在线！" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
            }
            // NSLog(@"%@", data);
            [self.tableView reloadData];
        }
    }else {
        hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
        hud.labelText = @"加载失败";
        // [[[UIAlertView alloc] initWithTitle:@"网络错误" message:@"请检查您的网络连接！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }
    hud.mode = MBProgressHUDModeCustomView;
    [hud hide:YES afterDelay:0.5];
}

- (IBAction)viewSign:(id)sender {
    self.buttonStat.enabled = NO;
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"加载中";
    [hud show:YES];
    [self performSelectorInBackground:@selector(getData:) withObject:@"sign"];
}

- (void)loadSign:(NSString *)HTMLString {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    if (HTMLString && [HTMLString containsString:@"签到统计"]) {
        hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
        hud.labelText = @"加载成功";
        HTMLString = [[ContentViewController removeHTML:HTMLString] substringFromIndex:@"签到统计\n".length];
        HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"\n#" withString:@"\n"];
        [[[UIAlertView alloc] initWithTitle:@"签到统计" message:HTMLString delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }else {
        hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
        hud.labelText = @"加载失败";
        // [[[UIAlertView alloc] initWithTitle:@"网络错误" message:@"请检查您的网络连接！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }
    hud.mode = MBProgressHUDModeCustomView;
    [hud hide:YES afterDelay:0.5];
}

- (void)getData:(NSString *)type{
    NSString * HTMLString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/%@", CHEXIE, type]] encoding:NSUTF8StringEncoding error:nil];
    if ([type isEqualToString:@"online"]) {
        [self performSelectorOnMainThread:@selector(loadOnline:) withObject:HTMLString waitUntilDone:NO];
    }else if ([type isEqualToString:@"sign"]) {
        [self performSelectorOnMainThread:@selector(loadSign:) withObject:HTMLString waitUntilDone:NO];
    }
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
    }else {
        return nil;
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
    if ([dict[@"type"] isEqualToString:@"web版登录"]) {
        cell.labelType.text = @"💻";
    }else if ([dict[@"type"] isEqualToString:@"Android客户端登录"]) {
        cell.labelType.text = @"📱";
    }else if ([dict[@"type"] isEqualToString:@"iOS客户端登录"]) {
        cell.labelType.text = @"📱";
    }else {
        cell.labelType.text = @"❓";
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
        dest.URL = [NSString stringWithFormat:@"%@/bbs/online", CHEXIE];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
