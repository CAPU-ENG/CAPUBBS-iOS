//
//  RegisterViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "RegisterViewController.h"
#import "ActionPerformer.h"
#import <CommonCrypto/CommonCrypto.h>

@interface RegisterViewController ()

@end

@implementation RegisterViewController

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
    performer=[[ActionPerformer alloc] init];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    NSString *uid=self.textUid.text;
    NSString *pass=self.textPsd.text;
    NSString *pass1=self.textPsdSure.text;
    NSString *sex=self.segmentSex.selectedSegmentIndex==0?@"m":@"f";
    NSString *qq=self.textQQ.text;
    NSString *email=self.textEMail.text;
    NSString *from=self.textFrom.text;
    NSString *intro=self.textIntro.text;
    NSString *sig=self.textSig.text;
    NSString *code=self.textCode.text;
    if (uid.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写用户名" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil]show];
        firstResp=self.textUid;
        return;
    }
    if (pass.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写密码" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil]show];
        firstResp=self.textPsd;
        return;
    }
    if (![pass isEqualToString:pass1]) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"两次密码填写不一致" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil]show];
        firstResp=self.textPsd;
        return;
    }
    if (code.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写注册码！注册码由CAPU颁发" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil]show];
        firstResp=self.textPsd;
        return;
    }

    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    [hud show:YES];
    hud.labelText=@"注册中";
    [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:uid,@"username",[self md5:pass],@"password",sex,@"sex",qq,@"qq",email,@"mail",from,@"from",intro,@"intro",sig,@"sig",code,@"code",@"ios",@"os",[UIDevice currentDevice].model,@"device",[[UIDevice currentDevice] systemVersion],@"version", nil] toURL:@"register" withBlock:^(NSArray *result, NSError *err) {
        switch ([[[result firstObject] objectForKey:@"code"] integerValue]) {
            case 0:
                hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                hud.mode=MBProgressHUDModeCustomView;
                [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"uid"];
                [[NSUserDefaults standardUserDefaults] setObject:pass forKey:@"pass"];
                [[NSUserDefaults standardUserDefaults] setObject:[result.firstObject objectForKey:@"token"] forKey:@"token"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshUser" object:nil userInfo:nil];
                [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
                [hud hide:YES afterDelay:1];
                break;
            case 8:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名含有非法字符！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                [hud hide:NO];
                break;
            }
            case 9:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名已经存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                [hud hide:NO];
                break;
            }
            default:
                break;
        }
    }];
}

-(NSString*) md5:(NSString*) str {
    
    const char *cStr = [str UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5( cStr, strlen(cStr), result );
    
    return [NSString stringWithFormat:
            
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            
            result[0], result[1], result[2], result[3],
            
            result[4], result[5], result[6], result[7],
            
            result[8], result[9], result[10], result[11],
            
            result[12], result[13], result[14], result[15]
            
            ];
    
}

-(void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [firstResp becomeFirstResponder];
}
- (IBAction)didEndOnExit:(id)sender {
    [sender resignFirstResponder];
}
@end
