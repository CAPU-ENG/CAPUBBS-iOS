//
//  IconCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "IconCell.h"

@implementation IconCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.icon.layer setBorderColor:GREEN_LIGHT.CGColor];
    [self.icon.layer setMasksToBounds:YES];
    self.layer.shouldRasterize = YES; // 光栅化 提高流畅度
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end
