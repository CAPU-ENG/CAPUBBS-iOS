//
//  LoginViewControllerInternal.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LoginViewControllerInternal.h"
#import "ActionPerformer.h"
#import <CommonCrypto/CommonCrypto.h>

@interface LoginViewControllerInternal ()

@end

@implementation LoginViewControllerInternal

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    performer=[[ActionPerformer alloc] init];
    [self.textUid becomeFirstResponder];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)didEndOnExit:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)login:(id)sender {
    [self.textPass resignFirstResponder];
    [self.textUid resignFirstResponder];
    NSString *uid=self.textUid.text;
    NSString *pass=self.textPass.text;
    if (uid.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    if (pass.length==0&&NO) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    hud=[[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText=@"正在登陆";
    [hud show:YES];
    [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:uid,@"username",[self md5:pass],@"password", nil] toURL:@"login" withBlock:^(NSArray *result, NSError *err) {
        [hud hide:YES];
        if (err) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return ;
        }
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"密码错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return ;
        }else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"2"]){
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"用户名不存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return ;
        }else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]){
            [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"uid"];
            [[NSUserDefaults standardUserDefaults] setObject:pass forKey:@"pass"];
            [self dismissViewControllerAnimated:YES completion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"userChanged" object:nil userInfo:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"密码错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return ;
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

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
