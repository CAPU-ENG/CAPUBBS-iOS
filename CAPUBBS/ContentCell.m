//
//  ContentCell.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ContentCell.h"

@implementation ContentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.icon setRounded:YES];
    [self.webViewContainer.layer setCornerRadius:10.0];
    [self.webViewContainer.layer setBorderColor:GREEN_LIGHT.CGColor];
    [self.webViewContainer.layer setBorderWidth:1.0];
    [self.webViewContainer.layer setMasksToBounds:YES];
    [self.webViewContainer setBackgroundColor:[UIColor whiteColor]];
    [self.webViewContainer initiateWebViewForToken:nil];
    [self.webViewContainer.webView.scrollView setScrollEnabled:NO];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.webViewContainer.webView loadHTMLString:@"" baseURL:[NSURL URLWithString:CHEXIE]];
    if (self.heightCheckTimer && [self.heightCheckTimer isValid]) {
        [self.heightCheckTimer invalidate];
    }
}

@end
