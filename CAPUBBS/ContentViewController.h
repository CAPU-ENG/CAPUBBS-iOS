//
//  ContentViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface ContentViewController : CustomTableViewController<WKNavigationDelegate> {
    MBProgressHUD *hud;
    ActionPerformer *performer;
    NSUserActivity *activity;
    NSString *URL;
    NSMutableArray *data;
    UIDocumentInteractionController *dic;
    int page;
    int textSize;
    BOOL isLast;
    BOOL isEdit;
    NSString *defaultTitle;
    NSString *defaultContent;
    NSInteger selectedIndex;
    NSMutableArray *heights;
    NSMutableArray *tempHeights; // 储存之前计算的高度结果，防止reload时高度突变
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
+ (NSString *)htmlStringWithText:(NSString *)text sig:(NSString *)sig textSize:(int)textSize;
+ (NSString *)restoreFormat:(NSString *)text;
+ (NSString *)transFromHTML:(NSString *)text;
+ (NSString *)removeHTML:(NSString *)text;
+ (NSDictionary *)getLink:(NSString *)path;
@end
