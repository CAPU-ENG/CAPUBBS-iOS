//
//  CustomViewControllers.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 6/4/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface CustomViewController : UIViewController
@end

@interface CustomTableViewController : UITableViewController
@end

@interface CustomCollectionViewController : UICollectionViewController
@end

@interface CustomMailComposeViewController : MFMailComposeViewController
@end

@interface UIViewController (Alert)

- (void)presentAlertController:(UIAlertController *)alert;

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle;

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message;

@end

@interface CustomViewController (Customize)
@end

@interface CustomTableViewController (Customize)
@end

@interface CustomCollectionViewController (Customize)
@end

@interface CustomMailComposeViewController (Customize)
@end
