//
//  LoginViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LoginViewController.h"
#import "ContentViewController.h"
#import "WebViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    [self.buttonEnter.layer setCornerRadius:10.0];
    [self.buttonRegister.layer setCornerRadius:10.0];
    [self.buttonLogin.layer setCornerRadius:10.0];
    [self.iconUser setRounded:YES];
    
    performer = [[ActionPerformer alloc] init];
    performerInfo = [[ActionPerformer alloc] init];
    performerUser = [[ActionPerformer alloc] init];
    [NOTIFICATION addObserver:self selector:@selector(userChanged) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(refreshIcon) name:@"infoRefreshed" object:nil];
    userInfoRefreshing = NO;
    control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tableview addSubview:control];
    // Auto height
    self.tableview.estimatedRowHeight = 40;
    self.tableview.rowHeight = UITableViewAutomaticDimension;
    
    [self userChanged];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showEULA];
    if (self.textUid.text.length == 0) {
        [self.textUid becomeFirstResponder];
    } else if (self.textPass.text.length == 0) {
        [self.textPass becomeFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.textUid resignFirstResponder];
    [self.textPass resignFirstResponder];
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    control.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = @"正在刷新";
    [hud showAnimated:YES];
    [self getInformation];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return news.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [news objectAtIndex:indexPath.row];
    NSString *bid = dict[@"bid"];
    NSString *tid = dict[@"tid"];
    NSString *url = dict[@"url"];
    UITableViewCell *cell;
    if (bid.length == 0 || tid.length == 0) {
        if ([url hasPrefix:@"javascript"] || url.length == 0) {
            cell = [self.tableview dequeueReusableCellWithIdentifier:@"noLinkCell"];
            cell.tag = -1;
        } else {
            cell = [self.tableview dequeueReusableCellWithIdentifier:@"webCell"];
        }
    } else {
        cell = [self.tableview dequeueReusableCellWithIdentifier:@"postCell"];
    }
    NSString *text = dict[@"text"];
    if (![text hasPrefix:@"📣 "]) {
        int interval = [[NSDate date] timeIntervalSince1970] - [dict[@"time"] intValue];
        if (interval <= 7 * 24 * 3600) { // 一周内的公告
            text = [@"📣 " stringByAppendingString:text];
        }
    }
    cell.textLabel.text = text;
    cell.textLabel.textColor = BLUE;
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:(0.6 - indexPath.row / (2.0 * news.count))]; // 渐变色效果 alpha ∈ [0.6, 0.1)递减
    
    // Configure the cell...
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [self.tableview cellForRowAtIndexPath:indexPath];
    if (cell.tag == -1) {
        [[[UIAlertView alloc] initWithTitle:@"无法打开" message:@"不是论坛链接！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil , nil] show];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return ([ActionPerformer checkRight] > 0);
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        UIAlertView *confirmDel = [[UIAlertView alloc] initWithTitle:@"警告" message:@"确定要删除该公告吗？\n删除操作不可逆！" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
        confirmDel.tag = indexPath.row;
        [confirmDel show];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (IBAction)addNews:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"添加公告" message:@"请填写公告的标题和链接\n链接可以为空" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"添加", nil];
    alert.alertViewStyle=UIAlertViewStyleLoginAndPasswordInput;
    [alert textFieldAtIndex:0].placeholder = @"标题";
    [alert textFieldAtIndex:1].placeholder = @"链接";
    [alert textFieldAtIndex:1].secureTextEntry = NO;
    [alert textFieldAtIndex:1].keyboardType = UIKeyboardTypeURL;
    [alert show];
}

- (void)userChanged {
    dispatch_main_async_safe(^{
        NSLog(@"Refresh User State");
        NSString *username = UID;
        if (username.length == 0) {
            [self.iconUser setImage:PLACEHOLDER];
            [self.buttonAddNews setHidden:YES];
        } else {
            if (userInfoRefreshing == NO) {
                userInfoRefreshing = YES;
                [performerUser performActionWithDictionary:@{@"uid": UID} toURL:@"userinfo" withBlock:^(NSArray *result, NSError *err) {
                    if (!err && result.count > 0) {
                        [GROUP_DEFAULTS setObject:[NSDictionary dictionaryWithDictionary:result[0]] forKey:@"userInfo"];
                        NSMutableArray *data = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"ID"]];
                        for (int i = 0; i < data.count; i++) {
                            NSMutableDictionary *dict = [data[i] mutableCopy];
                            if ([dict[@"id"] isEqualToString:result[0][@"username"]]) {
                                [dict setObject:result[0][@"icon"] forKey:@"icon"];
                                [data replaceObjectAtIndex:i withObject:dict];
                                [DEFAULTS setObject:data forKey:@"ID"];
                                break;
                            }
                        }
                        dispatch_main_async_safe(^{
                            [NOTIFICATION postNotificationName:@"infoRefreshed" object:nil];
                        });
                    }
                    [self.buttonAddNews setHidden:([ActionPerformer checkRight] < 1)];
                    userInfoRefreshing = NO;
                }];
            }
        }
        [self setLoginView];
    });
}

