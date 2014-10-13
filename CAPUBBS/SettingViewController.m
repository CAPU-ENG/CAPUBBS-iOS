//
//  SettingViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "SettingViewController.h"
#import "ContentViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged:) name:@"userChanged" object:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]) {
        self.textUid.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
    }
    [self performSelector:@selector(setDefault) withObject:nil afterDelay:0.01];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)setDefault{
    [self.segmentProxy setSelectedSegmentIndex:[[[NSUserDefaults standardUserDefaults] objectForKey:@"proxy"] integerValue]];
    [self.switchPic setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"nopic"] boolValue]];
}

-(void)userChanged:(NSNotification*)noti{
    self.textUid.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]) {
                UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:@"确认注销" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"注销" otherButtonTitles: nil];
                [action showInView:self.navigationController.view];
            }else{
                [self performSegueWithIdentifier:@"login" sender:nil];
            }
        }
    }else if (indexPath.section==1){
        if (indexPath.row==1) {
            ContentViewController *content=[self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            content.b=@"4";
            content.see=@"17637";
            content.title=@"帮助";
            [self.navigationController pushViewController:content animated:YES];
        }else if (indexPath.row==2){
            //网页版
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.chexie.net/bbs"]];
        }else if (indexPath.row==3){
            mvc=[[MFMailComposeViewController alloc] init];
            mvc.mailComposeDelegate=self;
            [mvc setSubject:@"CAPUBBS for iOS反馈"];
            [mvc setToRecipients:@[@"capuclient@126.com"]];
            [self presentViewController:mvc animated:YES completion:nil];
        }else if (indexPath.row==4){
            [[[UIAlertView alloc] initWithTitle:@"关于本软件" message:@"CAPUBBS客户端 ver1.0\n更新时间 2014-2-21\n\n作者 I2  协助开发 维茨C\n论坛地址 http://www.chexie.net\n\nCopyright © 2014 Dian Xiong, Law School of Peking University, All rights reserved." delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        }
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"content"]) {
        ContentViewController *dest=[[segue.destinationViewController viewControllers] firstObject];
        dest.see=@"baci";
        dest.b=@"4";
        dest.title=@"CAPUBBS客户端 帮助与意见反馈";
    }
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [mvc dismissViewControllerAnimated:YES completion:nil];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"uid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pass"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
    self.textUid.text=@"尚未登录";
}
- (IBAction)proxyChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:self.segmentProxy.selectedSegmentIndex] forKey:@"proxy"];
}
- (IBAction)picChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.switchPic.isOn] forKey:@"nopic"];
}
@end
