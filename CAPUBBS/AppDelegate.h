//
//  AppDelegate.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource> {
    ActionPerformer *performer;
    NSString *previewFilePath;
    NSString *previewFileName;
    UIView *previewFrame;
}

@property (strong, nonatomic) UIWindow *window;

@end
