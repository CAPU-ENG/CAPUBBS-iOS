//
//  CustomViewControllers.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <objc/runtime.h>

@implementation CustomViewController

@end

@implementation CustomTableViewController

@end

@implementation CustomCollectionViewController

@end

@implementation CustomMailComposeViewController

@end

@implementation UIViewController (Extension)

static char kViewControllerQueueKey;
static char kPresentTimerKey;

- (NSMutableArray<UIViewController *> *)_getVcQueue {
    NSMutableArray *queue = objc_getAssociatedObject(self, &kViewControllerQueueKey);
    if (!queue) {
        queue = [NSMutableArray array];
        objc_setAssociatedObject(self, &kViewControllerQueueKey, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return queue;
}

- (NSTimer *)_getPresentTimer {
    return objc_getAssociatedObject(self, &kPresentTimerKey);
}

- (void)_setPresentTimer:(NSTimer *)timer {
    objc_setAssociatedObject(self, &kPresentTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)_tryPresentNextVc {
    if (self.presentedViewController) {
        return NO;
    }
    
    NSMutableArray *queue = [self _getVcQueue];
    if (queue.count == 0) {
        if ([self _getPresentTimer]) {
            [[self _getPresentTimer] invalidate];
            [self _setPresentTimer:nil];
        }
        return NO;
    }
    
    UIViewController *item = queue.firstObject;
    [queue removeObjectAtIndex:0];
    dispatch_main_async_safe(^{
        [self presentViewController:item animated:YES completion:nil];
    });
    return YES;
}

- (void)_timerCheck {
    [self _tryPresentNextVc];
}

- (void)presentViewControllerSafe:(UIViewController *)view {
    [[self _getVcQueue] addObject:view];
    if ([self _tryPresentNextVc]) {
        return;
    }
    if (![self _getPresentTimer]) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                          target:self
                                                        selector:@selector(_timerCheck)
                                                        userInfo:nil
                                                         repeats:YES];
        [self _setPresentTimer:timer];
    }
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              confirmTitle:(NSString *)confirmTitle
             confirmAction:(void (^)(UIAlertAction *action))confirmAction
               cancelTitle:(NSString *)cancelTitle
              cancelAction:(void (^)(UIAlertAction *action))cancelAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    if (confirmTitle && confirmAction) {
        [alert addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                  style:[confirmTitle containsString:@"删除"] ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault
                                                handler:confirmAction]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:cancelTitle
                                              style:UIAlertActionStyleCancel
                                            handler:cancelAction]];
    [self presentViewControllerSafe:alert];
};

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              confirmTitle:(NSString *)confirmTitle
             confirmAction:(void (^)(UIAlertAction *action))confirmAction
               cancelTitle:(NSString *)cancelTitle {
    [self showAlertWithTitle:title message:message confirmTitle:confirmTitle confirmAction:confirmAction cancelTitle:cancelTitle cancelAction:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              confirmTitle:(NSString *)confirmTitle
             confirmAction:(void (^)(UIAlertAction *action))confirmAction {
    [self showAlertWithTitle:title message:message confirmTitle:confirmTitle confirmAction:confirmAction cancelTitle:@"取消" cancelAction:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle {
    [self showAlertWithTitle:title message:message confirmTitle:nil confirmAction:nil cancelTitle:cancelTitle cancelAction:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
             cancelAction:(void (^)(UIAlertAction *action))cancelAction {
    [self showAlertWithTitle:title message:message confirmTitle:nil confirmAction:nil cancelTitle:@"好" cancelAction:cancelAction];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message confirmTitle:nil confirmAction:nil cancelTitle:@"好" cancelAction:nil];
}

@end

@implementation CustomViewController (Customize)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation CustomTableViewController (Customize)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation CustomCollectionViewController (Customize)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation CustomMailComposeViewController (Customize)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
