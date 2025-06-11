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
    CGFloat contentOffsetY;
    BOOL isAtEnd;
    NSInteger scrollTargetRow;
}

@property NSString *bid;
@property NSString *tid;
@property NSString *floor;
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
/// 把正文和签名档组合成正式的 HTML
+ (NSString *)htmlStringWithText:(NSString *)text sig:(NSString *)sig textSize:(int)textSize;
/// 从论坛转义过的 HTML 恢复成正确的格式，例如 \<font>xxx\</font> 恢复成 [font=][/font]
+ (NSString *)restoreHTML:(NSString *)text;
/// 把转义过的 HTML 恢复成对应字符，例如 \&lt; 恢复成 <
+ (NSString *)simpleEscapeHTML:(NSString *)text;
/// 把空格和换行转换成 \<br\> 和 \&nbsp; 目的是兼容网页版编辑器，纯客户端其实不需要这个功能
+ (NSString *)toCompatibleFormat:(NSString *)text;
/// restoreHTML 逆操作，例如 [font=][/font] 变成 \<font>xxx\</font>
+ (NSString *)transToHTML:(NSString *)text;
/// 清除 HTML 标签并恢复成论坛格式的文本，有损操作，可能丢失信息
+ (NSString *)removeHTML:(NSString *)text;
/// 提取论坛的链接，获取bid，tid，p，floor
+ (NSDictionary *)getLink:(NSString *)path;
@end
