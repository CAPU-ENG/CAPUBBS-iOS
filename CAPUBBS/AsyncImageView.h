//
//  AsyncImageView.h
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "FLAnimatedImage.h"

#define PLACEHOLDER [UIImage imageNamed:@"placeholder"]
#define CACHE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/IconCache"]

#define JPEG_TYPE 0
#define PNG_TYPE 1
#define GIF_TYPE 2

@interface AsyncImageView : FLAnimatedImageView

- (void)setRounded:(BOOL)isRounded;
- (void)setBlurredImage:(UIImage *)image animated:(BOOL)animated;
- (void)setGif:(NSString *)imageName;
- (void)setUrl:(NSString *)urlToSet;
- (NSString *)getUrl;
+ (NSString *)transIconURL:(NSString *)iconUrl;
+ (int)fileType:(NSData *)imageData;
+ (void)checkPath;

@end
