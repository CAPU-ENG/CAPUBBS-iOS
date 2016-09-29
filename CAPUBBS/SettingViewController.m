//
//  SettingViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "SettingViewController.h"
#import "ContentViewController.h"
#import "UserViewController.h"
#import "WebViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(360, 10000); // 高度填满屏幕
    [self.iconUser setRounded:YES];
    [NOTIFICATION addObserver:self selector:@selector(userChanged) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(refreshInfo) name:@"infoRefreshed" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(cacheChanged:) name:nil object:nil];
    [self setDefault];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setDefault {
    //[self.segmentProxy setSelectedSegmentIndex:[[DEFAULTS objectForKey:@"proxy"] integerValue]];
    [self.autoLogin setOn:[[DEFAULTS objectForKey:@"autoLogin"] boolValue]];
    [self.switchVibrate setOn:[[DEFAULTS objectForKey:@"vibrate"] boolValue]];
    [self.segmentDirection setSelectedSegmentIndex:[[DEFAULTS objectForKey:@"oppositeSwipe"] boolValue]];
    [self.segmentEditTool setSelectedSegmentIndex:[[DEFAULTS objectForKey:@"toolbarEditor"] intValue]];
    [self.switchPic setOn:[[DEFAULTS objectForKey:@"picOnlyInWifi"] boolValue]];
    [self.switchIcon setOn:[[GROUP_DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue]];
    [self.autoSave setOn:[[DEFAULTS objectForKey:@"autoSave"] boolValue]];
    [self.switchSimpleView setOn:SIMPLE_VIEW];
    [self.stepperSize setValue:[[DEFAULTS objectForKey:@"textSize"] intValue]];
    [self.defaultSize setText:[NSString stringWithFormat:@"默认字体大小 - %d%%", (int)self.stepperSize.value]];
    [self userChanged];
    [self refreshInfo];
    [self cacheChanged:nil];
}

- (void)userChanged {
    dispatch_main_async_safe(^{
        if ([ActionPerformer checkLogin:NO]) {
            self.textUid.text = UID;
            self.textUidInfo.text = @"加载中...";
            self.cellUser.accessoryType = UITableViewCellAccessoryDetailButton;
            self.cellUser.userInteractionEnabled = YES;
        }else {
            [self.iconUser performSelectorOnMainThread:@selector(setImage:) withObject:PLACEHOLDER waitUntilDone:NO];
            self.textUid.text = @"未登录";
            self.textUidInfo.text = @"请在账号管理中登录";
            self.cellUser.accessoryType = UITableViewCellAccessoryNone;
            self.cellUser.userInteractionEnabled = NO;
        }
    });
}

- (void)refreshInfo {
    if ([ActionPerformer checkLogin:NO] && ![USERINFO isEqual:@""]) {
        NSDictionary *info = USERINFO;
        if ([[info objectForKey:@"sex"] isEqualToString:@"男"]) {
            self.textUid.text = [info[@"username"] stringByAppendingString:@" 🚹"];
        }else if ([[info objectForKey:@"sex"] isEqualToString:@"女"]) {
            self.textUid.text = [info[@"username"] stringByAppendingString:@" 🚺"];
        }
        [self.iconUser setUrl:[info objectForKey:@"icon"]];
        self.textUidInfo.text = [NSString stringWithFormat:@"星星：%@ 权限：%@", [info objectForKey:@"star"], [info objectForKey:@"rights"]];
    }
}

- (void)cacheChanged:(NSNotification *)noti {
    if (noti == nil || [noti.name hasPrefix:@"imageGet"]) {
        __block long long cacheSize = 0;
        NSString *dir = NSTemporaryDirectory(); // tmp目录
        cacheSize += [SettingViewController folderSizeAtPath:dir];
        dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]; // Caches目录
        cacheSize += [SettingViewController folderSizeAtPath:dir];
        self.appCacheSize.text = [NSString stringWithFormat:@"%.2fMB", (float)cacheSize / (1024 * 1024)];
        
        self.iconCacheSize.text = [NSString stringWithFormat:@"%.2fMB", (float)[SettingViewController folderSizeAtPath:CACHE_PATH] / (1024 * 1024)];
    }
}

