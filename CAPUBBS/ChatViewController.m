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
    if (self.iconData.length > 0) {
        [self refreshBackgroundView:YES];
    }
    
    if (self.shouldHideInfo == YES) {
        self.navigationItem.rightBarButtonItems = nil;
    }else if (self.directTalk == YES) {
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"发送私信" message:@"请输入对方的用户名" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"开始", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].placeholder = @"用户名";
        [alert show];
    }else {
        self.title = self.ID;
        [self loadChat];
    }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)refresh:(NSNotification *)noti {
    if (self.iconData.length == 0) {
        self.iconData = noti.userInfo[@"data"];
        [self performSelectorOnMainThread:@selector(refreshBackgroundView:) withObject:nil waitUntilDone:NO];
    }
}

- (void)refreshBackgroundView:(BOOL)noAnimation {
    if ([[DEFAULTS objectForKey:@"simpleView"] boolValue] == NO) {
        if (!backgroundView) {
            backgroundView = [[AsyncImageView alloc] init];
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            self.tableView.backgroundView = backgroundView;
        }
        [backgroundView setBlurredImage:[UIImage imageWithData:self.iconData] animated:!noAnimation];
    }
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
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    if (shouldShowHud) {
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"正在加载";
        [hud show:YES];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"chat", @"type", self.ID, @"chatter", nil];
    [performer performActionWithDictionary:dict toURL:@"msg" withBlock: ^(NSArray *result, NSError *err) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        if (err || result.count == 0) {
            if (shouldShowHud) {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"加载失败";
                hud.mode = MBProgressHUDModeCustomView;
                [hud hide:YES afterDelay:0.5];
            }
            return ;
        }
        
        if ([[data[0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录或登录超时" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        }
        
        data = result;
        if (data.count == 1) {
            [self checkID:shouldShowHud];
        }else if (shouldShowHud) {
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.labelText = @"加载成功";
            hud.mode = MBProgressHUDModeCustomView;
            [hud hide:YES afterDelay:0.5];
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
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"没有这个ID！" delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
            if (hudVisible) {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"加载失败";
            }
        }else {
            NSString *iconUrl = result[0][@"icon"];
            [NOTIFICATION addObserver:self selector:@selector(refresh:) name:[@"imageSet" stringByAppendingString:[AsyncImageView transIconURL:iconUrl]] object:nil];
            AsyncImageView *icon = [[AsyncImageView alloc] init];
            [icon setUrl:iconUrl];
            if (hudVisible) {
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                hud.labelText = @"加载成功";
            }
        }
        if (hudVisible) {
            hud.mode = MBProgressHUDModeCustomView;
            [hud hide:YES afterDelay:0.5];
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if ([alertView.title isEqualToString:@"发送私信"]) {
        self.ID = [alertView textFieldAtIndex:0].text;
        self.title = self.ID;
        [self loadChat];
    }
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
    }else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSString *text = [data[indexPath.row + 1] objectForKey:@"text"];
        //下句中(CELL_CONTENT_WIDTH - CELL_CONTENT_MARGIN 表示显示内容的label的长度 ，20000.0f 表示允许label的最大高度
        CGSize constraint = CGSizeMake(self.view.frame.size.width - 170 - 10, 20000.0f);
        CGSize size = [text boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
        return MAX(size.height, 18.0f) + 65;
    }else {
        return 100;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (data.count > 1) {
            return [NSString stringWithFormat:@"私信记录 共%d条", (int)data.count - 1];
        }else {
            return @"私信记录 暂无";
        }
    }else {
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
        }else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"chatSelf" forIndexPath:indexPath];
            [cell.imageChat setImage:[[UIImage imageNamed:@"balloon_white_reverse"] stretchableImageWithLeftCapWidth:15 topCapHeight:15]];
            [cell.imageIcon setUrl:[USERINFO objectForKey:@"icon"]];
        }
        
        cell.labelTime.text = [NSString stringWithFormat:@"  %@  ", dict[@"time"]];
        cell.textMessage.text = dict[@"text"];
        [cell.imageIcon.layer setCornerRadius:cell.imageIcon.frame.size.width / 2]; // 圆形
    }else {
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
    ChatCell *cell = (ChatCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    NSString *text = cell.textSend.text;
    if (text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您未填写私信内容！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        return;
    }
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"正在发送";
    [hud show:YES];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.ID, @"to", text, @"text", nil];
    [performerSend performActionWithDictionary:dict toURL:@"sendmsg" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            NSLog(@"%@",err);
            hud.labelText = @"发送失败";
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.mode = MBProgressHUDModeCustomView;
            [hud hide:YES afterDelay:0.5];
            return;
        }
        // NSLog(@"%@", result);
        if ([[result.firstObject objectForKey:@"code"] integerValue] == 0) {
            hud.labelText = @"发送成功";
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
        }else {
            hud.labelText = @"发送失败";
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
        }
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:0.5];
        switch ([[result.firstObject objectForKey:@"code"] integerValue]) {
            case 0: {
                cell.textSend.text = @"";
                [self loadChat];
                [NOTIFICATION postNotificationName:@"chatChanged" object:nil];
                break;
            }
            case 1:{
                [[[UIAlertView alloc] initWithTitle:@"发送失败" message:@"您长时间未登录，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                break;
            }
            case 3:{
                [[[UIAlertView alloc] initWithTitle:@"发送失败" message:@"留言的对象不存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                break;
            }
            case 4:{
                [[[UIAlertView alloc] initWithTitle:@"发送失败" message:@"数据库错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                break;
            }
            default:{
                [[[UIAlertView alloc] initWithTitle:@"发送失败" message:@"发生未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
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
