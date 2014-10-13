//
//  SettingViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@interface SettingViewController : UITableViewController<UIActionSheetDelegate,MFMailComposeViewControllerDelegate>{
    MFMailComposeViewController *mvc;
}
@property (weak, nonatomic) IBOutlet UILabel *textUid;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentProxy;
- (IBAction)proxyChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *switchPic;
- (IBAction)picChanged:(id)sender;

@end
