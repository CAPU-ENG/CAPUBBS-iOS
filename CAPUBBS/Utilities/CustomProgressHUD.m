//
//  CustomProgressHUD.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

@implementation MBProgressHUD (Custom)

- (void)showWithProgressMessage:(NSString *)message {
    dispatch_main_async_safe(^{
        self.label.text = message;
        self.mode = MBProgressHUDModeIndeterminate;
        [self showAnimated:YES];
    });
}

- (void)showWithImage:(UIImage *)image message:(NSString *)message andHideAfter:(NSTimeInterval)delay {
    dispatch_main_async_safe(^{
        self.label.text = message;
        self.mode = MBProgressHUDModeCustomView;
        self.customView = [[UIImageView alloc] initWithImage:image];
        [self showAnimated:YES];
        [self hideAnimated:YES afterDelay:delay];
    });
}

- (void)showAndHideWithSuccessMessage:(NSString *)message {
    [self showAndHideWithSuccessMessage:message delay:0.5];
}

- (void)showAndHideWithSuccessMessage:(NSString *)message delay:(NSTimeInterval)delay {
    [self showWithImage:SUCCESSMARK message:message andHideAfter:delay];
}

- (void)showAndHideWithFailureMessage:(NSString *)message {
    [self showAndHideWithFailureMessage:message delay: 0.5];
}

- (void)showAndHideWithFailureMessage:(NSString *)message delay:(NSTimeInterval)delay {
    [self showWithImage:FAILMARK message:message andHideAfter:delay];
}

- (void)hideWithImage:(UIImage *)image message:(NSString *)message delay:(NSTimeInterval)delay {
    if (self.hidden) {
        return;
    }
    dispatch_main_async_safe(^{
        self.label.text = message;
        self.mode = MBProgressHUDModeCustomView;
        self.customView = [[UIImageView alloc] initWithImage:image];
        [self hideAnimated:YES afterDelay:delay];
    });
}

- (void)hideWithSuccessMessage:(NSString *)message {
    [self hideWithSuccessMessage:message delay:0.5];
}

- (void)hideWithSuccessMessage:(NSString *)message delay:(NSTimeInterval)delay {
    [self hideWithImage:SUCCESSMARK message:message delay:delay];
}

- (void)hideWithFailureMessage:(NSString *)message {
    [self hideWithFailureMessage:message delay:0.5];
}

- (void)hideWithFailureMessage:(NSString *)message delay:(NSTimeInterval)delay {
    [self hideWithImage:FAILMARK message:message delay:delay];
}

@end
