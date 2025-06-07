//
//  PreviewViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/12.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CustomWebViewContainer.h"

@interface PreviewViewController : CustomViewController<WKNavigationDelegate> {
}

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet CustomWebViewContainer *webViewContainer;
@property NSString *textTitle;
@property NSString *textBody;
@property int sig;

@end
