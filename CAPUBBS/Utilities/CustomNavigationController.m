//
//  CustomNavigationController.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "CustomNavigationController.h"

@implementation CustomNavigationController

// 让状态栏样式跟随当前 topViewController
- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

@end
