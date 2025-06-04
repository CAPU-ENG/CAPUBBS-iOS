//
//  InternalLoginViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "InternalLoginViewController.h"
#import "LoginViewController.h"

@interface InternalLoginViewController ()

@end

@implementation InternalLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    performer = [[ActionPerformer alloc] init];
    performerLogout = [[ActionPerformer alloc] init];
    self.textUid.text = self.defaultUid;
    self.textPass.text = self.defaultPass;
    [self.buttonLogin.layer setCornerRadius:10.0];
    if (self.textUid.text.length == 0) {
        [self.textUid becomeFirstResponder];
    }
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (shouldPop == NO) {
        if (self.textUid.text.length > 0 && self.textPass.text.length > 0) {
            [self login:nil];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)didEndOnExit:(UITextField*)sender {
    [self.textPass becomeFirstResponder];
}

- (IBAction)login:(id)sender {
    [self.textPass resignFirstResponder];
    [self.textUid resignFirstResponder];
    NSString *uid = self.textUid.text;
    NSString *pass = self.textPass.text;
    if (uid.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"用户名不能为空"];
        [self.textUid becomeFirstResponder];
        return;
    }
    if (pass.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"密码不能为空"];
        [self.textPass becomeFirstResponder];
        return;
    }
    shouldPop = NO;
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = @"正在登录";
    [hud showAnimated:YES];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"username",[ActionPerformer md5:pass],@"password",@"ios",@"os",[ActionPerformer doDevicePlatform],@"device",[[UIDevice currentDevice] systemVersion],@"version",nil];
    [performer performActionWithDictionary:dict toURL:@"login" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.label.text = @"登录失败";
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
//            [self showAlertWithTitle:@"登录失败" message:[err localizedDescription]];
            return ;
        }
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            hud.label.text = @"登录成功";
        } else {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.label.text = @"登录失败";
        }
        hud.mode = MBProgressHUDModeCustomView;
        [hud hideAnimated:YES afterDelay:0.5];
        if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"1"]) {
            [self showAlertWithTitle:@"登录失败" message:@"密码错误！"];
            [self.textPass becomeFirstResponder];
            return ;
        } else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"2"]) {
            [self showAlertWithTitle:@"登录失败" message:@"用户名不存在！"];
            [self.textUid becomeFirstResponder];
            return ;
        } else if ([[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
            if ([UID length] > 0 && ![uid isEqualToString:UID]) { // 注销之前的账号
                [performerLogout performActionWithDictionary:nil toURL:@"logout" withBlock:^(NSArray *result, NSError *err) {}];
                NSLog(@"Logout - %@", UID);
            }
            [GROUP_DEFAULTS setObject:uid forKey:@"uid"];
            [GROUP_DEFAULTS setObject:pass forKey:@"pass"];
            [GROUP_DEFAULTS setObject:[[result objectAtIndex:0] objectForKey:@"token"] forKey:@"token"];
            [LoginViewController updateIDSaves];
            NSLog(@"Login - %@", uid);
            dispatch_main_async_safe(^{
                [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
            });
            [ActionPerformer checkPasswordLength];
            shouldPop = YES;
            [self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5];
        } else {
            [self showAlertWithTitle:@"登录失败" message:@"发生未知错误！"];
        }
    }];
}

@end
