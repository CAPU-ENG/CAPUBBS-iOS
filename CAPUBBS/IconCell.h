//
//  IconCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/3/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface IconCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UIImageView *imageCheck;

@end