- (void)refreshIcon {
    dispatch_main_async_safe(^{
        if (![USERINFO isEqual:@""]) {
            [self.iconUser setUrl:[USERINFO objectForKey:@"icon"]];
        } else {
            [self.iconUser setImage:PLACEHOLDER];
        }
    });
}

- (void)setLoginView {
    NSString *username = UID;
    self.textUid.text = UID;
    self.textPass.text = PASS;
    self.buttonLogin.highlighted = NO;
    self.buttonLogin.userInteractionEnabled = YES;
    self.textUid.userInteractionEnabled = YES;
    self.textPass.userInteractionEnabled = YES;
    self.textPass.secureTextEntry = YES;
    if (username.length > 0) {
        if (![ActionPerformer checkLogin:NO] && [[DEFAULTS objectForKey:@"enterLogin"] boolValue] == YES && [[DEFAULTS objectForKey:@"autoLogin"] boolValue] == YES) {
            NSLog(@"Autolog in Login Page");
            [self login:nil];
            [DEFAULTS setObject:[NSNumber numberWithBool:NO] forKey:@"enterLogin"];
        } else {
            [self getInformation];
            if ([ActionPerformer checkLogin:NO]) {
                self.textUid.text = [username stringByAppendingString:@" ✅"];
                NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:@"已登录"];
                [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0 alpha:0.5] range:NSMakeRange(0, attr.length)];
                self.textPass.secureTextEntry = NO;
                self.textPass.attributedText = attr;
                self.buttonLogin.highlighted = YES;
                self.buttonLogin.userInteractionEnabled = NO;
                self.textUid.userInteractionEnabled = NO;
                self.textPass.userInteractionEnabled = NO;
            }
        }
    } else {
        [self getInformation];
    }
}

