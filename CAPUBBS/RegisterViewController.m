//
//  RegisterViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "RegisterViewController.h"
#import "ContentViewController.h"
#import "IconViewController.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    performer = [[ActionPerformer alloc] init];
    performerPsd = [[ActionPerformer alloc] init];
    [NOTIFICATION addObserver:self selector:@selector(setUserIcon:) name:@"selectIcon" object:nil];
    [self.labelUidGuide setTextColor:BLUE];
    
    for (UITextView *view in @[self.textIntro, self.textSig, self.textSig2, self.textSig3]) {
        [view.layer setCornerRadius:6.0];
        [view.layer setBorderColor:[UIColor colorWithWhite:0 alpha:0.2].CGColor];
        [view.layer setBorderWidth:0.5];
        [view setScrollsToTop:NO];
    }
    [self.icon setRounded:YES];
    if (self.isEdit == YES) {
        self.title = @"修改个人信息";
        [self.imageUidAvailable setImage:SUCCESSMARK];
        [self setDefaultValue];
    } else {
        iconURL = [NSString stringWithFormat:@"%@/bbsimg/icons/%@", CHEXIE, ICON_NAMES[arc4random() % [ICON_NAMES count]]];
        [self.icon setUrl:iconURL];
        [self editingDidEnd:self.textUid];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)setDefaultValue {
    NSDictionary *dict = USERINFO;
    NSMutableAttributedString *uid = [[NSMutableAttributedString alloc] initWithString:dict[@"username"]];
    [uid addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(0, uid.length)];
    self.textUid.attributedText = uid;
    self.textUid.userInteractionEnabled = NO;
    [self.labelUidGuide setText:@"用户名一经注册无法更改"];
    [self.labelUidGuide setTextColor:[UIColor darkGrayColor]];
    self.cellUidGuide.userInteractionEnabled = NO;
    self.cellUidGuide.accessoryType = UITableViewCellAccessoryNone;
    self.labelPsdGuide.text = @"新密码：";
    self.textPsd.placeholder = @"不换则不必填写";
    iconURL = dict[@"icon"];
    [self.icon setUrl:iconURL];
    if ([dict[@"sex"] isEqualToString:@"男"]) {
        self.segmentSex.selectedSegmentIndex = 1;
    } else if ([dict[@"sex"] isEqualToString:@"女"]) {
        self.segmentSex.selectedSegmentIndex = 2;
    } else {
        self.segmentSex.selectedSegmentIndex = 0;
    }
    if (![dict[@"mail"] isEqualToString:@"Array"]) {
        self.textEmail.text = dict[@"mail"];
    }
    if (![dict[@"qq"] isEqualToString:@"Array"]) {
        self.textQQ.text = dict[@"qq"];
    }
    if (![dict[@"place"] isEqualToString:@"Array"]) {
        self.textFrom.text = dict[@"place"];
    }
    if (![dict[@"hobby"] isEqualToString:@"Array"]) {
        self.textHobby.text = dict[@"hobby"];
    }
    if (![dict[@"intro"] isEqualToString:@"Array"]) {
        self.textIntro.text = dict[@"intro"];
    }
    if (![dict[@"sig1"] isEqualToString:@"Array"]) {
        self.textSig.text = dict[@"sig1"];
    }
    if (![dict[@"sig2"] isEqualToString:@"Array"]) {
        self.textSig2.text = dict[@"sig2"];
    }
    if (![dict[@"sig3"] isEqualToString:@"Array"]) {
        self.textSig3.text = dict[@"sig3"];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUserIcon:(NSNotification *)notification{
    dispatch_main_async_safe(^{
        iconURL = [notification.userInfo objectForKey:@"URL"];
        [self.icon setUrl:iconURL];
    });
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    NSString *uid = self.textUid.text;
    NSString *pass = self.textPsd.text;
    NSString *pass1 = self.textPsdSure.text;
    NSString *email = self.textEmail.text;
    NSString *sex = [self.segmentSex titleForSegmentAtIndex:self.segmentSex.selectedSegmentIndex];
    NSString *qq = self.textQQ.text;
    NSString *from = self.textFrom.text;
    NSString *intro = self.textIntro.text;
    NSString *hobby = self.textHobby.text;
    NSString *sig = self.textSig.text;
    NSString *sig2 = self.textSig2.text;
    NSString *sig3 = self.textSig3.text;
    //NSString *code = self.textCode.text;
    if (self.isEdit == NO) {
        if (uid.length == 0) {
            [self showAlertWithTitle:@"错误" message:@"请填写用户名！" cancelAction:^(UIAlertAction *action) {
                [self.textUid becomeFirstResponder];
            }];
            return;
        }
        if (pass.length == 0) {
            [self showAlertWithTitle:@"错误" message:@"请填写密码！" cancelAction:^(UIAlertAction *action) {
                [self.textPsd becomeFirstResponder];
            }];
            return;
        }
    }
    if (pass.length > 0 && pass.length < 6) {
        [self showAlertWithTitle:@"错误" message:@"密码过于简单，至少为六位！" cancelAction:^(UIAlertAction *action) {
            [self.textPsd becomeFirstResponder];
        }];
        return;
    }
    if (![pass1 isEqualToString:pass]) {
        [self showAlertWithTitle:@"错误" message:@"两次密码填写不一致！" cancelAction:^(UIAlertAction *action) {
            [self.textPsdSure becomeFirstResponder];
        }];
        return;
    }
//    if (email.length == 0) {
//        [self showAlertWithTitle:@"错误" message:@"请填写邮箱！" cancelAction:^(UIAlertAction *action) {
//            [self.textEmail becomeFirstResponder];
//        }];
//        return;
//    }
    if (email.length > 0 && [self isValidateEmail:email] == NO) {
        [self showAlertWithTitle:@"错误" message:@"邮箱格式错误！" cancelAction:^(UIAlertAction *action) {
            [self.textEmail becomeFirstResponder];
        }];
        return;
    }
    if (qq.length > 0 && [self isValidQQ:qq] == NO) {
        [self showAlertWithTitle:@"错误" message:@"QQ格式错误！" cancelAction:^(UIAlertAction *action) {
            [self.textQQ becomeFirstResponder];
        }];
        return;
    }
//    if (code.length == 0) {
//        [self showAlertWithTitle:@"错误" message:@"请填写注册码！" cancelAction:^(UIAlertAction *action) {
//            [self.textCode becomeFirstResponder];
//        }];
//        return;
//    }
    if ([self getByte:hobby] > 500) {
        [self showAlertWithTitle:@"错误" message:@"爱好过长，不能超过500字节！" cancelAction:^(UIAlertAction *action) {
            [self.textHobby becomeFirstResponder];
        }];
        return;
    }
    if ([self getByte:intro] > 1000) {
        [self showAlertWithTitle:@"错误" message:@"个人简介过长，不能超过1000字节！" cancelAction:^(UIAlertAction *action) {
            [self.textIntro becomeFirstResponder];
        }];
        return;
    }
    if ([self getByte:sig] > 1000) {
        [self showAlertWithTitle:@"错误" message:@"签名档1过长，不能超过1000字节！" cancelAction:^(UIAlertAction *action) {
            [self.textSig becomeFirstResponder];
        }];
        return;
    }
    if ([self getByte:sig2] > 1000) {
        [self showAlertWithTitle:@"错误" message:@"签名档2过长，不能超过1000字节！" cancelAction:^(UIAlertAction *action) {
            [self.textSig2 becomeFirstResponder];
        }];
        return;
    }
    if ([self getByte:sig3] > 1000) {
        [self showAlertWithTitle:@"错误" message:@"签名档3过长，不能超过1000字节！" cancelAction:^(UIAlertAction *action) {
            [self.textSig3 becomeFirstResponder];
        }];
        return;
    }
    NSDictionary *dict = @{
        @"username" : uid,
        @"password" : [ActionPerformer md5:pass],
        @"sex" : sex,
        @"qq" : qq,
        @"mail" : email,
        @"icon" : iconURL,
        @"from" : from,
        @"intro" : intro,
        @"hobby" : hobby,
        @"sig" : sig,
        @"sig2" : sig2,
        @"sig3" : sig3,
    };
    if (self.isEdit == NO) {
        [hud showWithProgressMessage:@"注册中"];
        [performer performActionWithDictionary:dict toURL:@"register" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [self showAlertWithTitle:@"注册失败" message:[err localizedDescription]];
                [hud hideWithFailureMessage:@"注册失败"];
                return;
            }
            if ([result[0][@"code"] integerValue] == 0) {
                [hud hideWithSuccessMessage:@"注册成功"];
            } else {
                [hud hideWithFailureMessage:@"注册失败"];
            }
            switch ([result[0][@"code"] integerValue]) {
                case 0: {
                    [GROUP_DEFAULTS setObject:uid forKey:@"uid"];
                    [GROUP_DEFAULTS setObject:pass forKey:@"pass"];
                    [GROUP_DEFAULTS setObject:result[0][@"token"] forKey:@"token"];
                    [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.5];
                    break;
                }
                case 6:{
                    [self showAlertWithTitle:@"注册失败" message:@"数据库错误！"];
                    break;
                }
                case 8:{
                    [self showAlertWithTitle:@"注册失败" message:@"用户名含有非法字符！" cancelAction:^(UIAlertAction *action) {
                        [self.textUid becomeFirstResponder];
                    }];
                    break;
                }
                case 9:{
                    [self showAlertWithTitle:@"注册失败" message:@"用户名已经存在！" cancelAction:^(UIAlertAction *action) {
                        [self.textUid becomeFirstResponder];
                    }];
                    break;
                }
                default:
                {
                    [self showAlertWithTitle:@"注册失败" message:@"发生未知错误！"];
                    break;
                }
            }
        }];
    } else {
        [hud showWithProgressMessage:@"修改中"];
        [performer performActionWithDictionary:dict toURL:@"edituser" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [self showAlertWithTitle:@"修改失败" message:[err localizedDescription]];
                [hud hideWithFailureMessage:@"修改失败"];
                return;
            }
            if ([result[0][@"code"] integerValue] == 0) {
                [hud hideWithSuccessMessage:@"修改成功"];
            } else {
                [hud hideWithFailureMessage:@"修改失败"];
            }
            
            switch ([result[0][@"code"] integerValue]) {
                case 0: {
                    if (self.textPsd.text.length > 0) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"验证密码" message:@"您选择了修改密码\n请输入原密码以验证身份" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                            textField.placeholder = @"原密码";
                            textField.secureTextEntry = YES;
                        }];
                        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                            [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            NSString *oldPassword = alert.textFields.firstObject.text;
                            [self changePasswordWithOldPassword:oldPassword];
                        }]];
                        [self presentViewControllerSafe:alert];
                    } else {
                        [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
                    }
                    break;
                }
                case 1:{
                    [self showAlertWithTitle:@"修改个人信息失败" message:result[0][@"msg"]];
                    break;
                }
                default:
                {
                    [self showAlertWithTitle:@"修改个人信息失败" message:@"发生未知错误！"];
                    break;
                }
            }
        }];
    }
}

