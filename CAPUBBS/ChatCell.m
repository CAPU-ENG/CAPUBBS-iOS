//
//  ChatCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "ChatCell.h"

@implementation ChatCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.imageChat setAlpha:0.8];
    [self.labelTime.layer setCornerRadius:5.0];
    [self.labelTime.layer setMasksToBounds:YES];
    [self.textSend.layer setCornerRadius:10.0];
    [self.textSend setScrollsToTop:NO];
    [self.textMessage setBackgroundColor:[UIColor clearColor]];
    [self.imageIcon setRounded:YES];
    
    self.layer.shouldRasterize = YES; // 光栅化 提高流畅度
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
