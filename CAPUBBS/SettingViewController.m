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
#import "CustomWebViewContainer.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AppDelegate setPrefersLargeTitles:self.navigationController];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(400, 1000);
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
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
    [self.switchAutoLogin setOn:[[DEFAULTS objectForKey:@"autoLogin"] boolValue]];
    [self.switchVibrate setOn:[[DEFAULTS objectForKey:@"vibrate"] boolValue]];
    [self.segmentDirection setSelectedSegmentIndex:[[DEFAULTS objectForKey:@"oppositeSwipe"] intValue]];
    [self.segmentEditTool setSelectedSegmentIndex:[[DEFAULTS objectForKey:@"toolbarEditor"] intValue]];
    [self.switchPic setOn:[[DEFAULTS objectForKey:@"picOnlyInWifi"] boolValue]];
    [self.switchIcon setOn:[[GROUP_DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue]];
    [self.switchAutoSave setOn:[[DEFAULTS objectForKey:@"autoSave"] boolValue]];
    [self.switchSimpleView setOn:SIMPLE_VIEW];
    [self.switchScript setOn:[[DEFAULTS objectForKey:@"disableScript"] boolValue]];
    [self.switchChangeBackground setOn:[[DEFAULTS objectForKey:@"changeBackground"] boolValue]];
    [self.stepperSize setValue:[[DEFAULTS objectForKey:@"textSize"] intValue]];
    [self.defaultSize setText:[NSString stringWithFormat:@"默认页面缩放 - %d%%", (int)self.stepperSize.value]];
    [self userChanged];
    [self refreshInfo];
    self.appCacheSize.text = @"计算中...";
    self.iconCacheSize.text = @"计算中...";
    [self cacheChanged:nil];
}

- (void)userChanged {
    dispatch_main_async_safe(^{
        if ([Helper checkLogin:NO]) {
            self.textUid.text = UID;
            self.textUidInfo.text = @"加载中...";
            self.cellUser.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.cellUser.userInteractionEnabled = YES;
        } else {
            self.iconUser.image = PLACEHOLDER;
            self.textUid.text = @"未登录";
            self.textUidInfo.text = @"请在账号管理中登录";
            self.cellUser.accessoryType = UITableViewCellAccessoryNone;
            self.cellUser.userInteractionEnabled = NO;
        }
    });
}

- (void)refreshInfo {
    dispatch_main_async_safe((^{
        NSDictionary *info = USERINFO;
        if ([Helper checkLogin:NO] && info && ![info isEqual:@""]) {
            if ([info[@"sex"] isEqualToString:@"男"]) {
                self.textUid.text = [info[@"username"] stringByAppendingString:@" ♂"];
            } else if ([info[@"sex"] isEqualToString:@"女"]) {
                self.textUid.text = [info[@"username"] stringByAppendingString:@" ♀"];
            }
            [self.iconUser setUrl:info[@"icon"]];
            self.textUidInfo.text = [NSString stringWithFormat:@"星星：%@ 权限：%@ 签到：%@", info[@"star"], info[@"rights"], info[@"sign"]];
        }
    }));
}

- (void)cacheChanged:(NSNotification *)noti {
    if (noti != nil && ![noti.name hasPrefix:@"imageGet"]) {
        return;
    }
    if (isCalculatingCache) {
        return;
    }
    isCalculatingCache = YES;
    dispatch_global_default_async(^{
        unsigned long long cacheSize = 0;
        // tmp目录
        cacheSize += [Helper folderSizeAtPath:NSTemporaryDirectory()];
        // Caches目录
        cacheSize += [Helper folderSizeAtPath:CACHE_PATH];
        unsigned long long iconCacheSize = [Helper folderSizeAtPath:ICON_CACHE_PATH];
        isCalculatingCache = NO;
        dispatch_main_async_safe((^{
            self.appCacheSize.text = [Helper fileSizeStr:cacheSize];
            self.iconCacheSize.text = [Helper fileSizeStr:iconCacheSize];
        }));
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showAlertWithTitle:@"确认清除软件缓存？" message:@"将重点清除网络缓存\n不会清除头像缓存\n少数系统关键缓存无法彻底清除" confirmTitle:@"确认" confirmAction:^(UIAlertAction *action) {
                [hud showWithProgressMessage:@"清除中"];
                // WKWebView (WebKit) cache
                [CustomWebViewContainer clearAllDataStores:^{
                    // NSURLCache
                    [[NSURLCache sharedURLCache] removeAllCachedResponses];
                    // Temporary folder
                    [Helper cleanUpFilesInDirectory:NSTemporaryDirectory() minInterval:60 * 60]; // 1 hour
                    // Cache folder
                    [Helper cleanUpFilesInDirectory:CACHE_PATH minInterval:24 * 60 * 60]; // 24 hour
                    
                    [hud hideWithSuccessMessage:@"清除完成"];
                    [self cacheChanged:nil];
                }];
            }];
        } else if (indexPath.row == 1) {
            [self showAlertWithTitle:@"确认清除头像缓存？" message:@"建议仅在头像出错时使用" confirmTitle:@"确认" confirmAction:^(UIAlertAction *action) {
                [MANAGER removeItemAtPath:ICON_CACHE_PATH error:nil];
                [hud showAndHideWithSuccessMessage:@"清除完成"];
                [self cacheChanged:nil];
            }];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 3) {
            [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
                @"recipients": FEEDBACK_EMAIL,
                @"subject": @"CAPUBBS iOS客户端反馈",
                @"body": [NSString stringWithFormat:@"\n设备：%@\n系统：%@\n客户端版本：%@ Build %@", [Helper getDevicePlatform], [Helper getOsVersionString], APP_VERSION, APP_BUILD],
                @"fallbackMessage": @"请前往网络维护板块反馈"
            }];
        } else if (indexPath.row == 4) {
            NSURL *storeLink = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id826386033?action=write-review"];
            if (![[UIApplication sharedApplication] canOpenURL:storeLink]) {
                storeLink = [NSURL URLWithString:@"https://itunes.apple.com/sg/app/capubbs/id826386033"];
            }
            [[UIApplication sharedApplication] openURL:storeLink options:@{} completionHandler:nil];
        } else if (indexPath.row == 5) {
            [self showAlertWithTitle:@"🚲关于本软件🚲" message:[NSString stringWithFormat:@"\nCAPUBBS iOS客户端\n版本：%@\nBuild：%@\n版本创建日期：%s\n\n原作：熊典|I2\n协助开发：陈章|维茨C\n更新与维护：范志康|好男人\n\n%@\n\n%@", APP_VERSION, APP_BUILD, __DATE__, COPYRIGHT, EULA]];
        }
    }
}

