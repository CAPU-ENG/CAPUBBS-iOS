//
//  CustomViewControllers.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

@implementation CustomViewController

@end

@implementation CustomTableViewController

@end

@implementation CustomCollectionViewController

@end

@implementation CustomMailComposeViewController

@end

@implementation UIViewController (Extension)

- (void)presentViewControllerSafe:(UIViewController *)view {
    dispatch_main_async_safe(^{
        [self presentViewController:view animated:YES completion:nil];
    });
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
