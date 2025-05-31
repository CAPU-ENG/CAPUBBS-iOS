//
//  ContentCell.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ContentCell.h"

@implementation ContentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [self.icon setRounded:YES];
    [self.webView.layer setCornerRadius:10.0];
    [self.webView.layer setBorderColor:GREEN_LIGHT.CGColor];
    [self.webView.layer setBorderWidth:1.0];
    [self.webView.layer setMasksToBounds:YES];
    [self.webView.scrollView setScrollEnabled:NO];
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    [self.webView setAllowsLinkPreview:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
