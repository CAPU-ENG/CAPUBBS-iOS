//
//  ListViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"

@interface ListViewController : UITableViewController<UIAlertViewDelegate,UISearchBarDelegate,UISearchDisplayDelegate,UIActionSheetDelegate>{
    ActionPerformer *performer;
    NSArray *data;
    MBProgressHUD *hud;
    NSInteger page;
    BOOL isLast;
    NSArray *searchResult;
    NSInteger selectedRow;
}
@property NSString *b;
- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)compose:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonForward;
- (IBAction)jump:(id)sender;
- (IBAction)longPress:(id)sender;
@property NSString *name;
@end
