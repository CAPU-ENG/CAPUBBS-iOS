//
//  ContentViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"

@interface ContentViewController : UITableViewController<UIAlertViewDelegate, MFMailComposeViewControllerDelegate, UIWebViewDelegate, UIDocumentInteractionControllerDelegate> {
    MBProgressHUD *hud;
    ActionPerformer *performer;
    NSUserActivity *activity;
    NSString *URL;
    NSMutableArray *data;
    MFMailComposeViewController *mail;
    UIDocumentInteractionController *dic;
    int page;
    int textSize;
    BOOL isLast;
    BOOL isEdit;
    NSString *defaultTitle;
    NSString *defaultContent;
    NSInteger selectedIndex;
    NSMutableArray *heights;
    NSMutableArray *estimatedHeights;
    NSMutableArray *HTMLStrings;
    NSString *tempPath;
    NSString *imgPath;
    CGFloat contentOffsetY;
    BOOL isAtEnd;
}

@property NSString *bid;
@property NSString *tid;
@property NSString *floor;
@property NSString *exactFloor;
@property BOOL willScroll;
@property BOOL isCollection;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *barFreeSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCollection;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonForward;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLatest;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonJump;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonAction;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCompose;
+ (NSString *)htmlStringWithRespondString:(NSString *)respondString;
+ (NSString *)restoreFormat:(NSString *)text;
+ (NSString *)transFromHTML:(NSString *)text;
+ (NSString *)removeHTML:(NSString *)text;
+ (NSDictionary *)getLink:(NSString *)path;
@end