- (IBAction)login:(id)sender {
    [self.textPass resignFirstResponder];
    [self.textUid resignFirstResponder];
    NSString *uid = self.textUid.text;
    NSString *pass = self.textPass.text;
    if (uid.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        [self.textUid becomeFirstResponder];
        return;
    }
    if (pass.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        [self.textPass becomeFirstResponder];
        return;
    }
    if (!hud) {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = @"正在登录";
    [hud showAnimated:YES];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"username",[ActionPerformer md5:pass],@"password",[ActionPerformer doDevicePlatform],@"device",[[UIDevice currentDevice] systemVersion],@"version", nil];
    [performer performActionWithDictionary:dict toURL:@"login" withBlock:^(NSArray *result, NSError *err) {
        //NSLog(@"%@",result);
        if (err || result.count == 0) {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.label.text = @"登录失败";
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
            [self getInformation];
            // [[[UIAlertView alloc] initWithTitle:@"登录失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return ;
        }
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.label.text = @"登录成功";
        } else {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.label.text = @"登录失败";
        }
        hud.mode = MBProgressHUDModeCustomView;
        [hud hideAnimated:YES afterDelay:0.5];
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"密码错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            [self.textPass becomeFirstResponder];
            [self getInformation];
            return ;
        } else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"2"]) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"用户名不存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            [self.textUid becomeFirstResponder];
            [self getInformation];
            return ;
        } else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
            [GROUP_DEFAULTS setObject:uid forKey:@"uid"];
            [GROUP_DEFAULTS setObject:pass forKey:@"pass"];
            [GROUP_DEFAULTS setObject:[[result objectAtIndex:0] objectForKey:@"token"] forKey:@"token"];
            [LoginViewController updateIDSaves];
            NSLog(@"Login - %@", uid);
            dispatch_main_async_safe(^{
                [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
            });
            [ActionPerformer checkPasswordLength];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"发生未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            [self getInformation];
            return ;
        }
    }];
}

+ (void)updateIDSaves {
    NSMutableArray *data = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"ID"]];
    NSDictionary *nowDict = [NSDictionary dictionaryWithObjectsAndKeys:UID, @"id", PASS, @"pass", nil];
    BOOL findID = NO;
    for (int i = 0; i < data.count; i++) {
        NSDictionary *dict = data[i];
        if ([dict[@"id"] isEqualToString:UID]) {
            findID = YES;
            if (![dict[@"pass"] isEqualToString:PASS]) {
                [data replaceObjectAtIndex:i withObject:nowDict];
            }
        }
    }
    if (findID == NO) {
        [data addObject:nowDict];
    }
    [DEFAULTS setObject:data forKey:@"ID"];
}

- (void)getInformation {
    [performerInfo performActionWithDictionary:@{@"more":@"YES"} toURL:@"main" withBlock:^(NSArray *result, NSError *err) {
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        if (err || result.count == 0) {
            if ([hud.label.text isEqualToString:@"正在刷新"]) {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.mode = MBProgressHUDModeCustomView;
                hud.label.text = @"刷新失败";
                [hud hideAnimated:YES afterDelay:0.5];
            }
            return ;
        }
        if ([hud.label.text isEqualToString:@"正在刷新"]) {
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.mode = MBProgressHUDModeCustomView;
            hud.label.text = @"刷新成功";
            [hud hideAnimated:YES afterDelay:0.5];
        }
        
        news = [result objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, result.count-1)]]; // result的第一项是更新信息 不需要
        // NSLog(@"%@", news);
        [self.tableview reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
        [formatter setTimeZone:beijingTimeZone];
        NSDate *currentDate = [NSDate date];
        NSDate *lastDate =[formatter dateFromString:[DEFAULTS objectForKey:@"checkUpdate"]];
        NSTimeInterval time = [currentDate timeIntervalSinceDate:lastDate];
        if ((int)time > 3600 * 24) { // 每隔1天检测一次更新
            NSLog(@"Check For Update");
            [self performSelectorInBackground:@selector(checkUpdate) withObject:nil];
            [DEFAULTS setObject:[formatter stringFromDate:currentDate] forKey:@"checkUpdate"];
        } else {
            NSLog(@"Needn't Check Update");
        }
    }];
}

