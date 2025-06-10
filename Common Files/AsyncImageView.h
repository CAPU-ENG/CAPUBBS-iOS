//
//  AsyncImageView.h
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <SDWebImage/SDAnimatedImage.h>
#import <SDWebImage/SDAnimatedImageView.h>

#define PLACEHOLDER [UIImage imageNamed:@"placeholder"]
#define CACHE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/IconCache"]

typedef NS_ENUM(int, ImageFileType) {
    ImageFileTypeUnknown = 0,
    ImageFileTypeJPEG,
    ImageFileTypePNG,
    ImageFileTypeGIF,
    ImageFileTypeHEIC,
    ImageFileTypeHEIF,
    ImageFileTypeWEBP  // iOS 14+
};

@interface AsyncImageView : SDAnimatedImageView

- (void)setRounded:(BOOL)isRounded;
- (void)setBlurredImage:(UIImage *)image animated:(BOOL)animated;
- (void)setGif:(NSString *)imageName;
- (void)setUrl:(NSString *)urlToSet;
- (void)setUrl:(NSString *)urlToSet withPlaceholder:(BOOL)showPlaceholder;
- (NSString *)getUrl;
+ (NSString *)transIconURL:(NSString *)iconUrl;
+ (ImageFileType)fileType:(NSData *)imageData;
+ (NSString *)fileExtension:(ImageFileType)type;
+ (void)checkPath;

@end
