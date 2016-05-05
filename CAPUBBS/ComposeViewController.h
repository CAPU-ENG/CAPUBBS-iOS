//
//  ComposeViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-19.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface ComposeViewController : UIViewController<UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    MBProgressHUD *hud;
    ActionPerformer *performer;
    NSUserActivity *activity;
    UIImage *image;
    int toolbarEditor;
    UIToolbar *toolbar;
}

@property (weak, nonatomic) IBOutlet UITextField *textTitle;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UIButton *saveDraft;
@property (weak, nonatomic) IBOutlet UIButton *restoreDraft;
@property (weak, nonatomic) IBOutlet UIButton *buttonPic;
@property (weak, nonatomic) IBOutlet UIButton *buttonTools;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *viewTools;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;

@property NSString *bid;
@property NSString *tid;
@property NSString *defaultTitle;
@property NSString *defaultContent;
@property NSString *floor;
@property BOOL isEdit;

@end
