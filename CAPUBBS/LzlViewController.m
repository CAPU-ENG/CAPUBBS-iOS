//
//  LzlViewController.m
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LzlViewController.h"
#import "UserViewController.h"
#import "ContentViewController.h"
#import "WebViewController.h"

@interface LzlViewController ()

@end

@implementation LzlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    
    self.preferredContentSize = CGSizeMake(360, 0);
    performer = [[ActionPerformer alloc] init];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    shouldShowHud = YES;
    
    [self loadData];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //    if (![[DEFAULTS objectForKey:@"Featurelzl1.3"] boolValue]) {
    //        [[[UIAlertView alloc] initWithTitle:@"新功能！" message:@"长按某层楼中楼可以快捷回复" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil] show];
    //        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"Featurelzl1.3"];
    //    }
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".lzl"]];
    activity.webpageURL = self.URL;
    [activity becomeCurrent];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)refreshControlValueChanged:(UIRefreshControl*)sender{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    shouldShowHud = YES;
    [self loadData];
}

- (IBAction)back:(id)sender {
    if (self.textPost.text.length == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [[[UIAlertView alloc] initWithTitle:@"确定退出" message:@"您输入了尚未发表的楼中楼内容，确定继续退出？" delegate:self cancelButtonTitle:@"返回" otherButtonTitles:@"退出", nil] show];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.textPost) {
        return;
    }
    if (scrollView.dragging) {
        [self.view endEditing:YES];
    }
}