/*- (IBAction)proxyChanged:(id)sender {
    [DEFAULTS setObject:@(self.segmentProxy.selectedSegmentIndex) forKey:@"proxy"];
}*/

- (IBAction)loginChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchAutoLogin.isOn) forKey:@"autoLogin"];
}

- (IBAction)vibrateChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchVibrate.isOn) forKey:@"vibrate"];
}

- (IBAction)picChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchPic.isOn) forKey:@"picOnlyInWifi"];
    if (self.switchPic.isOn) {
        [self showAlertWithTitle:@"图片显示已关闭" message:@"使用流量时\n帖子图片将以文字或🚫代替\n点击文字或🚫可以加载图片"];
    }
}

- (IBAction)iconChanged:(id)sender {
    [GROUP_DEFAULTS setObject:@(self.switchIcon.isOn) forKey:@"iconOnlyInWifi"];
    if (self.switchIcon.isOn) {
        [self showAlertWithTitle:@"头像显示已关闭" message:@"使用流量时\n未缓存过的头像将以会标代替\n已缓存过的头像将会正常显示"];
    }
}

- (IBAction)saveChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchAutoSave.isOn) forKey:@"autoSave"];
}

- (IBAction)sizeChanged:(UIStepper *)sender {
    [DEFAULTS setObject:@((int)self.stepperSize.value) forKey:@"textSize"];
    self.defaultSize.text = [NSString stringWithFormat:@"默认页面缩放 - %d%%", (int)self.stepperSize.value];
}

- (IBAction)simpleViewChanged:(id)sender {
    [GROUP_DEFAULTS setObject:@(self.switchSimpleView.isOn) forKey:@"simpleView"];
    [WidgetManager reloadWidgets];
    if (self.switchSimpleView.isOn) {
        [self showAlertWithTitle:@"简洁版内容已启用" message:@"将隐藏部分详细信息\n楼中楼不默认展示\n动图头像将静态显示\n模糊效果将禁用"];
    }
}

- (IBAction)scriptChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchScript.isOn) forKey:@"disableScript"];
    if (self.switchScript.isOn) {
        [self showAlertWithTitle:@"JavaScript脚本已禁用" message:@"动态内容将失效（例如动态签名档）"];
    }
}

- (IBAction)changeBackgroundChanged:(id)sender {
    [DEFAULTS setObject:@(self.switchChangeBackground.isOn) forKey:@"changeBackground"];
}

- (IBAction)selectDirection:(UISegmentedControl *)sender {
    [DEFAULTS setObject:@(sender.selectedSegmentIndex) forKey:@"oppositeSwipe"];
}

- (IBAction)selectEditTool:(UISegmentedControl *)sender {
    [DEFAULTS setObject:@(sender.selectedSegmentIndex) forKey:@"toolbarEditor"];
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
        } else {
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
            dest.URL = [NSString stringWithFormat:@"%@/bbs", CHEXIE];
        } else if (indexPath.row == 1) {
            dest.URL = [NSString stringWithFormat:@"%@", CHEXIE];
        }
    }
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        dest.bid = @"4";
        dest.tid = @"17637";
        dest.title = @"CAPUBBS客户端  帮助与意见反馈";
        dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(done:)];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
