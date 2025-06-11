//
//  MessageViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "MessageViewController.h"
#import "ContentViewController.h"
#import "ChatViewController.h"
#import "UserViewController.h"
#import "SettingViewController.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    performer = [[ActionPerformer alloc] init];
    messageRefreshing = NO;
    isFirstTime = YES;
    [NOTIFICATION addObserver:self selector:@selector(backgroundRefresh) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(getInfo) name:@"chatChanged" object:nil];
    [NOTIFICATION addObserver:self.tableView selector:@selector(reloadData) name:@"collectionChanged" object:nil];
    control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:control];
    if (@available(iOS 13.0, *)) {
        self.segmentType.selectedSegmentTintColor = GREEN_DARK;
        // 普通状态文字颜色
        [self.segmentType setTitleTextAttributes:@{
            NSForegroundColorAttributeName: [UIColor grayColor]
        } forState:UIControlStateNormal];
        // 选中状态文字颜色
        [self.segmentType setTitleTextAttributes:@{
            NSForegroundColorAttributeName: [UIColor whiteColor]
        } forState:UIControlStateSelected];
    } else {
        self.segmentType.tintColor = GREEN_DARK;
    }
//    [self.segmentType setTintColor:GREEN_DARK];
    [self typeChanged:self.segmentType];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    isVisible = YES;
    if (isBackground) {
        [self getInfo];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    isVisible = NO;
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    control.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [hud showWithProgressMessage:@"正在刷新"];
    [self getInfo];
}

- (void)getInfo {
    if (self.segmentType.selectedSegmentIndex == 0) {
        self.toolbarItems = @[self.buttonPrevious, self.barFreeSpace, self.barFreeSpace, self.buttonNext];
    } else {
        self.toolbarItems = @[self.barFreeSpace, self.buttonAdd, self.barFreeSpace];
    }
    if ([ActionPerformer checkLogin:NO] && messageRefreshing == NO) {
        messageRefreshing = YES;
        NSString *type = (self.segmentType.selectedSegmentIndex == 0) ? @"system" : @"private";
        [hud showWithProgressMessage:@"正在加载"];
        NSDictionary *dict = @{
            @"type" : type,
            @"page" : [NSString stringWithFormat:@"%ld", (long)page]
        };
        [performer performActionWithDictionary:dict toURL:@"msg" withBlock: ^(NSArray *result, NSError *err) {
            if (control.isRefreshing) {
                [control endRefreshing];
            }
            messageRefreshing = NO;
            isBackground = NO;
            if (err || result.count == 0) {
                [hud hideWithFailureMessage:@"加载失败"];
                return;
            }
            [hud hideWithSuccessMessage:@"加载成功"];
            
            // NSLog(@"%@", result);
            data = result;
            if ([[data[0] objectForKey:@"code"] isEqualToString:@"1"]) {
                [self showAlertWithTitle:@"错误" message:@"尚未登录或登录超时"];
            }
            [self setMessageNum];
            
            int rowAnimation = -1;
            if (originalSegment < self.segmentType.selectedSegmentIndex) {
                rowAnimation = UITableViewRowAnimationLeft;
            }
            if (originalSegment > self.segmentType.selectedSegmentIndex) {
                rowAnimation = UITableViewRowAnimationRight;
            }
            if (rowAnimation > 0) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnimation];
            } else {
                if (isFirstTime) {
                    [self.tableView reloadData];
                } else {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                isFirstTime = NO;
            }
            originalSegment = self.segmentType.selectedSegmentIndex;
            
            if (data.count > 1) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            if (data.count - 1 < 10) {
                maxPage = page;
            }
            self.buttonPrevious.enabled = (page > 1);
            self.buttonNext.enabled = (page < maxPage);
        }];
    } else {
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        [hud showAndHideWithFailureMessage:@"尚未登录"];
        data = nil;
        self.buttonPrevious.enabled = NO;
        self.buttonNext.enabled = NO;
        self.buttonAdd.enabled = NO;
        [self setMessageNum];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        page = 1;
        maxPage = 10000;
    } else {
        page = -1;
        maxPage = -1;
    }
    [self getInfo];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.segmentType.selectedSegmentIndex == 0 && swipeDirection == 1) {
            [self.segmentType setSelectedSegmentIndex:1];
            [self typeChanged:self.segmentType];
        }
        if (self.segmentType.selectedSegmentIndex == 1 && swipeDirection == 0) {
            [self.segmentType setSelectedSegmentIndex:0];
            [self typeChanged:self.segmentType];
        }
    }
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (self.segmentType.selectedSegmentIndex == 0 && swipeDirection == 0) {
            [self.segmentType setSelectedSegmentIndex:1];
            [self typeChanged:self.segmentType];
        }
        if (self.segmentType.selectedSegmentIndex == 1 && swipeDirection == 1) {
            [self.segmentType setSelectedSegmentIndex:0];
            [self typeChanged:self.segmentType];
        }
    }
}

