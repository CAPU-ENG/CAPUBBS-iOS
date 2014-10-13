//
//  ComposeViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-19.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"
#import "ASIFormDataRequest.h"

@interface ComposeViewController : UIViewController<UITextViewDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ASIHTTPRequestDelegate,NSXMLParserDelegate>{
    CGRect origin;
    CGFloat delta;
    MBProgressHUD *hud;
    ActionPerformer *performer;
    ASIFormDataRequest *httpRequest;
    NSInteger uploaded;
    NSInteger total;
    
    NSMutableArray *finalData;
    NSString *currentField;
    NSMutableString *currentString;
    NSMutableDictionary *tempData;
    UIImage* image;
}
@property (weak, nonatomic) IBOutlet UITextField *textTitle;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
- (IBAction)didEndOnExit:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
- (IBAction)selectPic:(id)sender;
@property NSString *navigationTitle;
@property NSString *reply;
@property NSString *defaultTitle;
@property NSString *defaultContent;
@property NSString *b;
@property NSString *floor;
@property BOOL isEdit;

@end
