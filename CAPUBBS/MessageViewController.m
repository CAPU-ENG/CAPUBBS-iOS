//
//  MessageViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "MessageViewController.h"
#import "MessageCell.h"
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
    self.title = @"消息中心";
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    messageRefreshing = NO;
    
    [NOTIFICATION addObserver:self selector:@selector(backgroundRefresh) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(getInfo) name:@"chatChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(reloadTableView) name:@"collectionChanged" object:nil];
    
    control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:control];
    
    if (LIQUID_GLASS) {
        [self.segmentBackgroundView removeFromSuperview];
        [self.segmentTypeInView removeFromSuperview];
        activeSegment = self.segmentTypeInTitle;
    } else {
        self.navigationItem.titleView = nil;
        activeSegment = self.segmentTypeInView;
        
        self.segmentBackgroundView.backgroundColor = [GREEN_BACK colorWithAlphaComponent:0.85];
        self.tableView.contentInset = UIEdgeInsetsMake(48, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        
        activeSegment.selectedSegmentTintColor = GREEN_DARK;
        // 普通状态文字
        [activeSegment setTitleTextAttributes:@{
            NSForegroundColorAttributeName: [UIColor darkGrayColor],
        } forState:UIControlStateNormal];
        // 选中状态文字
        [activeSegment setTitleTextAttributes:@{
            NSForegroundColorAttributeName: [UIColor whiteColor],
        } forState:UIControlStateSelected];
    }
    [self typeChanged:activeSegment];
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
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [hud showWithProgressMessage:@"正在刷新"];
    [self getInfo];
}

- (void)reloadTableView {
    dispatch_main_sync_safe(^{
        [self.tableView reloadData];
    });
}

- (void)getInfo {
    dispatch_main_async_safe((^{
        if (messageRefreshing) {
            return;
        }
        if (![Helper checkLogin:NO]) {
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
            return;
        }
        messageRefreshing = YES;
        NSString *type = (activeSegment.selectedSegmentIndex == 0) ? @"system" : @"private";
        [hud showWithProgressMessage:@"正在加载"];
        NSDictionary *dict = @{
            @"type" : type,
            @"page" : [NSString stringWithFormat:@"%ld", (long)page]
        };
        [Helper callApiWithParams:dict toURL:@"msg" callback: ^(NSArray *result, NSError *err) {
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
            if ([data[0][@"code"] isEqualToString:@"1"]) {
                [self showAlertWithTitle:@"错误" message:@"尚未登录或登录超时"];
            }
            [self setMessageNum];
            
            if ([self.tableView numberOfRowsInSection:0] == 0) {
                [self.tableView reloadData];
            } else {
                UITableViewRowAnimation rowAnimation = UITableViewRowAnimationFade;
                if (!SIMPLE_VIEW) {
                    if (originalSegment < activeSegment.selectedSegmentIndex) {
                        rowAnimation = UITableViewRowAnimationLeft;
                    }
                    if (originalSegment > activeSegment.selectedSegmentIndex) {
                        rowAnimation = UITableViewRowAnimationRight;
                    }
                }
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnimation];
            }
            originalSegment = activeSegment.selectedSegmentIndex;
            
            if (data.count > 1) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            if (data.count - 1 < 10) {
                maxPage = page;
            }
            self.buttonPrevious.enabled = (page > 1);
            self.buttonNext.enabled = (page < maxPage);
            self.tableView.scrollEnabled = data.count > 1;
        }];
    }));
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        page = 1;
        maxPage = 10000;
        if (LIQUID_GLASS) {
            [self setToolbarItems:@[self.buttonPrevious, self.buttonNext] animated:YES];
        } else {
            [self setToolbarItems:@[self.buttonPrevious, self.flexSpace, self.buttonNext] animated:YES];
        }
    } else {
        page = -1;
        maxPage = -1;
        if (LIQUID_GLASS) {
            [self setToolbarItems:@[self.buttonAdd] animated:YES];
        } else {
            [self setToolbarItems:@[self.flexSpace, self.buttonAdd, self.flexSpace] animated:YES];
        }
    }
    [self getInfo];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (activeSegment.selectedSegmentIndex == 0 && swipeDirection == 1) {
            [activeSegment setSelectedSegmentIndex:1];
            [self typeChanged:activeSegment];
        }
        if (activeSegment.selectedSegmentIndex == 1 && swipeDirection == 0) {
            [activeSegment setSelectedSegmentIndex:0];
            [self typeChanged:activeSegment];
        }
    }
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        int swipeDirection = [[DEFAULTS objectForKey:@"oppositeSwipe"] intValue];
        if (swipeDirection == 2) { // Disable swipe
            return;
        }
        if (activeSegment.selectedSegmentIndex == 0 && swipeDirection == 0) {
            [activeSegment setSelectedSegmentIndex:1];
            [self typeChanged:activeSegment];
        }
        if (activeSegment.selectedSegmentIndex == 1 && swipeDirection == 1) {
            [activeSegment setSelectedSegmentIndex:0];
            [self typeChanged:activeSegment];
        }
    }
}

