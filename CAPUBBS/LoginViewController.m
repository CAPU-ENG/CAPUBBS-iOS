//
//  LoginViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LoginViewController.h"
#import "ActionPerformer.h"
#import "ContentViewController.h"
#import <CommonCrypto/CommonCrypto.h>
#include <sys/sysctl.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag==0) {
        if (buttonIndex==alertView.cancelButtonIndex) {
            exit(0);
            return;
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"hasShownEULA"];
        [self viewDidLoad];
    }else if(alertView.tag==1){
        if (buttonIndex==alertView.cancelButtonIndex) {
            return;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tempurl]];
    }
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"hasShownEULA"] boolValue]) {
        [[[UIAlertView alloc] initWithTitle:@"用户协议" message:@"请勿在本论坛中发布或展示任何形式的色情、暴力或其他违规信息" delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"同意", nil] show];
        return;
    }
    performer=[[ActionPerformer alloc] init];
    performerLink=[[ActionPerformer alloc] init];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]){
        self.textUid.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
        self.textPass.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"pass"];
        self.buttonEnter.hidden=YES;
        //        NSLog(@"%@,%d",[[NSUserDefaults standardUserDefaults] objectForKey:@"pass"],[[[NSUserDefaults standardUserDefaults] objectForKey:@"pass"] length]);
    }else{
//        [self.textUid becomeFirstResponder];
    }
    [self getLinkInformation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged:) name:@"refreshUser" object:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)getLinkInformation{
    [performerLink performActionWithDictionary:nil toURL:@"main" withBlock:^(NSArray *result, NSError *err) {
        if (err) {
            return ;
        }
        news=result;
        NSArray *buttons=@[self.link1,self.link2,self.link3,self.link4,self.link5,self.link6,self.link7,self.link8];
        NSDictionary *info=result.firstObject;
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        if (![app_Version isEqualToString:[info objectForKey:@"iosversion"]]) {
            tempurl=[info objectForKey:@"iosurl"];
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"发现新版本！" message:[NSString stringWithFormat:@"发现新版本%@，是否前往App Store升级？\n更新内容：%@",[info objectForKey:@"iosversion"],[info objectForKey:@"iostext"]] delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"好", nil];
            alert.tag=1;
            [alert show];
        }
        for (NSInteger i=1; i<result.count; i++) {
            NSDictionary *dict=[result objectAtIndex:i];
            UIButton *button=[buttons objectAtIndex:i];
            
            [button setTitle:[dict objectForKey:@"text"] forState:UIControlStateNormal];
            button.tag=i;
            [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
    }];
}
-(void)buttonTapped:(UIButton*)sender{
    NSDictionary *dict=[news objectAtIndex:sender.tag];
    b=[dict objectForKey:@"bid"];
    see=[dict objectForKey:@"tid"];
    title=[dict objectForKey:@"text"];
    ContentViewController *content=[self.storyboard instantiateViewControllerWithIdentifier:@"content"];
    navi=[[UINavigationController alloc] initWithRootViewController:content];
    content.b=b;
    content.see=see;
    content.title=title;
    content.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];
    [self presentViewController:navi animated:YES completion:nil];
//    [self performSegueWithIdentifier:@"content" sender:nil];
}
-(void)dismiss:(UIBarButtonItem*)sender{
    [navi dismissViewControllerAnimated:YES completion:nil];
}
-(NSString*)trans:(NSString*)input{
    NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"act",@"2",@"capu",@"3",@"bike",@"4",@"water",@"5",@"acad",@"6",@"skill",@"9",@"race", nil];
    return [dict objectForKey:input];
}
-(void)userChanged:(NSNotification*)noti{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]){
        self.textUid.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
        self.textPass.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"pass"];
    }else{
        [self.textUid becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"content"]) {
        ContentViewController *dest=[[segue.destinationViewController viewControllers] firstObject];
        dest.see=see;
        dest.b=b;
        dest.title=title;
    }
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
    [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:uid,@"username",[self md5:pass],@"password",@"ios",@"os",[self doDevicePlatform],@"device",[[UIDevice currentDevice] systemVersion],@"version", nil] toURL:@"login" withBlock:^(NSArray *result, NSError *err) {
//        NSLog(@"%@",result);
        [hud hide:NO];
        if (err) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            self.buttonEnter.hidden=NO;
            return ;
        }
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"密码错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            self.buttonEnter.hidden=NO;
            return ;
        }else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"2"]){
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"用户名不存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            self.buttonEnter.hidden=NO;
            return ;
        }else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]){
            [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"uid"];
            [[NSUserDefaults standardUserDefaults] setObject:pass forKey:@"pass"];
            [[NSUserDefaults standardUserDefaults] setObject:[[result objectAtIndex:0] objectForKey:@"token"] forKey:@"token"];
            [self performSegueWithIdentifier:@"main" sender:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"登录失败" message:@"发生了错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            self.buttonEnter.hidden=NO;
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

#define CHUNK_SIZE 1024

+(NSString *)file_md5:(NSString*) path {
    
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:path];
    
    if(handle == nil)
        
        return nil;
    
    CC_MD5_CTX md5_ctx;
    
    CC_MD5_Init(&md5_ctx);
    
    NSData* filedata;
    
    do {
        
        filedata = [handle readDataOfLength:CHUNK_SIZE];
        
        CC_MD5_Update(&md5_ctx, [filedata bytes], [filedata length]);
        
    }
    
    while([filedata length]);
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5_Final(result, &md5_ctx);
    
    [handle closeFile];
    
    return [NSString stringWithFormat:
            
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            
            result[0], result[1], result[2], result[3],
            
            result[4], result[5], result[6], result[7],
            
            result[8], result[9], result[10], result[11],
            
            result[12], result[13], result[14], result[15]
            
            ];
    
}

- (NSString*) doDevicePlatform
{
    size_t size;
    int nR = sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    nR = sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    NSLog(@"platform=%@",platform);
    return platform;
    
    if ([platform isEqualToString:@"iPhone1,1"]) {
        
        platform = @"iPhone";
        
    } else if ([platform isEqualToString:@"iPhone1,2"]) {
        
        platform = @"iPhone 3G";
        
    } else if ([platform isEqualToString:@"iPhone2,1"]) {
        
        platform = @"iPhone 3GS";
        
    } else if ([platform isEqualToString:@"iPhone3,1"]||[platform isEqualToString:@"iPhone3,2"]||[platform isEqualToString:@"iPhone3,3"]) {
        
        platform = @"iPhone 4";
        
    } else if ([platform isEqualToString:@"iPhone4,1"]) {
        
        platform = @"iPhone 4S";
        
    } else if ([platform isEqualToString:@"iPhone5,1"]||[platform isEqualToString:@"iPhone5,2"]) {
        
        platform = @"iPhone 5";
        
    }else if ([platform isEqualToString:@"iPhone5,3"]||[platform isEqualToString:@"iPhone5,4"]) {
        
        platform = @"iPhone 5C";
        
    }else if ([platform isEqualToString:@"iPhone6,2"]||[platform isEqualToString:@"iPhone6,1"]) {
        
        platform = @"iPhone 5S";
        
    }else if ([platform isEqualToString:@"iPhone7,2"]||[platform isEqualToString:@"iPhone7,1"]) {
        
        platform = @"iPhone 6";
        
    }else if ([platform isEqualToString:@"iPod4,1"]) {
        
        platform = @"iPod touch 4";
        
    }else if ([platform isEqualToString:@"iPod5,1"]) {
        
        platform = @"iPod touch 5";
        
    }else if ([platform isEqualToString:@"iPod3,1"]) {
        
        platform = @"iPod touch 3";
        
    }else if ([platform isEqualToString:@"iPod2,1"]) {
        
        platform = @"iPod touch 2";
        
    }else if ([platform isEqualToString:@"iPod1,1"]) {
        
        platform = @"iPod touch";
        
    }else if ([platform isEqualToString:@"iPad3,2"]||[platform isEqualToString:@"iPad3,1"]||[platform isEqualToString:@"iPad3,3"]||[platform isEqualToString:@"iPad3,4"]||[platform isEqualToString:@"iPad3,5"]||[platform isEqualToString:@"iPad3,6"]) {
        
        platform = @"iPad 3";
        
    }else if ([platform isEqualToString:@"iPad2,2"]||[platform isEqualToString:@"iPad2,1"]||[platform isEqualToString:@"iPad2,3"]||[platform isEqualToString:@"iPad2,4"]) {
        
        platform = @"iPad 2";
        
    }else if ([platform isEqualToString:@"iPad1,1"]) {
        
        platform = @"iPad 1";
        
    }else if ([platform isEqualToString:@"iPad2,5"]||[platform isEqualToString:@"iPad2,6"]||[platform isEqualToString:@"iPad2,7"]) {
        
        platform = @"ipad mini";
        
    }else if ([platform isEqualToString:@"iPad3,2"]||[platform isEqualToString:@"iPad3,1"]||[platform isEqualToString:@"iPad3,3"]||[platform isEqualToString:@"iPad3,4"]||[platform isEqualToString:@"iPad3,5"]||[platform isEqualToString:@"iPad3,6"]) {
        
        platform = @"iPad 3";
        
    }
    
    return platform;
}

- (IBAction)gotoMain:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"uid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pass"];
    [self performSegueWithIdentifier:@"main" sender:nil];
}

- (IBAction)didEndOnExit:(UITextField*)sender {
    [self.textPass becomeFirstResponder];
}
- (IBAction)enterPressed:(id)sender {
    [self login:nil];
}

@end
