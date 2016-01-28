//
//  PreviewViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"

@interface PreviewViewController : UIViewController<UIAlertViewDelegate, UIWebViewDelegate> {
}

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property NSString *textTitle;
@property NSString *textBody;
@property int sig;

@end