- (void)dismiss {
    dispatch_main_async_safe(^{
        [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
    });
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)back {
    [NOTIFICATION postNotificationName:@"userUpdated" object:nil userInfo:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword {
    [hud showWithProgressMessage:@"修改中"];
    NSDictionary *dict = @{
        @"old" : [ActionPerformer md5:oldPassword],
        @"new" : [ActionPerformer md5:self.textPsd.text]
    };
    [performerPsd performActionWithDictionary:dict toURL:@"changepsd" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            [self showAlertWithTitle:@"修改失败" message:[err localizedDescription]];
            [hud hideWithFailureMessage:@"修改失败"];
            return;
        }
        if ([result[0][@"code"] integerValue] == 0) {
            [hud hideWithSuccessMessage:@"修改成功"];
        } else {
            [hud hideWithFailureMessage:@"修改失败"];
        }
        
        switch ([result[0][@"code"] integerValue]) {
            case 0: {
                [GROUP_DEFAULTS setObject:self.textPsd.text forKey:@"pass"];
                [GROUP_DEFAULTS setObject:result[0][@"msg"] forKey:@"token"];
                [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
                break;
            }
            case 1:{
                [self showAlertWithTitle:@"修改密码失败" message:@"登录超时，请重新登录！"];
                break;
            }
            case 2:{
                [self showAlertWithTitle:@"修改密码失败" message:@"旧密码错误！"];
                break;
            }
            case 3:{
                [self showAlertWithTitle:@"修改密码失败" message:@"数据库错误！"];
                break;
            }
            default:
            {
                [self showAlertWithTitle:@"修改密码失败" message:@"发生未知错误！"];
                break;
            }
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)uidDidEndOnExit:(UITextField *)sender {
    [self.textPsd becomeFirstResponder];
}

- (IBAction)editingDidEnd:(UITextField *)sender {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (sender.text.length == 0) {
        [self.imageUidAvailable setImage:QUESTIONMARK];
        return;
    }
    [performer performActionWithDictionary:@{@"uid":sender.text} toURL:@"userinfo" withBlock:^(NSArray *result, NSError *err) {
        // NSLog(@"%@", result);
        if (err || result.count == 0 || [result[0][@"username"] length] == 0) {
            [self.imageUidAvailable setImage:SUCCESSMARK];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        } else {
            [self.imageUidAvailable setImage:FAILMARK];
            [self.labelUidGuide setText:@"该ID已经存在！"];
            [self.labelUidGuide setTextColor:[UIColor redColor]];
            [self.labelUidGuide performSelector:@selector(setText:) withObject:@"如何才能取一个好的ID？" afterDelay:1.0];
            [self.labelUidGuide performSelector:@selector(setTextColor:) withObject:BLUE afterDelay:1.0];
        }
    }];
}

- (IBAction)passDidEndOnExit:(id)sender {
    [self.textPsdSure becomeFirstResponder];
}

- (IBAction)pass1didEndOnExit:(id)sender {
    [sender resignFirstResponder];
}

- (BOOL)string:(NSString *)string passRegex:(NSString *)regex {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex] evaluateWithObject:string];
}

- (BOOL)isValidateEmail:(NSString *)email {
    return [self string:email passRegex:@"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"];
}

- (BOOL)isValidQQ:(NSString *)qq {
    return [self string:qq passRegex:@"^[1-9][0-9]{4,10}$"];
}

- (int)getByte:(NSString*)text {
    int bytes = 0;
    char *p = (char *)[text cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i = 0 ; i < [text lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ; i++) {
        if (*p) {
            p++;
            bytes++;
        } else {
            p++;
        }
    }
    return bytes;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"icon"]) {
        IconViewController *dest = [segue destinationViewController];
        dest.userIcon = iconURL;
    }
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        dest.bid = @"2";
        dest.tid = @"6205";
        dest.title = @"【新会员请猛戳】协会文化之——论坛ID";
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
