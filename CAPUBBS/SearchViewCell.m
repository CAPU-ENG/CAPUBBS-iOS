//
//  SearchViewCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/6.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "SearchViewCell.h"

@implementation SearchViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
