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

@implementation UIViewController (Alert)

- (void)presentAlertController:(UIAlertController *)alert {
    dispatch_main_async_safe(^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:cancelTitle
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentAlertController:alert];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message cancelTitle:@"好"];
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
