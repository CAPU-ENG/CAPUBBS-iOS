//
//  ListViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ListViewController.h"
#import "ActionPerformer.h"
#import "ListCell.h"
#import "ContentViewController.h"
#import "ComposeViewController.h"
#import "ContentCell.h"

@interface ListViewController ()

@end

@implementation ListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)refreshControlValueChanged:(UIRefreshControl*)sender{
    self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"正在刷新"];
    [self jumpTo:page];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    page=1;
    performer=[[ActionPerformer alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldRefresh:) name:@"shouldRefresh" object:nil];
    [self.navigationItem setTitle:self.name];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self jumpTo:page];
    self.searchDisplayController.searchBar.scopeButtonTitles=@[@"帖子标题",@"帖子内容"];
    
//    self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"下拉刷新"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        
        for (UIView *subview in self.searchDisplayController.searchResultsTableView.subviews) {
            
            if ([subview isKindOfClass:[UILabel class]] && ([[(UILabel *)subview text] isEqualToString:@"No Results"]||[[(UILabel *)subview text] isEqualToString:@"无结果"])) {
                
                UILabel *label = (UILabel *)subview;
                
                label.text = @"轻点按钮开始搜索";
                
                break;
                
            }
            
        }
        
    });
    
    return NO;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText=@"正在搜索";
    [hud show:YES];
    performer=[[ActionPerformer alloc] init];
    NSArray *types=@[@"thread",@"post"];
    NSString *text=self.searchDisplayController.searchBar.text;
    NSString *type=[types objectAtIndex:self.searchDisplayController.searchBar.selectedScopeButtonIndex];
    [performer performActionWithDictionary:@{@"type":type,@"bid":self.b,@"text":text} toURL:@"search" withBlock:^(NSArray *result, NSError *err) {
        [hud hide:YES];
        if (err) {
            searchResult=nil;
            return ;
        }
        searchResult=[result subarrayWithRange:NSMakeRange(1, result.count-1)];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
}

-(void)shouldRefresh:(NSNotification*)sender{
    [self jumpTo:page];
}
-(void)jumpTo:(NSInteger)pageNum{
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText=@"读取中";
    [hud show:YES];
    NSInteger oldPage=page;
    page=pageNum;
    self.buttonBack.enabled=page!=1;
    [performer performActionWithDictionary:@{@"bid":self.b,@"p":[NSString stringWithFormat:@"%ld",(long)pageNum]} toURL:@"show" withBlock:^(NSArray *result, NSError *err) {
        if(self.refreshControl.isRefreshing){
            [self.refreshControl endRefreshing];
            self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"下拉刷新"];
        }

        if (err) {
            page=oldPage;
            hud.mode=MBProgressHUDModeText;
            hud.labelText=@"读取失败";
            NSLog(@"%@",err);
            [hud hide:YES afterDelay:1];
        }else{
            data=result;
            [self.navigationItem setTitle:[NSString stringWithFormat:@"%@(%ld/%@)",self.name,page,[[data lastObject] objectForKey:@"pages"]]];
            if (data.count==0) {
                isLast=YES;
            }else{
                isLast=[[[data objectAtIndex:0] objectForKey:@"nextpage"] isEqualToString:@"false"];
            }
            [self.buttonForward setEnabled:!isLast];
            [hud hide:NO];
            [self.tableView reloadData];
            if (data.count!=0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];                
            }
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return tableView==self.tableView? data.count:searchResult.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *one;
    if (tableView==self.tableView) {
        one=[data objectAtIndex:indexPath.row];
    }else{
        one=[searchResult objectAtIndex:indexPath.row];
    }
    
    ListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"list"];
    NSString *text=[one objectForKey:@"text"];
    NSInteger count=0;
    if([[one objectForKey:@"extr"] integerValue]==1){
        text=[@"[精]" stringByAppendingString:text];
        count+=3;
    }
    if([[one objectForKey:@"top"] integerValue]==1){
        text=[@"[顶]" stringByAppendingString:text];
        count+=3;
    }
    if([[one objectForKey:@"lock"] integerValue]==1){
        text=[@"[锁]" stringByAppendingString:text];
        count+=3;
    }
    NSMutableAttributedString *attr=[[NSMutableAttributedString alloc] initWithString:text];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, count)];
