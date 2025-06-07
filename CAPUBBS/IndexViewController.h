//
//  IndexViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndexViewCell.h"

@interface IndexViewController : CustomViewController<UICollectionViewDelegate> {
    ActionPerformer *performer;
    MBProgressHUD *hud;
    BOOL shouldVibrate;
    CGFloat cellWidth;
    CGFloat cellHeight;
    CGFloat cellSpace;
    CGFloat cellMargin;
    CGFloat fontSize;
}

@property (weak, nonatomic) IBOutlet UIButton *buttonHot;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonUser;

@end
