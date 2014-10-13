//
//  ContentViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentCell.h"
#import "ActionPerformer.h"
#import "IPGetter.h"
#import "ComposeViewController.h"
#import "LzlViewController.h"
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface ContentViewController ()

@end

@implementation ContentViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    page=1;
    performer=[[ActionPerformer alloc] init];
    //self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"下拉刷新"];
    self.navigationItem.title=[NSString stringWithFormat:@"%@(第%ld页)",self.title,(long)page];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldRefresh:) name:@"shouldRefresh" object:nil];
    [self jumpTo:page];
    left=self.navigationItem.leftBarButtonItem;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    if(!self.navigationItem.rightBarButtonItem){
//        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    if (editing) {
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trash:)] animated:YES];
    }else{
        [self.navigationItem setLeftBarButtonItem:left animated:YES];
    }
}
-(void)trash:(id)sender{
    [[[UIAlertView alloc] initWithTitle:@"确认删除" message:@"真的要删除选中的楼层么？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"好", nil] show];
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete|UITableViewCellEditingStyleInsert;
}
-(void)shouldRefresh:(NSNotification*)sender{
    willScroll=YES;
    [self jumpTo:[[[data lastObject] objectForKey:@"pages"] integerValue]];
}
-(void)refreshControlValueChanged:(UIRefreshControl*)sender{
    self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"正在刷新"];
    [self jumpTo:page];
}
-(void)jumpTo:(NSInteger)pageNum{
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText=@"加载中";
    [hud show:YES];
    NSInteger oldPage=page;
    page=pageNum;
    self.buttonBack.enabled=page!=1;
    [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)pageNum],@"p",self.b,@"bid",self.see,@"tid", nil] toURL:@"show" withBlock:^(NSArray *result, NSError *err) {
        if(self.refreshControl.isRefreshing){
            [self.refreshControl endRefreshing];
            self.refreshControl.attributedTitle=[[NSAttributedString alloc] initWithString:@"下拉刷新"];
        }
        
        if (err) {
            page=oldPage;
            hud.mode=MBProgressHUDModeText;
            hud.labelText=@"加载失败";
            [hud hide:YES afterDelay:1];
        }else{
            data=result;
            if ([[result.firstObject objectForKey:@"code"] integerValue]!=-1&&[[result.firstObject objectForKey:@"code"] integerValue]!=0) {
                [[[UIAlertView alloc] initWithTitle:@"读取失败" message:[NSString stringWithFormat:@"%@, code:%@",[result.firstObject objectForKey:@"msg"],[result.firstObject objectForKey:@"code"]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                [hud hide:YES afterDelay:0.5];
                return ;
            }
            if (data.count==0) {
                [self.navigationItem setTitle:@"没有这个帖子"];
            }else{
                [self.navigationItem setTitle:[NSString stringWithFormat:@"%@(%ld/%@)",[data.firstObject objectForKey:@"title"],(long)page,[[data lastObject] objectForKey:@"pages"]]];
            }
            
            if (data.count==0) {
                isLast=YES;
            }else{
                isLast=[[[data objectAtIndex:0] objectForKey:@"nextpage"] isEqualToString:@"false"];
            }
            [self.buttonForward setEnabled:!isLast];
            [hud hide:NO];
            heights=[[NSMutableArray alloc] init];
            if (data.count!=0) {
                for (NSInteger i=0; i<data.count; i++) {
                    [heights addObject:@0];
                }
            }

            [self.tableView reloadData];
            if (data.count!=0) {
                if (willScroll) {
                    willScroll=NO;
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:data.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }else{
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
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
    return data.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (heights.count>=indexPath.row&&[[heights objectAtIndex:indexPath.row] floatValue]!=0) {
        return [[heights objectAtIndex:indexPath.row] floatValue]+64;
    }
    NSString *text = [[data objectAtIndex:[indexPath row]] objectForKey:@"text"];
    
    //下句中(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2)  表示显示内容的label的长度 ，20000.0f 表示允许label的最大高度
    CGSize constraint = CGSizeMake(self.view.frame.size.width - 15-20, 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = MAX(size.height, 44.0f);
    
    return height + 64;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"content" forIndexPath:indexPath];
    NSDictionary *dict=[data objectAtIndex:indexPath.row];
    cell.authorLabel.text=[dict objectForKey:@"author"];
    cell.dateLabel.text=[dict objectForKey:@"time"];

    cell.btlzl.tag=indexPath.row;
    [cell.btlzl setTitle:[NSString stringWithFormat:@"评论 (%@)",[dict objectForKey:@"lzl"]] forState:UIControlStateNormal];
    [cell.webView setTag:indexPath.row];
    
    [cell.webView setDelegate:self];
//    [cell.webView loadHTMLString:nil baseURL:nil];
    [cell.webView loadHTMLString:[self htmlStringWIthRespondString:[dict objectForKey:@"text"]] baseURL:[NSURL URLWithString:@"http://www.chexie.net/bbs/content/index.php"]];
    [cell.webView.scrollView setScrollEnabled:NO];
    cell.floorLabel.text=[NSString stringWithFormat:@"%@楼",[dict objectForKey:@"floor"]];
    // Configure the cell...
    
    return cell;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
//    NSMutableArray *newHeights=[[NSMutableArray alloc] init];
//    for (NSInteger i=0; i<data.count-1; i++) {
//        ContentCell *cell=(ContentCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
//        if(cell.webView){
//            [newHeights addObject:[cell.webView stringByEvaluatingJavaScriptFromString:@"document.height"]];
//        }else{
//            [newHeights addObject:[heights objectAtIndex:i]];
//        }
//    }
//    heights=newHeights;
    if([[heights objectAtIndex:webView.tag] integerValue]==0){
        [heights replaceObjectAtIndex:webView.tag withObject:[webView stringByEvaluatingJavaScriptFromString:@"document.height"]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:webView.tag inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    heights=[[NSMutableArray alloc] init];
    if (data.count!=0) {
        for (NSInteger i=0; i<data.count; i++) {
            [heights addObject:@0];
        }
    }
    [self.tableView reloadData];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"type=%d",navigationType);
    if (UIWebViewNavigationTypeOther==navigationType) {
        return YES;
    }else if (UIWebViewNavigationTypeLinkClicked==navigationType){
        NSString *path= request.URL.absoluteString;
        
        NSRegularExpression *regular=[NSRegularExpression regularExpressionWithPattern:@"((http://www.chexie.net)?/bbs|\\.\\.)(/content(/|/index.php)?\\?)(.+)" options:0 error:nil];
        NSArray *matchs=[regular matchesInString:path options:0 range:NSMakeRange(0, path.length)];
        if (matchs.count!=0) {
            NSTextCheckingResult *result=matchs.firstObject;
            NSString *getstr=[path substringWithRange:[result rangeAtIndex:5]];
            NSString *bid=[getstr substringWithRange:[[[NSRegularExpression regularExpressionWithPattern:@"(bid=)([^&]+)" options:0 error:nil] matchesInString:getstr options:0 range:NSMakeRange(0, getstr.length)].firstObject rangeAtIndex:2]];
            NSString *tid=[getstr substringWithRange:[[[NSRegularExpression regularExpressionWithPattern:@"(tid=)([^&]+)" options:0 error:nil] matchesInString:getstr options:0 range:NSMakeRange(0, getstr.length)].firstObject rangeAtIndex:2]];
            ContentViewController *next=[self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            next.b=bid;
            next.see=tid;
            [self.navigationController pushViewController:next animated:YES];
            return NO;
        }
        
        regular=[NSRegularExpression regularExpressionWithPattern:@"((http://www.chexie.net)?/cgi-bin/bbs.pl\\?)(.+)" options:0 error:nil];
        matchs=[regular matchesInString:path options:0 range:NSMakeRange(0, path.length)];
        if (matchs.count!=0) {
            NSTextCheckingResult *result=matchs.firstObject;
            NSString *getstr=[path substringWithRange:[result rangeAtIndex:3]];
            NSString *bid=[getstr substringWithRange:[[[NSRegularExpression regularExpressionWithPattern:@"(b=)([^&]+)" options:0 error:nil] matchesInString:getstr options:0 range:NSMakeRange(0, getstr.length)].firstObject rangeAtIndex:2]];
            NSString *tid=[getstr substringWithRange:[[[NSRegularExpression regularExpressionWithPattern:@"(see=)([^&]+)" options:0 error:nil] matchesInString:getstr options:0 range:NSMakeRange(0, getstr.length)].firstObject rangeAtIndex:2]];
            NSString *oldbid=[getstr substringWithRange:[[[NSRegularExpression regularExpressionWithPattern:@"(id=)([^&]+)" options:0 error:nil] matchesInString:getstr options:0 range:NSMakeRange(0, getstr.length)].firstObject rangeAtIndex:2]];

            NSDictionary *trans=@{@"act":@1,@"capu":@2,@"bike":@3,@"water":@4,@"acad":@5,@"asso":@6,@"skill":@7,@"race":@9,@"web":@28};

            if (oldbid&&oldbid.length!=0) {
                bid=[trans objectForKey:oldbid];
            }
            ContentViewController *next=[self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            tid=[NSString stringWithFormat:@"%d",[self transsee:tid]];
            next.b=bid;
            next.see=tid;
            [self.navigationController pushViewController:next animated:YES];
            return NO;
        }
        
        temppath=path;
        [[[UIAlertView alloc] initWithTitle:@"打开链接" message:path delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"打开链接", nil]show];

        
    }
    return YES;
}

-(NSInteger)transsee:(NSString *)see{
    NSInteger count=0;
    for (NSInteger i=0; i<see.length; i++) {
        unsigned int one= [see characterAtIndex:see.length-1-i]-'a';
        count+=one*pow(26, i);
    }
    count++;
    return count;
}
-(NSString*)htmlStringWIthRespondString:(NSString*)respondString{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"nopic"] boolValue]&&[[IPGetter getIPAddress] isEqualToString:@"error"]) {
        NSRegularExpression *regexp=[NSRegularExpression regularExpressionWithPattern:@"(<img[^>]+?src=['\"])(.+?)(['\"].*?>)" options:0 error:nil];
        NSMutableString *result=[NSMutableString stringWithString:respondString];
        NSArray *matches=[regexp matchesInString:result options:0 range:NSMakeRange(0, result.length)];
        NSRegularExpression *expression=[NSRegularExpression regularExpressionWithPattern:@"bbsimg/(expr/)?[^/]+$" options:0 error:nil];
        for (NSInteger i=0; i<matches.count; i++) {
            NSTextCheckingResult *one=[matches objectAtIndex:i];
            NSString *nowstr=[respondString substringWithRange:[one rangeAtIndex:2]];
            if ([expression matchesInString:nowstr options:0 range:NSMakeRange(0, nowstr.length)].count==0) {
                [regexp replaceMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@"$1http://www.baidu.com/img/bdlogo.png$3"];
            }
        }
        
        respondString=[NSString stringWithString:result];
    }
    return [@"<style type='text/css'>img{max-width:100%}</style>" stringByAppendingString:[respondString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"]];
    
    
    
    NSRegularExpression *regexp=[NSRegularExpression regularExpressionWithPattern:@"(\\[img])(.+?)(\\[/img])" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *matches=[regexp matchesInString:respondString options:0 range:NSMakeRange(0, respondString.length)];
    while (matches.count>0) {
        NSTextCheckingResult *result=[matches firstObject];
        NSString *check=@"/bbsimg/";
        NSString *newString;
        NSString *src=[respondString substringWithRange:[result rangeAtIndex:2]];
        if (src.length>8&&[[src substringToIndex:check.length] isEqualToString:check]) {
            newString=[NSString stringWithFormat:@"<img src='%@'/>",src];
        }else{
            if (isPad) {
                newString=[NSString stringWithFormat:@"<p align='center'><img src='%@' width='%d'/></p>",src,((self.view.frame.size.width-80>600)?600:(int)self.view.frame.size.width-80)];
            }else{
                newString=[NSString stringWithFormat:@"<p align='center'><img src='%@' width='%f'/></p>",src,self.view.frame.size.width-80];
            }
        }
        respondString=[respondString stringByReplacingCharactersInRange:result.range withString:newString];
        matches=[regexp matchesInString:respondString options:0 range:NSMakeRange(0, respondString.length)];
    }
    
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
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    if ([actionSheet.title isEqualToString:@"选择操作"]) {
        if (buttonIndex==0) {
            NSString *content=[[data objectAtIndex:selectedRow] objectForKey:@"text"];
            if (content.length>30) {
                content=[[content substringToIndex:30] stringByAppendingString:@"…"];
            }
            defaultContent=[NSString stringWithFormat:@"[quote=%@]%@[/quote]\n",[[data objectAtIndex:selectedRow] objectForKey:@"author"],content];
            defaultTitle=[NSString stringWithFormat:@"Re: %@",self.title];
            defaultNavi=@"发表回复";
            [self performSegueWithIdentifier:@"compose" sender:nil];
        }else if(buttonIndex==1){
            NSString *content=[[data objectAtIndex:selectedRow] objectForKey:@"text"];
            [[UIPasteboard generalPasteboard] setString:content];
        }else if (buttonIndex==2){
            NSDictionary *dict=[data objectAtIndex:selectedRow];
            defaultTitle=[[dict objectForKey:@"pid"] isEqualToString:@"1"]?self.title:[NSString stringWithFormat:@"Re: %@",self.title];
            defaultContent=[dict objectForKey:@"text"];
            defaultNavi=@"编辑帖子";
            isEdit=YES;
            [self performSegueWithIdentifier:@"compose" sender:nil];
        }else if (buttonIndex==3){
            UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:@"确认删除\n该操作不可恢复" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles: nil];
//            [action showInView:self.view];
            [action performSelector:@selector(showInView:) withObject:self.view afterDelay:0.5];
        }
    }else if([actionSheet.title isEqualToString:@"您确认举报该贴？"]){
        mfc=[[MFMailComposeViewController alloc] init];
        [self presentViewController:mfc animated:YES completion:nil];
        [mfc setSubject:@"CAPUBBS举报违规帖"];
        [mfc setMessageBody:[NSString stringWithFormat:@"我在帖子 <a href=\"http://www.chexie.net/bbs/content/?tid=%@&bid=%@\">http://http://www.chexie.net/bbs/content/?tid=%@&bid=%@</a> 中发现了违规内容，希望版主尽快处理。",self.see,self.b,self.see,self.b] isHTML:YES];
        [mfc setToRecipients:@[@"ckcz123@126.com"]];
        mfc.mailComposeDelegate=self;
    }else{
        NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
        if (!username) {
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return;
        }
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
        hud.labelText=@"正在删除";
        [hud show:YES];
        
        NSDictionary *dict;
        BOOL deleteAll=[[[data objectAtIndex:selectedRow] objectForKey:@"floor"] integerValue]==1&&data.count==1;
        if (deleteAll) {
            dict=[NSDictionary dictionaryWithObjectsAndKeys:self.b,@"bid",self.see,@"tid", nil];
        }else{
            dict=[NSDictionary dictionaryWithObjectsAndKeys:self.b,@"bid",self.see,@"tid",[[data objectAtIndex:selectedRow] objectForKey:@"floor"],@"pid", nil];
        }


        [performer performActionWithDictionary:dict toURL:@"delete" withBlock:^(NSArray *result, NSError *err) {
            if (err) {
                [hud hide:NO];
                [[[UIAlertView alloc] initWithTitle:@"错误" message:err.localizedDescription delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;

            }
            NSInteger back=[[[result firstObject] objectForKey:@"d"] integerValue];
            switch (back) {
                case 0:{
                    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                    hud.mode=MBProgressHUDModeCustomView;
                    hud.labelText=@"删除成功";
                    [hud hide:YES afterDelay:1];
                    if (deleteAll) {
                        [self performSelector:@selector(pop) withObject:nil afterDelay:1];
                        [[NSNotificationCenter defaultCenter] removeObserver:self];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldRefresh" object:nil userInfo:nil];
                    }else{
                        [self performSelector:@selector(refresh) withObject:nil afterDelay:1];
                    }
                }
                    break;
                case 1:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码错误，您可能在登录后修改过密码，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                case 2:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名不存在，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 3:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的账号被封禁，请联系管理员！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 4:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的操作过快，请稍后再试！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 5:{
                    [hud hide:NO];
                 [[[UIAlertView alloc] initWithTitle:@"错误" message:@"文章被锁定，无法回复！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 6:{
                    [hud hide:NO];
                  [[[UIAlertView alloc] initWithTitle:@"错误" message:@"内部错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 10:{
                    [hud hide:NO];
                   [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的权限不够，无法删除！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                default:{
                    [hud hide:NO];
                   [[[UIAlertView alloc] initWithTitle:@"错误" message:@"未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
            }

        }];
    }
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [mfc dismissViewControllerAnimated:YES completion:nil];
}
-(void)pop{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)refresh{
    [self jumpTo:page];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"compose"]) {
        ComposeViewController *dest=[[segue.destinationViewController viewControllers] firstObject];
        dest.navigationTitle=defaultNavi;
        dest.reply=self.see;
        dest.b=self.b;
        dest.defaultTitle=defaultTitle;
        dest.defaultContent=defaultContent;
        dest.isEdit=isEdit;

        if (selectedRow!=-1) {
            dest.floor=[NSString stringWithFormat:@"%d",[[[data objectAtIndex:selectedRow] objectForKey:@"pid"] integerValue]];            
        }
        
        defaultTitle=nil;
        defaultContent=nil;
        selectedRow=-1;
        isEdit=NO;
    }else if ([segue.identifier isEqualToString:@"lzl"]){
        LzlViewController *dest=segue.destinationViewController;
        dest.fid=[[data objectAtIndex:selectedRow] objectForKey:@"fid"];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


- (IBAction)jump:(id)sender {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"跳转页面" message:[NSString stringWithFormat:@"请输入页码(1-%@)",[[data lastObject] objectForKey:@"pages"]] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"好", nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType=UIKeyboardTypeNumberPad;
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:@"确认删除"]) {
        NSArray *selectedRows=[self.tableView indexPathsForSelectedRows];
        NSMutableString *str=[[NSMutableString alloc] init];
        for (NSInteger i=0; i<selectedRows.count; i++) {
            NSInteger temp=[[[data objectAtIndex:[[selectedRows objectAtIndex:i] row]] objectForKey:@"pid"] integerValue]-1;
            [str appendFormat:@"%d-",temp];
        }
        NSString *token=[[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
        if (!token) {
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return;
        }
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
        hud.labelText=@"正在删除";
        [hud show:YES];
        [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:self.b,@"bid",self.see,@"tid",[str substringToIndex:str.length-1],@"pid",nil] toURL:@"delete" withBlock:^(NSArray *result, NSError *err) {
            if (err) {
                [hud hide:NO];
                [[[UIAlertView alloc] initWithTitle:@"错误" message:err.localizedDescription delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
                
            }
            NSInteger back=[[[result firstObject] objectForKey:@"code"] integerValue];
            switch (back) {
                case 0:{
                    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                    hud.mode=MBProgressHUDModeCustomView;
                    hud.labelText=@"删除成功";
                    [hud hide:YES afterDelay:1];
                    [self.tableView setEditing:NO];
                    [self performSelector:@selector(refresh) withObject:nil afterDelay:1];
                }
                    break;
                case 1:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码错误，您可能在登录后修改过密码，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                case 2:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名不存在，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 3:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的账号被封禁，请联系管理员！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 4:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的操作过快，请稍后再试！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 5:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"文章被锁定，无法回复！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 6:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"内部错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                case 10:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的权限不够，无法删除！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
                    break;
                default:{
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    return;
                }
            }

        }];
    }else if([alertView.title isEqualToString:@"跳转页面"]){
        NSString *pageip=[alertView textFieldAtIndex:0].text;
        NSInteger pagen=[pageip integerValue];
        if (pagen<=0||pagen>[[[data lastObject] objectForKey:@"pages"] integerValue]){
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"输入不合法" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return;
        }
        [self jumpTo:pagen];
    }else if([alertView.title isEqualToString:@"打开链接"]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:temppath]];
    }
}

- (IBAction)compose:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    

    defaultTitle=[NSString stringWithFormat:@"Re: %@",self.title];
    defaultNavi=@"发表回复";
    [self performSegueWithIdentifier:@"compose" sender:nil];
}

- (IBAction)back:(id)sender {
    [self jumpTo:page-1];
}

- (IBAction)forward:(id)sender {
    [self jumpTo:page+1];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)report:(id)sender {
    UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:@"您确认举报该贴？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"举报" otherButtonTitles: nil] ;
    [action showFromBarButtonItem:sender animated:YES];
}

- (IBAction)longPressPid:(UILongPressGestureRecognizer*)sender {
    if(sender.state == UIGestureRecognizerStateBegan){
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if(indexPath == nil) return ;
        selectedRow=indexPath.row;
        UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:@"选择操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"引用",@"复制",@"编辑",@"删除" ,nil];
        [action setDestructiveButtonIndex:3];
        [action showInView:self.view];

    }
}

- (IBAction)gotolzl:(UIButton*)sender {
    selectedRow=sender.tag;
    [self performSegueWithIdentifier:@"lzl" sender:nil];

}

@end

