//
//  SettingViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AsyncImageView.h"

@interface SettingViewController : CustomTableViewController {
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet AsyncImageView *iconUser;
@property (weak, nonatomic) IBOutlet UILabel *textUid;
@property (weak, nonatomic) IBOutlet UILabel *textUidInfo;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellUser;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentProxy;
@property (weak, nonatomic) IBOutlet UISwitch *autoLogin;
@property (weak, nonatomic) IBOutlet UISwitch *switchVibrate;
@property (weak, nonatomic) IBOutlet UISwitch *switchPic;
@property (weak, nonatomic) IBOutlet UISwitch *switchIcon;
@property (weak, nonatomic) IBOutlet UILabel *iconCacheSize;
@property (weak, nonatomic) IBOutlet UILabel *appCacheSize;
@property (weak, nonatomic) IBOutlet UILabel *defaultSize;
@property (weak, nonatomic) IBOutlet UIStepper *stepperSize;
@property (weak, nonatomic) IBOutlet UISwitch *autoSave;
@property (weak, nonatomic) IBOutlet UISwitch *switchSimpleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentDirection;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentEditTool;

+ (long long) fileSizeAtPath:(NSString *)filePath;
+ (long long) folderSizeAtPath:(NSString *)folderPath;

@end
