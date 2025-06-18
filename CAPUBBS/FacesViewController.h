//
//  FacesViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/3/9.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FacesViewCell.h"

@interface FacesViewController : CustomCollectionViewController {
    AnimatedImageView *previewImageView;
}

@property int numberOfFaces;

@end