- (void)setMessageNum {
    if (data.count > 0 && [data[0][@"sysmsg"] integerValue] > 0) {
        [activeSegment setTitle:[NSString stringWithFormat:@"系统(%@)", data[0][@"sysmsg"]] forSegmentAtIndex:0];
    } else {
        [activeSegment setTitle:@"系统消息" forSegmentAtIndex:0];
    }
    if (data.count > 0 && [data[0][@"prvmsg"] integerValue] > 0) {
        [activeSegment setTitle:[NSString stringWithFormat:@"私信(%@)", data[0][@"prvmsg"]] forSegmentAtIndex:1];
    } else {
        [activeSegment setTitle:@"私信消息" forSegmentAtIndex:1];
    }
    NSDictionary *infoDict = USERINFO;
    if (data.count > 0 && infoDict && ![infoDict isEqual:@""]) {
        NSMutableDictionary *dict = [infoDict mutableCopy];
        NSString *msgNum = [NSString stringWithFormat:@"%d", [data[0][@"sysmsg"] intValue] + [data[0][@"prvmsg"] intValue]];
        [dict setObject:msgNum forKey:@"newmsg"];
        [Helper updateUserInfo:dict];
    }
}

- (IBAction)previous:(id)sender {
    if (messageRefreshing) {
        return;
    }
    page--;
    [self getInfo];
}

- (IBAction)next:(id)sender {
    if (messageRefreshing) {
        return;
    }
    page++;
    [self getInfo];
}

- (IBAction)add:(id)sender {
    if (messageRefreshing) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"发送私信"
                                                                   message:@"请输入对方的用户名"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(alertController) weakAlertController = alertController; // 避免循环引用
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"用户名";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"开始"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakAlertController) strongAlertController = weakAlertController;
        if (!strongAlertController) {
            return;
        }
        NSString *userName = strongAlertController.textFields[0].text;
        if (userName.length == 0) {
            [self showAlertWithTitle:@"错误" message:@"用户名不能为空"];
        } else {
            chatID = userName;
            [self performSegueWithIdentifier:@"chat" sender:nil];
        }
    }]];
    [self presentViewControllerSafe:alertController];
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
    if (!data || data.count > 1) {
        return nil;
    }
    return activeSegment.selectedSegmentIndex == 0 ? @"您还没有系统消息" : @"您还没有私信消息";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:(activeSegment.selectedSegmentIndex == 0) ? @"systemmsg" : @"privatemsg" forIndexPath:indexPath];
    
    NSDictionary *dict = data[indexPath.row + 1];
    cell.labelUser.text = dict[@"username"];
    NSMutableAttributedString *text;
    if (activeSegment.selectedSegmentIndex == 0) {
        int textLenth = 0;
        NSString *titleText = dict[@"title"];
        titleText = [Helper restoreTitle:titleText];
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
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
        if (sender == nil) {
            dest.ID = chatID;
            dest.directTalk = YES;
        } else {
            dest.ID = dict[@"username"];
            NSMutableArray *tempData = [data mutableCopy];
            if ([tempData[indexPath.row + 1][@"number"] intValue] > 0) {
                NSString *prvmsg = tempData[0][@"prvmsg"];
                NSString *number = tempData[indexPath.row + 1][@"number"];
                prvmsg = [NSString stringWithFormat:@"%d", [prvmsg intValue] - [number intValue]];
                [tempData[0] setObject:prvmsg forKey:@"prvmsg"];
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
        dest.destinationPage = dict[@"p"];
        // NSLog(@"%@", dict[@"url"]);
        NSString *floor = [Helper getLink:dict[@"url"]][@"floor"];
        if ([floor intValue] > 0) {
            dest.destinationFloor = floor;
            if ([dict[@"type"] hasPrefix:@"replylzl"]) {
                dest.openDestinationLzl = YES;
            }
        }
        dest.title = [Helper restoreTitle:dict[@"title"]];
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
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:sender halfScreen:YES];
        UIButton *button = sender;
        dest.ID = data[button.tag + 1][@"username"];
        MessageCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:button.tag inSection:0]];
        if (cell && ![cell.imageIcon.image isEqual:PLACEHOLDER]) {
            dest.iconData = UIImagePNGRepresentation(cell.imageIcon.image);
        }
    }
    if ([segue.identifier isEqualToString:@"setting"]) {
        UIViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:sender halfScreen:NO];
    }
}

@end
