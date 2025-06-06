//
//  CustomProgressHUD.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface MBProgressHUD (Custom)

- (void)showWithProgressMessage:(NSString *)message;
- (void)showAndHideWithSuccessMessage:(NSString *)message;
- (void)showAndHideWithSuccessMessage:(NSString *)message delay:(NSTimeInterval)delay;
- (void)showAndHideWithFailureMessage:(NSString *)message;
- (void)showAndHideWithFailureMessage:(NSString *)message delay:(NSTimeInterval)delay;
- (void)hideWithSuccessMessage:(NSString *)message;
- (void)hideWithSuccessMessage:(NSString *)message delay:(NSTimeInterval)delay;
- (void)hideWithFailureMessage:(NSString *)message;
- (void)hideWithFailureMessage:(NSString *)message delay:(NSTimeInterval)delay;

@end
