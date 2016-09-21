//
//  IndexViewCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/8.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "IndexViewCell.h"

@implementation IndexViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.text.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.layer setCornerRadius:self.frame.size.width / 15];
}

@end