- (void)setMessageNum {
    if ([[data[0] objectForKey:@"sysmsg"] integerValue] > 0) {
        [self.segmentType setTitle:[NSString stringWithFormat:@"系统消息(%@)", [data[0] objectForKey:@"sysmsg"]] forSegmentAtIndex:0];
    } else {
        [self.segmentType setTitle:@"系统消息" forSegmentAtIndex:0];
    }
    if ([[data[0] objectForKey:@"prvmsg"] integerValue] > 0) {
        [self.segmentType setTitle:[NSString stringWithFormat:@"私信消息(%@)", [data[0] objectForKey:@"prvmsg"]] forSegmentAtIndex:1];
    } else {
        [self.segmentType setTitle:@"私信消息" forSegmentAtIndex:1];
    }
    if (![USERINFO isEqual:@""]) {
        NSMutableDictionary *dict = [USERINFO mutableCopy];
        NSString *msgNum = [NSString stringWithFormat:@"%d", [[data[0] objectForKey:@"sysmsg"] intValue] + [[data[0] objectForKey:@"prvmsg"] intValue]];
        [dict setObject:msgNum forKey:@"newmsg"];
        [GROUP_DEFAULTS setObject:dict forKey:@"userInfo"];
    }
    dispatch_main_async_safe(^{
        [NOTIFICATION postNotificationName:@"infoRefreshed" object:nil];
    });
}

- (IBAction)previous:(id)sender {
    page--;
    [self getInfo];
}

- (IBAction)next:(id)sender {
    page++;
    [self getInfo];
}

- (IBAction)add:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发送私信"
                                                                   message:@"请输入对方的用户名"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"用户名";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *userName = alert.textFields.firstObject.text;
        if (userName.length == 0) {
            [self showAlertWithTitle:@"错误" message:@"用户名不能为空"];
        } else {
            chatID = userName;
            [self performSegueWithIdentifier:@"chat" sender:nil];
        }
    }]];
    [self presentViewControllerSafe:alert];
}