- (void)checkUpdate {
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    //CFShow((__bridge CFTypeRef)(infoDic));
    NSString *currentVersion = [infoDic objectForKey:@"CFBundleVersion"];
    //CAPUBBS iTunes Link = https://itunes.apple.com/sg/app/capubbs/id826386033?l=zh&mt=8
    NSString *URL = @"https://itunes.apple.com/lookup?id=826386033";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:URL]];
    [request setHTTPMethod:@"POST"];
    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;
    NSData *recervedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    if (recervedData == nil) {
        [[[UIAlertView alloc] initWithTitle:@"警告" message:@"向App Store检查更新失败，请检查您的网络连接！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        NSLog(@"Check Update Failed Error-%@", error);
        return;
    }
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:recervedData options:kNilOptions error:nil];
    NSArray *infoArray = [dic objectForKey:@"results"];
    if ([infoArray count]) {
        NSDictionary *releaseInfo = [infoArray objectAtIndex:0];
        NSString *lastVersion = [releaseInfo objectForKey:@"version"];
        NSLog(@"Latest Version:%@",lastVersion);
        if ([currentVersion compare:lastVersion options:NSNumericSearch]==NSOrderedAscending) {
            newVerURL = [releaseInfo objectForKey:@"trackViewUrl"];
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"发现新版本%@",lastVersion] message:[NSString stringWithFormat:@"更新内容：\n%@", [releaseInfo objectForKey:@"releaseNotes"]] delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"升级", nil] show];
        }
    }
}

- (IBAction)didEndOnExit:(UITextField*)sender {
    [self.textPass becomeFirstResponder];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self performSegueWithIdentifier:@"main" sender:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title hasPrefix:@"发现新版本"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:newVerURL] options:@{} completionHandler:nil];
    } else if ([alertView.title isEqualToString:@"警告"] || [alertView.title isEqualToString:@"添加公告"]) {
        NSString *method;
        NSString *text = [alertView textFieldAtIndex:0].text;
        NSString *url = [alertView textFieldAtIndex:1].text;
        if ([alertView.title isEqualToString:@"警告"]) {
            method = @"delete";
        } else {
            method = @"add";
            if (text.length == 0) {
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您未填写公告的内容" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
                return;
            }
        }
        
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"正在操作";
        [hud showAnimated:YES];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:method, @"method", [[news objectAtIndex:alertView.tag] objectForKey:@"time"], @"time", text, @"text", url, @"url", nil];
        [performerInfo performActionWithDictionary:dict toURL:@"news" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"操作失败";
            } else {
                if ([[[result firstObject] objectForKey:@"code"] integerValue] == 0) {
                    hud.label.text = @"操作成功";
                    hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                    if ([method isEqualToString:@"delete"]) {
                        NSMutableArray *temp = [NSMutableArray arrayWithArray:news];
                        [temp removeObjectAtIndex:alertView.tag];
                        news = [NSArray arrayWithArray:temp];
                        [self.tableview deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:alertView.tag inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    }
                } else {
                    hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                    hud.label.text = @"操作失败";
                    [[[UIAlertView alloc] initWithTitle:@"操作失败" message:[[result firstObject] objectForKey:@"msg"] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
                }
            }
            [self performSelector:@selector(getInformation) withObject:nil afterDelay:0.5];
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
        }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        NSDictionary *dict = [news objectAtIndex:[self.tableview indexPathForCell:(UITableViewCell *)sender].row];
        dest.bid = dict[@"bid"];
        dest.tid = dict[@"tid"];
        dest.title = dict[@"text"];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    }
    if ([segue.identifier isEqualToString:@"web"]) {
        WebViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        NSDictionary *dict = [news objectAtIndex:[self.tableview indexPathForCell:(UITableViewCell *)sender].row];
        dest.URL = dict[@"url"];
    }
    if ([segue.identifier isEqualToString:@"account"]) {
        UIViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        dest.navigationController.popoverPresentationController.sourceView = self.iconUser;
        dest.navigationController.popoverPresentationController.sourceRect = self.iconUser.bounds;
    }
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showEULA {
    if ([[DEFAULTS objectForKey:@"hasShownEULA"] boolValue]) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"最终用户许可协议"
                                                                   message:EULA
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"查看隐私政策"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        WebViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"webview"];
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:dest];
        dest.URL = [CHEXIE stringByAppendingString:@"/privacy"];
        [navi setToolbarHidden:NO];
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navi animated:YES completion:nil];
        // Show again
        [self showEULA];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"我同意以上协议"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"hasShownEULA"];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"我拒绝以上协议"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