//    cell.titleText.text=[one objectForKey:@"text"];
    cell.titleText.attributedText=attr;
    cell.authorText.text=[[one objectForKey:@"author"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    cell.timeText.text=[one objectForKey:@"time"];
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest=[[segue.destinationViewController viewControllers] firstObject];
        dest.navigationTitle=@"发表新帖";
        dest.b=self.b;
    }else{
        ContentViewController *dest=segue.destinationViewController;
        dest.b=self.b;
        NSDictionary *one;
        NSArray *sourceArray;
        NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:(UITableViewCell *)sender];
        if (indexPath != nil)
        {
            sourceArray = searchResult;
        }
        else
        {
            indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
            sourceArray = data;
        }
        one=[sourceArray objectAtIndex:indexPath.row];
        dest.see=[one objectForKey:@"tid"];
        dest.title=[[data objectAtIndex:[self.tableView indexPathForSelectedRow].row] objectForKey:@"text"];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)back:(id)sender {
    [self jumpTo:page-1];
}

- (IBAction)forward:(id)sender {
    [self jumpTo:page+1];
}

- (IBAction)compose:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }

    [self performSegueWithIdentifier:@"compose" sender:nil];
}
- (IBAction)jump:(id)sender {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[[data lastObject] objectForKey:@"pages"]] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"好", nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType=UIKeyboardTypeNumberPad;
    [alert show];
    
}

- (IBAction)longPress:(UILongPressGestureRecognizer*)sender {
    if(sender.state == UIGestureRecognizerStateBegan){
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if(indexPath == nil) return ;
        selectedRow=indexPath.row;
        
        UIActionSheet *action=[[UIActionSheet alloc] init];
        action.title=@"选择操作";
        NSDictionary *info=[data objectAtIndex:selectedRow];

        if ([[info objectForKey:@"extr"] integerValue]==1) {
            [action addButtonWithTitle:@"取消加精"];
        }else{
            [action addButtonWithTitle:@"加精"];
        }
        if ([[info objectForKey:@"top"] integerValue]==1) {
            [action addButtonWithTitle:@"取消置顶"];
        }else{
            [action addButtonWithTitle:@"置顶"];
        }
        if ([[info objectForKey:@"lock"] integerValue]==1) {
            [action addButtonWithTitle:@"取消锁定"];
        }else{
            [action addButtonWithTitle:@"锁定"];
        }
        [action addButtonWithTitle:@"删除"];
        [action addButtonWithTitle:@"取消"];

        [action setCancelButtonIndex:4];
        [action setDestructiveButtonIndex:3];
        [action setDelegate:self];
        [action showInView:self.view];
        
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    NSMutableDictionary *args=[NSMutableDictionary dictionaryWithObjectsAndKeys:[[data objectAtIndex:selectedRow] objectForKey:@"bid"],@"bid",[[data objectAtIndex:selectedRow] objectForKey:@"tid"],@"tid", nil];
    if (buttonIndex==0) {
        [args setObject:@"extr" forKey:@"method"];
    }else if (buttonIndex==1){
        [args setObject:@"top" forKey:@"method"];
    }else if (buttonIndex==2){
        [args setObject:@"lock" forKey:@"method"];
    }
    performer=[[ActionPerformer alloc] init];
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText=@"正在操作";
    [hud show:YES];
    if (buttonIndex==3) {
        [performer performActionWithDictionary:args toURL:@"delete" withBlock:^(NSArray *result, NSError *err) {
            if ([[result.firstObject objectForKey:@"code"]integerValue]==0) {
                hud.labelText=@"成功";
                hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                hud.mode=MBProgressHUDModeCustomView;
                [hud hide:YES afterDelay:0.5];
                [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
            }else{
                hud.labelText=[result.firstObject objectForKey:@"msg"];
                hud.mode=MBProgressHUDModeText;
                [hud hide:YES afterDelay:0.5];
            }
        }];
    }else{
        [performer performActionWithDictionary:args toURL:@"action" withBlock:^(NSArray *result, NSError *err) {
            if ([[result.firstObject objectForKey:@"code"]integerValue]==0) {
                hud.labelText=@"成功";
                hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                hud.mode=MBProgressHUDModeCustomView;
                [hud hide:YES afterDelay:0.5];
                [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
            }else{
                hud.labelText=[result.firstObject objectForKey:@"msg"];
                hud.mode=MBProgressHUDModeText;
                [hud hide:YES afterDelay:0.5];
            }
        }];
    }
}
- (void)refresh{
    [self jumpTo:page];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    NSString *pageip=[alertView textFieldAtIndex:0].text;
    NSInteger pagen=[pageip integerValue];
    if (pagen<=0||pagen>[[[data lastObject] objectForKey:@"pages"] integerValue]){
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"输入不合法" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    [self jumpTo:pagen];
}

@end