- (void)backgroundRefresh {
    // NSLog(@"Personal Center Background Refresh");
    if (isVisible) {
        [self getInfo];
    } else {
        isBackground = YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return data.count - 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return data && data.count <= 1 ? @"您还没有消息" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:(self.segmentType.selectedSegmentIndex == 0) ? @"systemmsg" : @"privatemsg" forIndexPath:indexPath];
    
    NSDictionary *dict = data[indexPath.row + 1];
    cell.labelUser.text = dict[@"username"];
    NSMutableAttributedString *text;
    if (self.segmentType.selectedSegmentIndex == 0) {
        int textLenth = 0;
        NSString *titleText = dict[@"title"];
        titleText = [ActionPerformer removeRe:titleText];
        NSString *type = dict[@"type"];
        if ([type isEqualToString:@"reply"]) {
            text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"回复了您的帖子：%@", titleText]];
            textLenth = 8;
        } else if ([type isEqualToString:@"replylzl"]) {
            text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"回复了您在帖子：%@ 中的回复", titleText]];
            textLenth = 8;
        } else if ([type isEqualToString:@"replylzlreply"]) {
            text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"回复了您在帖子：%@ 中的楼中楼", titleText]];
            textLenth = 8;
        } else if ([type isEqualToString:@"at"]) {
            text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"在帖子：%@ 中@了您", titleText]];
            textLenth = 4;
        } else if ([type isEqualToString:@"quote"]) {
            text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"在帖子：%@ 中引用了您的文章", titleText]];
            textLenth = 4;
        } else if ([type isEqualToString:@"plain"]) {
            text = [[NSMutableAttributedString alloc] initWithString:titleText];
            textLenth = 0;
        }
        for (NSDictionary *mdic in [DEFAULTS objectForKey:@"collection"]) {
            if ([dict[@"bid"] isEqualToString:mdic[@"bid"]] && [dict[@"tid"] isEqualToString:mdic[@"tid"]]) {
                [text addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:cell.labelText.font.pointSize weight:UIFontWeightBold] range:NSMakeRange(textLenth, titleText.length)];
                break;
            }
        }
        [text addAttribute:NSForegroundColorAttributeName value:BLUE range:NSMakeRange(textLenth, titleText.length)];
        cell.labelText.attributedText = text;
        cell.labelNum.text = @"";
        [cell.labelNum setHidden:[dict[@"hasread"] boolValue]];
    } else {
        cell.labelMsgNum.text = dict[@"totalnum"];
        cell.labelText.text = dict[@"text"];
        cell.labelNum.text = dict[@"number"];
        [cell.labelNum setHidden:([dict[@"number"] intValue] == 0)];
    }
    [cell.imageIcon setUrl:dict[@"icon"]];
    cell.buttonIcon.tag = indexPath.row;
    cell.labelTime.text = dict[@"time"];
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
    NSDictionary *dict;
    if (indexPath != nil) {
        dict = data[indexPath.row + 1];
    }
    if ([segue.identifier isEqualToString:@"chat"]) {
        ChatViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        if (sender == nil) {
            dest.ID = chatID;
            dest.directTalk = YES;
        } else {
            dest.ID = dict[@"username"];
            NSMutableArray *tempData = [data mutableCopy];
            if ([tempData[indexPath.row + 1][@"number"] intValue] > 0) {
                NSString *primsg = tempData[0][@"prvmsg"];
                NSString *number = tempData[indexPath.row + 1][@"number"];
                primsg = [NSString stringWithFormat:@"%d", [primsg intValue] - [number intValue]];
                [tempData[0] setObject:primsg forKey:@"prvmsg"];
                [tempData[indexPath.row + 1] setObject:@"0" forKey:@"number"];
                data = [NSArray arrayWithArray:tempData];
                [self.tableView reloadData];
                [self setMessageNum];
            }
        }
        MessageCell *cell = (MessageCell *)sender;
        if (![cell.imageIcon.image isEqual:PLACEHOLDER]) {
            dest.iconData = UIImagePNGRepresentation(cell.imageIcon.image);
        }
    } else if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        dest.tid = dict[@"tid"];
        dest.bid = dict[@"bid"];
        dest.floor = [NSString stringWithFormat:@"%d", [dict[@"p"] intValue] * 12];
        // NSLog(@"%@", dict[@"url"]);
        NSString *floor = [ContentViewController getLink:dict[@"url"]][@"floor"];
        if ([floor intValue] > 0) {
            dest.destinationFloor = floor;
            if ([dict[@"type"] hasPrefix:@"replylzl"]) {
                dest.openDestinationLzl = YES;
            }
        }
        dest.title = @"帖子跳转中";
        NSMutableArray *tempData = [data mutableCopy];
        if ([tempData[indexPath.row + 1][@"hasread"] isEqualToString:@"0"]) {
            NSString *sysmsg = tempData[0][@"sysmsg"];
            sysmsg = [NSString stringWithFormat:@"%d", [sysmsg intValue] - 1];
            [tempData[0] setObject:sysmsg forKey:@"sysmsg"];
            [tempData[indexPath.row + 1] setObject:@"1" forKey:@"hasread"];
            data = [NSArray arrayWithArray:tempData];
            [self.tableView reloadData];
            [self setMessageNum];
        }
    }
    if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        UIButton *button = sender;
        dest.navigationController.modalPresentationStyle = UIModalPresentationPopover;
        dest.navigationController.popoverPresentationController.sourceView = button;
        dest.navigationController.popoverPresentationController.sourceRect = button.bounds;
        dest.ID = data[button.tag + 1][@"username"];
        MessageCell *cell = (MessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:button.tag inSection:0]];
        if (![cell.imageIcon.image isEqual:PLACEHOLDER]) {
            dest.iconData = UIImagePNGRepresentation(cell.imageIcon.image);
        }
    }
}

@end