//单个文件的大小
+ (long long) fileSizeAtPath:(NSString *)filePath {
    if ([MANAGER fileExistsAtPath:filePath]) {
        return [[MANAGER attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

//遍历文件夹获得文件夹大小
+ (long long) folderSizeAtPath:(NSString *)folderPath {
    if (![MANAGER fileExistsAtPath:folderPath]) {
        return 0;
    }
    NSArray *chileFiles = [MANAGER subpathsAtPath:folderPath];
    long long folderSize = 0;
    for (NSString *fileName in chileFiles) {
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}

- (void)deleteAllFiles:(NSString *)path {
    if ([MANAGER fileExistsAtPath:path]) {
        NSArray *childerFiles = [MANAGER subpathsAtPath:path];
        for (NSString *fileName in childerFiles) {
            // 如有需要，加入条件，过滤掉不想删除的文件
            NSString *absolutePath = [path stringByAppendingPathComponent:fileName];
            [MANAGER removeItemAtPath:absolutePath error:nil];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title hasPrefix:@"确认清除"]) {
        if ([alertView.title isEqualToString:@"确认清除头像缓存？"]) {
            [MANAGER removeItemAtPath:CACHE_PATH error:nil];
        }
        if ([alertView.title isEqualToString:@"确认清除软件缓存？"]) {
            [self deleteAllFiles:NSTemporaryDirectory()]; // tmp目录
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            [MANAGER removeItemAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] error:nil]; // Caches目录
        }
        if (!hud && self.navigationController) {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
        }
        [hud show:YES];
        hud.labelText = @"清除完成";
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
        [hud hide:YES afterDelay:0.5];
        [self cacheChanged:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [[[UIAlertView alloc] initWithTitle:@"确认清除软件缓存？" message:@"这将清除部分缓存和临时文件\n不会清除头像缓存" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil] show];
        }
        if (indexPath.row == 1) {
            [[[UIAlertView alloc] initWithTitle:@"确认清除头像缓存？" message:@"建议仅在头像出错时使用" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil] show];
        }
    }else if (indexPath.section == 2) {
        if (indexPath.row == 3) {
            NSString *app_Version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            NSString *app_Build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            mail = [[MFMailComposeViewController alloc] init];
            mail.mailComposeDelegate = self;
            [mail.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
            [mail.navigationBar setTintColor:[UIColor whiteColor]];
            [mail setSubject:@"CAPUBBS iOS客户端反馈"];
            [mail setToRecipients:FEEDBACK_EMAIL];
            [mail setMessageBody:[NSString stringWithFormat:@"设备：%@ 系统：iOS %@ 客户端版本：%@ Build %@", [ActionPerformer doDevicePlatform], [[UIDevice currentDevice] systemVersion], app_Version, app_Build] isHTML:NO];
            [self presentViewController:mail animated:YES completion:nil];
        }else if (indexPath.row == 4) {
            NSString *str = @"itms-apps://itunes.apple.com/app/id826386033";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
        }else if (indexPath.row == 5) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            [[[UIAlertView alloc] initWithTitle:@"🚲关于本软件🚲" message:[NSString stringWithFormat:@"CAPUBBS iOS客户端\n版本：%@\n更新时间：%s\n\n原作：熊典|I2\n协助开发：陈章|维茨C\n更新与维护：范志康|好男人\n\n%@\n\n%@", app_Version, __DATE__, COPYRIGHT, EULA] delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [mail dismissViewControllerAnimated:YES completion:nil];
}

/*- (IBAction)proxyChanged:(id)sender {
    [DEFAULTS setObject:[NSNumber numberWithInteger:self.segmentProxy.selectedSegmentIndex] forKey:@"proxy"];
}*/

- (IBAction)loginChanged:(id)sender {
    [DEFAULTS setObject:[NSNumber numberWithBool:self.autoLogin.isOn] forKey:@"autoLogin"];
}

- (IBAction)vibrateChanged:(id)sender {
    [DEFAULTS setObject:[NSNumber numberWithBool:self.switchVibrate.isOn] forKey:@"vibrate"];
}

- (IBAction)picChanged:(id)sender {
    [DEFAULTS setObject:[NSNumber numberWithBool:self.switchPic.isOn] forKey:@"picOnlyInWifi"];
    if (self.switchPic.isOn) {
        [[[UIAlertView alloc] initWithTitle:@"图片显示已关闭" message:@"使用流量时\n帖子图片将以🚫代替\n点击🚫可以加载图片" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)iconChanged:(id)sender {
    [GROUP_DEFAULTS setObject:[NSNumber numberWithBool:self.switchIcon.isOn] forKey:@"iconOnlyInWifi"];
    if (self.switchIcon.isOn) {
        [[[UIAlertView alloc] initWithTitle:@"头像显示已关闭" message:@"使用流量时\n未缓存过的头像将以会标代替\n已缓存过的头像将会正常加载" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)saveChanged:(id)sender {
    [DEFAULTS setObject:[NSNumber numberWithBool:self.autoSave.isOn] forKey:@"autoSave"];
}

- (IBAction)sizeChanged:(UIStepper *)sender {
    [DEFAULTS setObject:[NSNumber numberWithInt:(int)self.stepperSize.value] forKey:@"textSize"];
    self.defaultSize.text = [NSString stringWithFormat:@"默认字体大小 - %d%%", (int)self.stepperSize.value];
}

- (IBAction)simpleViewChanged:(id)sender {
    [GROUP_DEFAULTS setObject:[NSNumber numberWithBool:self.switchSimpleView.isOn] forKey:@"simpleView"];
    if (self.switchSimpleView.isOn) {
        [[[UIAlertView alloc] initWithTitle:@"简洁版内容已启用" message:@"将隐藏部分详细信息\n动图头像将静态显示\n模糊效果将禁用" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    }
}


- (IBAction)selectDirection:(UISegmentedControl *)sender {
    [DEFAULTS setObject:[NSNumber numberWithLong:sender.selectedSegmentIndex] forKey:@"oppositeSwipe"];
}

- (IBAction)selectEditTool:(UISegmentedControl *)sender {
    [DEFAULTS setObject:[NSNumber numberWithLong:sender.selectedSegmentIndex] forKey:@"toolbarEditor"];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"userInfo"]) {
        UserViewController *dest = [segue destinationViewController];
        dest.navigationItem.leftBarButtonItems = nil;
        if ([UID length] > 0) {
            dest.ID = UID;
        }else {
            dest.ID = @"";
        }
        if (![self.iconUser.image isEqual:PLACEHOLDER]) {
            dest.iconData = UIImagePNGRepresentation(self.iconUser.image);
        }
    }
    if ([segue.identifier isEqualToString:@"account"]) {
        UIViewController *dest = [segue destinationViewController];
        dest.navigationItem.leftBarButtonItems = nil;
    }
    if ([segue.identifier isEqualToString:@"web"]) {
        WebViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        if (indexPath.row == 0) {
            dest.URL = [NSString stringWithFormat:@"https://%@/bbs", CHEXIE];
        }else if (indexPath.row == 1) {
            dest.URL = [NSString stringWithFormat:@"https://%@", CHEXIE];
        }
    }
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        dest.bid = @"4";
        dest.tid = @"17637";
        dest.title = @"CAPUBBS客户端 帮助与意见反馈";
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
