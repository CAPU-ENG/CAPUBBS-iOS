//
//  ContentViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface ContentViewController : CustomTableViewController<WKNavigationDelegate, WKScriptMessageHandler> {
    MBProgressHUD *hud;
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
    CGFloat contentOffsetY;
    BOOL isAtEnd;
    NSInteger scrollTargetRow;
}

@property NSString *bid;
@property NSString *tid;
@property NSString *destinationPage;
/// If set, will try to scroll to the desired flor
@property NSString *destinationFloor;
/// If set, will popup lzl for the desired floor
@property BOOL openDestinationLzl;
/// If set, will try to scroll to the last flor
@property BOOL willScrollToBottom;
@property BOOL isCollection;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *barFreeSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCollection;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonForward;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLatest;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonJump;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonAction;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCompose;

@end
