//
//  ChatViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "ChatViewController.h"
#import "UserViewController.h"

@interface ChatViewController ()

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    if (self.iconData.length > 0) {
        [self refreshBackgroundViewAnimated:NO];
    }
    
    if (self.shouldHideInfo == YES) {
        self.navigationItem.rightBarButtonItems = nil;
    } else if (self.directTalk == YES) {
        self.navigationItem.rightBarButtonItems = @[self.buttonInfo];
    }
    performer = [[ActionPerformer alloc] init];
    performerUser = [[ActionPerformer alloc] init];
    performerSend = [[ActionPerformer alloc] init];
    shouldShowHud = YES;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    if (self.ID.length == 0) {
        self.directTalk = YES;
        self.title = @"私信";
        [self askForUserId];
    } else {
        self.title = self.ID;
        [self loadChat];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)askForUserId {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发送私信"
                                                                   message:@"请输入对方的用户名"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"用户名";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *userName = alert.textFields.firstObject.text;
        if (userName.length == 0) {
            [self showAlertWithTitle:@"错误" message:@"用户名不能为空" confirmTitle:@"重试" confirmAction:^(UIAlertAction *action) {
                [self askForUserId];
            } cancelTitle:@"取消" cancelAction:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            self.ID = userName;
            self.title = userName;
            [self loadChat];
        }
    }]];
    [self presentViewControllerSafe:alert];
}

- (void)refresh:(NSNotification *)noti {
    dispatch_main_async_safe(^{
        if (self.iconData.length == 0) {
            self.iconData = noti.userInfo[@"data"];
            [self refreshBackgroundViewAnimated:YES];
        }
    });
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.textSend) {
        return;
    }
    if (scrollView.dragging) {
        [self.view endEditing:YES];
    }
}

- (void)refreshControlValueChanged:(UIRefreshControl *)sender {
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    shouldShowHud = YES;
    [self loadChat];
}

- (void)loadChat {
    if (shouldShowHud) {
        [hud showWithProgressMessage:@"正在加载"];
    }
    NSDictionary *dict = @{
        @"type" : @"chat",
        @"chatter" : self.ID
    };
    [performer performActionWithDictionary:dict toURL:@"msg" withBlock: ^(NSArray *result, NSError *err) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        if (err || result.count == 0) {
            if (shouldShowHud) {
                [hud hideWithFailureMessage:@"加载失败"];
            }
            return ;
        }
        
        if ([[data[0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [self showAlertWithTitle:@"错误" message:@"尚未登录或登录超时"];
        }
        
        data = result;
        if (data.count == 1) {
            [self checkID:shouldShowHud];
        } else if (shouldShowHud) {
            [hud hideWithSuccessMessage:@"加载成功"];
        }
        
        // NSLog(@"%@", data);
        if (self.iconData.length == 0 && data.count > 1) {
            [self checkID:NO];
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self performSelector:@selector(scrollTableView) withObject:nil afterDelay:0.5];
        shouldShowHud = NO;
    }];
}

- (void)checkID:(BOOL)hudVisible {
    [performerUser performActionWithDictionary:@{@"uid":self.ID, @"recent":@"YES"} toURL:@"userinfo" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            return;
        }
        // NSLog(@"%@", result);
        if ([result[0][@"username"] length] == 0) {
            [self showAlertWithTitle:@"错误" message:@"没有这个ID！" confirmTitle:@"重试" confirmAction:^(UIAlertAction *action) {
                [self askForUserId];
            } cancelTitle:@"取消" cancelAction:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            
            if (hudVisible) {
                [hud hideWithFailureMessage:@"加载失败"];
            }
        } else {
            NSString *iconUrl = result[0][@"icon"];
            [NOTIFICATION addObserver:self selector:@selector(refresh:) name:[@"imageSet" stringByAppendingString:[AsyncImageView transIconURL:iconUrl]] object:nil];
            AsyncImageView *icon = [[AsyncImageView alloc] init];
            [icon setUrl:iconUrl];
            if (hudVisible) {
                [hud hideWithSuccessMessage:@"加载成功"];
            }
        }
    }];
}

- (void)scrollTableView {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    if (self.directTalk == YES) {
        [self.textSend performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
    }
    self.directTalk = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return data.count - 1;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (data.count > 1) {
            return [NSString stringWithFormat:@"私信记录 共%d条", (int)data.count - 1];
        } else {
            return @"私信记录 暂无";
        }
    } else {
        return @"发送私信";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatCell *cell;
    // Configure the cell...
    if (indexPath.section == 0) {
        NSDictionary *dict = data[indexPath.row + 1];
        if ([dict[@"type"] isEqualToString:@"get"]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"chatOther" forIndexPath:indexPath];
            [cell.imageChat setImage:[[UIImage imageNamed:@"balloon_green"] stretchableImageWithLeftCapWidth:15 topCapHeight:15]];
            [cell.imageIcon setUrl:dict[@"icon"]];
            cell.buttonIcon.userInteractionEnabled = (self.shouldHideInfo == NO);
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"chatSelf" forIndexPath:indexPath];
            [cell.imageChat setImage:[[UIImage imageNamed:@"balloon_white_reverse"] stretchableImageWithLeftCapWidth:15 topCapHeight:15]];
            [cell.imageIcon setUrl:[USERINFO objectForKey:@"icon"]];
        }
        
        cell.labelTime.text = [NSString stringWithFormat:@"  %@  ", dict[@"time"]];
        cell.textMessage.text = dict[@"text"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"chatSend" forIndexPath:indexPath];
        self.textSend = cell.textSend;
    }
    
    return cell;
}

- (IBAction)buttonBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startCompose:(id)sender {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self.textSend performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
}

- (IBAction)buttonSend:(id)sender {
    ChatCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    NSString *text = cell.textSend.text;
    if (text.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"您未填写私信内容！" cancelAction:^(UIAlertAction *action) {
            [cell.textSend becomeFirstResponder];
        }];
        return;
    }
    [hud showWithProgressMessage:@"正在发送"];
    
    NSDictionary *dict = @{
        @"to" : self.ID,
        @"text" : text
    };
    [performerSend performActionWithDictionary:dict toURL:@"sendmsg" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            NSLog(@"%@",err);
            [hud hideWithFailureMessage:@"发送失败"];
            return;
        }
        // NSLog(@"%@", result);
        if ([[result.firstObject objectForKey:@"code"] integerValue] == 0) {
            [hud hideWithSuccessMessage:@"发送成功"];
        } else {
            [hud hideWithFailureMessage:@"发送失败"];
        }
        switch ([[result.firstObject objectForKey:@"code"] integerValue]) {
            case 0: {
                cell.textSend.text = @"";
                [self loadChat];
                [NOTIFICATION postNotificationName:@"chatChanged" object:nil];
                break;
            }
            case 1:{
                [self showAlertWithTitle:@"发送失败" message:@"您长时间未登录，请重新登录！"];
                break;
            }
            case 3:{
                [self showAlertWithTitle:@"发送失败" message:@"私信的对象不存在！"];
                break;
            }
            case 4:{
                [self showAlertWithTitle:@"发送失败" message:@"数据库错误！"];
                break;
            }
            default:{
                [self showAlertWithTitle:@"发送失败" message:@"发生未知错误！"];
                break;
            }
        }
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [segue destinationViewController];
        dest.ID = self.ID;
        dest.noRightBarItem = YES;
        dest.iconData = self.iconData;
        dest.navigationItem.leftBarButtonItems = nil;
    }
}

@end
