//
//  IndexViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"
#import "IndexViewCell.h"
#import "MBProgressHUD.h"

@interface IndexViewController : UIViewController<UICollectionViewDelegate>{
    ActionPerformer *performer;
    MBProgressHUD *hud;
    BOOL shouldVibrate;
    int cellWidth;
    int cellHeight;
    int cellSpace;
    int fontSize;
}

@property (weak, nonatomic) IBOutlet UIButton *buttonHot;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonUser;

@end
