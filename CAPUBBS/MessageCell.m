//
//  MessageCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "MessageCell.h"

@implementation MessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.imageIcon setRounded:YES];
    [self.labelNum.layer setMasksToBounds:YES];
    self.layer.shouldRasterize = YES; // 光栅化 提高流畅度
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.labelNum layoutIfNeeded];
    [self.labelNum.layer setCornerRadius:self.labelNum.frame.size.height / 2]; // 圆形
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