- (void)loadData {
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    if (shouldShowHud) {
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"读取中";
        [hud show:YES];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.fid, @"fid", @"show", @"method", nil];
    [performer performActionWithDictionary:dict toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
        if (err || result.count == 0) {
            if (shouldShowHud) {
                hud.mode = MBProgressHUDModeCustomView;
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"读取失败";
                [hud hide:YES afterDelay:0.5];
            }
            return;
        }
        
        if (shouldShowHud) {
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.labelText = @"读取成功";
            [hud hide:YES afterDelay:0.5];
        }
        shouldShowHud = NO;
        
        data = [result subarrayWithRange:NSMakeRange(1, result.count - 1)];
        [NOTIFICATION postNotificationName:@"refreshLzl" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", (int)data.count], @"num", self.fid, @"fid", nil]];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return data.count;
    }else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LzlCell *cell;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        NSDictionary *dict = data[indexPath.row];
        cell.textAuthor.text = dict[@"author"];
        [cell.imageBottom setImage:[[UIImage imageNamed:[dict[@"author"] isEqualToString:UID] ? @"balloon_white" : @"balloon_green"] stretchableImageWithLeftCapWidth:15 topCapHeight:15]];
        cell.textTime.text = dict[@"time"];
        cell.textMain.text = dict[@"text"];
        NSString *url = dict[@"icon"];
        [cell.icon setUrl:url];
        [cell.icon.layer setCornerRadius:cell.icon.frame.size.width / 2];
        cell.buttonIcon.tag = indexPath.row;
        
        if (cell.gestureRecognizers.count == 0) {
            [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
        }
    }else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"post" forIndexPath:indexPath];
        
        self.textPost = cell.textPost;
        [self.textPost setDelegate:self];
        [self textViewDidChange:self.textPost];
        self.labelByte = cell.labelByte;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSString *text = [data[[indexPath row]] objectForKey:@"text"];
        //下句中(CELL_CONTENT_WIDTH - CELL_CONTENT_MARGIN 表示显示内容的label的长度 ，20000.0f 表示允许label的最大高度
        CGSize constraint = CGSizeMake(self.view.frame.size.width - 110, 20000.0f);
        CGSize size = [text boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size;
        return MAX(size.height, 18.0f) + 52;
    }else {
        return 100;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        if (!data) {
            return @"正在加载";
        }else if (data.count == 0) {
            return @"暂时没有楼中楼";
        }
        return [NSString stringWithFormat:@"共有%lu条楼中楼",(unsigned long)data.count];
    }else {
        return @"发表楼中楼";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UIAlertController *action = [UIAlertController alertControllerWithTitle:@"选择操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [action addAction:[UIAlertAction actionWithTitle:@"回复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self directPost:nil];
        }]];
        [action addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIPasteboard generalPasteboard] setString:lzlText];
            hud.labelText = @"复制完成";
            [hud show:YES];
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            [hud hide:YES afterDelay:0.5];
        }]];
        [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        lzlText = [data[indexPath.row] objectForKey:@"text"];
        lzlAuthor = [data[indexPath.row] objectForKey:@"author"];
        NSString *exp = @"[a-zA-z]+://[^\\s]*"; // 提取网址链接
        NSRange range = [lzlText rangeOfString:exp options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            lzlUrl = [lzlText substringWithRange:range];
            [action addAction:[UIAlertAction actionWithTitle:@"打开连接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSDictionary *dict = [ContentViewController getLink:lzlUrl];
                if (dict.count > 0 && ![dict[@"tid"] isEqualToString:@""]) {
                    ContentViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"content"];
                    dest.bid = dict[@"bid"];
                    dest.tid = dict[@"tid"];
                    dest.floor = [NSString stringWithFormat:@"%d", [dict[@"p"] intValue] * 12];
                    dest.title=@"帖子跳转中";
                    dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
                    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:dest];
                    [navi setToolbarHidden:NO];
                    [self presentViewController:navi animated:YES completion:nil];
                }else {
                    WebViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"webview"];
                    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:dest];
                    dest.URL = lzlUrl;
                    [navi setToolbarHidden:NO];
                    [self presentViewController:navi animated:YES completion:nil];
                }
            }]];
        }
        LzlCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UIView *view = cell.textMain;
        action.popoverPresentationController.sourceView = view;
        action.popoverPresentationController.sourceRect = view.bounds;
        [self presentViewController:action animated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:@"警告"]) {
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"正在删除";
        [hud show:YES];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"delete", @"method", self.fid, @"fid", [data[alertView.tag] objectForKey:@"id"], @"id", nil];
        [performer performActionWithDictionary:dict toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"删除失败";
            }else {
                if ([[result.firstObject objectForKey:@"code"] integerValue]==0) {
                    hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                    hud.labelText = @"删除成功";
                    NSMutableArray *temp = [NSMutableArray arrayWithArray:data];
                    [temp removeObjectAtIndex:alertView.tag];
                    data = [NSArray arrayWithArray:temp];
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:alertView.tag inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    [self performSelector:@selector(loadData) withObject:nil afterDelay:0.5];
                }else {
                    hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                    hud.labelText = @"删除失败";
                    [[[UIAlertView alloc] initWithTitle:@"删除失败" message:[result.firstObject objectForKey:@"msg"] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
                }
            }
            hud.mode = MBProgressHUDModeCustomView;
            [hud hide:YES afterDelay:0.5];
        }];
    }else if ([alertView.title isEqualToString:@"确定退出"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 0) {
        if ([ActionPerformer checkRight] > 1 || [[data[indexPath.row] objectForKey:@"author"] isEqualToString:UID]) {
            return YES;
        }
    }
    return NO;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        UIAlertView *confirmDel = [[UIAlertView alloc] initWithTitle:@"警告" message:@"确定要删除该楼中楼吗？\n删除操作不可逆！" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
        confirmDel.tag = indexPath.row;
        [confirmDel show];
    }else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (IBAction)buttonPost:(id)sender {
    if (self.textPost.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"楼中楼内容为空！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        [self.textPost becomeFirstResponder];
        return;
    }
    if (self.textPost.text.length > 140) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"楼中楼内容太长！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        [self.textPost becomeFirstResponder];
        return;
    }
    
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"正在发布";
    [hud show:YES];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"post", @"method", self.fid, @"fid", self.textPost.text, @"text", nil];
    [performer performActionWithDictionary:dict toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.labelText = @"发布失败";
        }else {
            if ([[[result firstObject] objectForKey:@"code"] integerValue]==0) {
                hud.labelText = @"发布成功";
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                self.textPost.text = @"";
                [self performSelector:@selector(loadData) withObject:nil afterDelay:0.5];
            }else {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"发布失败";
                [[[UIAlertView alloc] initWithTitle:@"发布失败" message:[[result firstObject] objectForKey:@"msg"] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
            }
        }
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:0.5];
    }];
}

- (IBAction)directPost:(id)sender {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    if (sender == nil) {
        [self.textPost insertText:[NSString stringWithFormat:@"回复 @%@: ",lzlAuthor]];
    }
    [self performSelector:@selector(inputText) withObject:nil afterDelay:0.5];
}

- (void)inputText {
    [self.textPost becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    int length = (int)textView.text.length;
    self.labelByte.text = [NSString stringWithFormat:@"%d/140", length];
    if (length <= 120) {
        [self.labelByte setTextColor:[UIColor darkGrayColor]];
    }else if (length <= 140) {
        [self.labelByte setTextColor:[UIColor orangeColor]];
    }else {
        [self.labelByte setTextColor:[UIColor redColor]];
    }
}

- (void)longPress:(UILongPressGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![ActionPerformer checkLogin:YES]) {
            return;
        }
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil) {
            return;
        }
        lzlAuthor = [data[indexPath.row] objectForKey:@"author"];
        [self directPost:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [segue destinationViewController];
        UIButton *button = sender;
        dest.ID = [data[button.tag] objectForKey:@"author"];
        dest.navigationItem.leftBarButtonItems = nil;
        LzlCell *cell = (LzlCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:button.tag inSection:0]];
        if (![cell.icon.image isEqual:PLACEHOLDER]) {
            dest.iconData = UIImagePNGRepresentation(cell.icon.image);
        }
    }
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
