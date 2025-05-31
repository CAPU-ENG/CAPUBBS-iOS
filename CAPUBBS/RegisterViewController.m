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

#define UID_GUIDE @"如何才能取一个好的ID？"
#define UID_WARNING @"该ID已经存在！"
#define UID_CHANGE_HINT @"用户名一经注册无法更改"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
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
        iconURL = [NSString stringWithFormat:@"%@/bbsimg/icons/%@", CHEXIE, [ICON_NAMES objectAtIndex:arc4random() % [ICON_NAMES count]]];
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
    [self.labelUidGuide setText:UID_CHANGE_HINT];
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
    self.textSig.text = [ContentViewController transFromHTML:[ContentViewController restoreFormat:dict[@"sig1"]]];
    self.textSig2.text = [ContentViewController transFromHTML:[ContentViewController restoreFormat:dict[@"sig2"]]];
    self.textSig3.text = [ContentViewController transFromHTML:[ContentViewController restoreFormat:dict[@"sig3"]]];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUserIcon:(NSNotification *)notification{
    iconURL = [notification.userInfo objectForKey:@"URL"];
    dispatch_main_async_safe(^{
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
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写用户名！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            firstResp = self.textUid;
            return;
        }
        if (pass.length == 0) {
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写密码！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            firstResp = self.textPsd;
            return;
        }
    }
    if (pass.length > 0 && pass.length < 6) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码过于简单，至少为六位！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textPsd;
        return;
    }
    if (![pass1 isEqualToString:pass]) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"两次密码填写不一致！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textPsdSure;
        return;
    }
//    if (email.length == 0) {
//        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写邮箱！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
//        firstResp = self.textEmail;
//        return;
//    }
    if (email.length > 0 && [RegisterViewController isValidateEmail:email] == NO) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"邮箱格式错误！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textEmail;
        return;
    }
    if (qq.length > 0 && [self isValidQQ:qq] == NO) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"QQ格式错误！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textQQ;
        return;
    }
