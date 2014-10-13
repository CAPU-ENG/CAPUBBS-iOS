//
//  ContentViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>
#import "ActionPerformer.h"

@interface ContentViewController : UITableViewController<UIAlertViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,UIWebViewDelegate>{
    NSArray *data;
    MBProgressHUD *hud;
    NSInteger page;
    BOOL isLast;
    NSString *defaultTitle;
    NSString *defaultContent;
    NSInteger selectedRow;
    NSString *defaultNavi;
    BOOL isEdit;
    UIBarButtonItem *left;
    BOOL willScroll;
    ActionPerformer *performer;
    MFMailComposeViewController *mfc;
    
    NSMutableArray *heights;
    NSMutableArray *webViews;
    NSString *temppath;
}
@property NSString *b;
@property NSString *see;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonForward;
- (IBAction)jump:(id)sender;
- (IBAction)compose:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)report:(id)sender;
- (IBAction)longPressPid:(id)sender;
- (IBAction)gotolzl:(id)sender;
@property NSString *title;
@end