//    if (code.length == 0) {
//        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请填写注册码！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
//        firstResp = self.textCode;
//        return;
//    }
    if ([self getByte:hobby] > 500) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"爱好过长，不能超过500字节！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textHobby;
        return;
    }
    if ([self getByte:sig] > 1000) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"签名档1过长，不能超过1000字节！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textSig;
        return;
    }
    if ([self getByte:sig2] > 1000) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"签名档2过长，不能超过1000字节！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textSig2;
        return;
    }
    if ([self getByte:sig3] > 1000) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"签名档3过长，不能超过1000字节！" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        firstResp = self.textSig3;
        return;
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:uid, @"username",[ActionPerformer md5:pass], @"password", sex, @"sex",qq,@"qq",email,@"mail",iconURL, @"icon", from, @"from", intro, @"intro", hobby, @"hobby", sig, @"sig", sig2, @"sig2", sig3, @"sig3", @"ios", @"os", [ActionPerformer doDevicePlatform], @"device", [[UIDevice currentDevice] systemVersion], @"version", nil];
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud showAnimated:YES];
    if (self.isEdit == NO) {
        hud.label.text = @"注册中";
        [performer performActionWithDictionary:dict toURL:@"register" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"注册失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"注册失败";
                hud.mode = MBProgressHUDModeCustomView;
                [hud hideAnimated:YES afterDelay:0.5];
                return;
            }
            if ([[[result firstObject] objectForKey:@"code"] integerValue] == 0) {
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                hud.label.text = @"注册成功";
            } else {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"注册失败";
            }
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
            switch ([[[result firstObject] objectForKey:@"code"] integerValue]) {
                case 0: {
                    [GROUP_DEFAULTS setObject:uid forKey:@"uid"];
                    [GROUP_DEFAULTS setObject:pass forKey:@"pass"];
                    [GROUP_DEFAULTS setObject:[result.firstObject objectForKey:@"token"] forKey:@"token"];
                    [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.5];
                    break;
                }
                case 6:{
                    [[[UIAlertView alloc] initWithTitle:@"注册失败" message:@"数据库错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
                case 8:{
                    [[[UIAlertView alloc] initWithTitle:@"注册失败" message:@"用户名含有非法字符！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    [self.textUid becomeFirstResponder];
                    break;
                }
                case 9:{
                    [[[UIAlertView alloc] initWithTitle:@"注册失败" message:@"用户名已经存在！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    [self.textUid becomeFirstResponder];
                    break;
                }
                default:
                {
                    [[[UIAlertView alloc] initWithTitle:@"注册失败" message:@"发生未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
            }
        }];
    } else {
        hud.label.text = @"修改中";
        [performer performActionWithDictionary:dict toURL:@"edituser" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"修改失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"修改失败";
                hud.mode = MBProgressHUDModeCustomView;
                [hud hideAnimated:YES afterDelay:0.5];
                return;
            }
            if ([[[result firstObject] objectForKey:@"code"] integerValue] == 0) {
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                hud.label.text = @"修改成功";
            } else {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"修改失败";
            }
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
            
            switch ([[[result firstObject] objectForKey:@"code"] integerValue]) {
                case 0: {
                    if (self.textPsd.text.length > 0) {
                        UIAlertView *passSure = [[UIAlertView alloc] initWithTitle:@"验证密码" message:@"您选择了修改密码\n请输入原密码以验证身份" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
                        [passSure setAlertViewStyle:UIAlertViewStylePlainTextInput];
                        [passSure textFieldAtIndex:0].placeholder = @"原密码";
                        [passSure textFieldAtIndex:0].secureTextEntry = YES;
                        [passSure show];
                    } else {
                        [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
                    }
                    break;
                }
                case 1:{
                    [[[UIAlertView alloc] initWithTitle:@"修改个人信息失败" message:[[result firstObject] objectForKey:@"msg"] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
                default:
                {
                    [[[UIAlertView alloc] initWithTitle:@"修改个人信息失败" message:@"发生未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"错误"]) {
        [firstResp becomeFirstResponder];
    }
    if (buttonIndex == alertView.cancelButtonIndex) {
        if ([alertView.title isEqualToString:@"验证密码"]) {
            [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
        }
        return;
    }
    if ([alertView.title isEqualToString:@"验证密码"]) {
        if (!hud && self.navigationController) {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
        }
        hud.mode = MBProgressHUDModeIndeterminate;
        [hud showAnimated:YES];
        hud.label.text = @"修改中";
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[ActionPerformer md5:[alertView textFieldAtIndex:0].text], @"old", [ActionPerformer md5:self.textPsd.text], @"new", nil];
        [performerPsd performActionWithDictionary:dict toURL:@"changepsd" withBlock:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"修改失败" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"修改失败";
                hud.mode = MBProgressHUDModeCustomView;
                [hud hideAnimated:YES afterDelay:0.5];
                return;
            }
            if ([[[result firstObject] objectForKey:@"code"] integerValue] == 0) {
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                hud.label.text = @"修改成功";
            } else {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.label.text = @"修改失败";
            }
            hud.mode = MBProgressHUDModeCustomView;
            [hud hideAnimated:YES afterDelay:0.5];
            
            switch ([[[result firstObject] objectForKey:@"code"] integerValue]) {
                case 0: {
                    [GROUP_DEFAULTS setObject:self.textPsd.text forKey:@"pass"];
                    [GROUP_DEFAULTS setObject:[[result firstObject] objectForKey:@"msg"] forKey:@"token"];
                    [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
                    break;
                }
                case 1:{
                    [[[UIAlertView alloc] initWithTitle:@"修改密码失败" message:@"登录超时，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
                case 2:{
                    [[[UIAlertView alloc] initWithTitle:@"修改密码失败" message:@"旧密码错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
                case 3:{
                    [[[UIAlertView alloc] initWithTitle:@"修改密码失败" message:@"数据库错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
                default:
                {
                    [[[UIAlertView alloc] initWithTitle:@"修改密码失败" message:@"发生未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                    break;
                }
            }
        }];
    }
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
        if (err || result.count == 0 || [[[result objectAtIndex:0] objectForKey:@"username"] length] == 0) {
            [self.imageUidAvailable setImage:SUCCESSMARK];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        } else {
            [self.imageUidAvailable setImage:FAILMARK];
            [self.labelUidGuide setText:UID_WARNING];
            [self.labelUidGuide setTextColor:[UIColor redColor]];
            [self.labelUidGuide performSelector:@selector(setText:) withObject:UID_GUIDE afterDelay:1.0];
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

+ (BOOL)isValidateEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSRange range = [email rangeOfString:emailRegex options:NSRegularExpressionSearch];
    return (range.location != NSNotFound);
}

- (BOOL)isValidQQ:(NSString *)QQ {
    const char *cvalue = [QQ UTF8String];
    int len = (int)strlen(cvalue);
    if (len < 5 || len > 11) {
        return NO;
    }
    for (int i = 0; i < len; i++) {
        if (isnumber(cvalue[i]) == NO) {
            return NO;
        }
    }
    return YES;
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
