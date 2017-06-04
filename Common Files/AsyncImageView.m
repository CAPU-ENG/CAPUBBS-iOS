//
//  AsyncImageView.m
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AsyncImageView.h"
#import "ActionPerformer.h"
#import "CommonDefinitions.h"
#import "UIImageEffects.h"

@implementation AsyncImageView {
    NSString * url;
    BOOL rounded;
}

- (void)setRounded:(BOOL)isRounded {
    rounded = isRounded;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.masksToBounds = YES;
    if (rounded) {
        self.layer.cornerRadius = self.frame.size.width / 2;
    } else {
        self.layer.cornerRadius = 0.0f;
    }
}

- (void)setBlurredImage:(UIImage *)image animated:(BOOL)animated {
    float animationTime = 1.0;
    image = [UIImageEffects imageByApplyingExtraLightEffectToImage:image];
    if (animated) {
        if (self.image) { // 原本有图片
            [UIView animateWithDuration:animationTime / 2 animations:^{
                [self setAlpha:0.25];
            }completion:^(BOOL finished) {
                [self setImage:image];
                [UIView animateWithDuration:animationTime / 2 animations:^{
                    [self setAlpha:1.0];
                }];
            }];
        }else {
            [self setAlpha:0.0];
            [self setImage:image];
            [UIView animateWithDuration:animationTime animations:^{
                [self setAlpha:1.0];
            }];
        }
    }else {
        [self setImage:image];
    }
}

- (void)setGif:(NSString *)imageName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    [self _setGifWithData:fileData];
}

- (void)_setGifWithData:(NSData *)data {
    dispatch_global_default_async(^{
        FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setAnimatedImage:image];
        });
    });
}

- (void)setUrl:(NSString *)urlToSet {
    [self setUrl:urlToSet withPlaceholder:YES];
}

- (void)setUrl:(NSString *)urlToSet withPlaceholder:(BOOL)showPlaceholder {
    url = [AsyncImageView transIconURL:urlToSet];
    if (url.length == 0) {
        NSLog(@"Fail to translate icon URL - %@", urlToSet);
        return;
    }
    
    [self loadImageWithPlaceholder:showPlaceholder];
}

- (NSString *)getUrl {
    return url;
}

- (void)loadImageWithPlaceholder:(BOOL)showPlaceholder {
    [NOTIFICATION removeObserver:self];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:url]];
    NSData *data = [MANAGER contentsAtPath:filePath];
    NSString *oldInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 一定要在主线程上刷新图片 否则软件崩溃
    if (data.length > 0 && ![oldInfo hasPrefix:@"loading"]) { // 缓存存在的话直接加载缓存
        dispatch_main_async_safe(^{
            if (SIMPLE_VIEW == YES) {
                [self setImage:[UIImage imageWithData:data]];
            }else {
                int imageType = [AsyncImageView fileType:data];
                if (imageType == GIF_TYPE) {
                    [self _setGifWithData:data];
                } else {
                    [self setImage:[UIImage imageWithData:data]];
                }
            }
            [NOTIFICATION postNotificationName:[@"imageSet" stringByAppendingString:url] object:nil userInfo:@{@"data": data}];
        });
    }else if (url.length > 0) {
        if (showPlaceholder) {
            [self setImage:PLACEHOLDER];
        }
        [NOTIFICATION addObserver:self selector:@selector(loadImageWithPlaceholder:) name:[@"imageGet" stringByAppendingString:url] object:nil];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        if ([oldInfo hasPrefix:@"loading"]) {
            NSDate *oldDate = [formatter dateFromString:[oldInfo substringFromIndex:@"loading".length]];
            if ([[NSDate date] timeIntervalSinceDate:oldDate] < 60) { // 上次加载图片时间不超过一分钟
                return;
            }
        }
        NSString *newInfo = [@"loading" stringByAppendingString:[formatter stringFromDate:[NSDate date]]];
        [AsyncImageView checkPath];
        [MANAGER createFileAtPath:filePath contents:[newInfo dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        dispatch_global_default_async(^{
            [self startLoadingImage:showPlaceholder];
        });
        dispatch_global_default_async(^{
            [self startLoadingImage:showPlaceholder];
        });
    }
}

- (void)startLoadingImage:(BOOL)hasPlaceholder {
    NSString *imageTag = url;
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:url]];
    if (!([[GROUP_DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue] && IS_CELLULAR)) {
        // NSLog(@"Load Img - %@", imageTag);
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image = [UIImage imageWithData:imageData];
        int imageType = [AsyncImageView fileType:imageData];
        if (image) {
            if (imageType != GIF_TYPE) {
                imageData = [self resizeImage:image imageType:imageType];
            }
            // NSLog(@"Icon Type:%@, Size:%dkb", imageType, (int)(imageData.length/1024));
            [AsyncImageView checkPath];
            [MANAGER createFileAtPath:filePath contents:imageData attributes:nil];
            [NOTIFICATION postNotificationName:[@"imageGet" stringByAppendingString:imageTag] object:nil];
            return;
        }
    }
    [MANAGER removeItemAtPath:filePath error:nil];
    if (!hasPlaceholder) {
        dispatch_main_async_safe(^{
            [self setImage:PLACEHOLDER];
        });
    }
    NSLog(@"Icon Load Failed - %@", imageTag);
}

- (NSData *)resizeImage:(UIImage *)oriImage imageType:(int)type {
    UIImage *resizeImage = oriImage;
    int maxWidth = 450; // 详细信息界面图片大小150 * 150 @3x模式下450 * 450可保证清晰
    if (oriImage.size.width > maxWidth) {
        UIGraphicsBeginImageContext(CGSizeMake(maxWidth, maxWidth*oriImage.size.height/oriImage.size.width));
        [oriImage drawInRect:CGRectMake(0, 0, maxWidth, maxWidth*oriImage.size.height/oriImage.size.width)];
        resizeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    if (type == PNG_TYPE) { // 带透明信息的png不可转换成jpeg否则丢失透明性
        return UIImagePNGRepresentation(resizeImage);
    }else {
        if (resizeImage.size.width >= maxWidth) {
            return UIImageJPEGRepresentation(resizeImage, 0.75);
        }else {
            return UIImageJPEGRepresentation(resizeImage, 1);
        }
    }
}

+ (int)fileType:(NSData *)imageData {
    if (imageData.length > 4) {
        const unsigned char * bytes = [imageData bytes];
        
        if (bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff) {
            return JPEG_TYPE;
        }
        
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47) {
            return PNG_TYPE;
        }
        
        if (bytes[0] == 0x47 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46) {
            return GIF_TYPE;
        }
    }
    return -1;
}

+ (void)checkPath {
    if (![MANAGER fileExistsAtPath:CACHE_PATH]) { // 如果没有CACHE_PATH目录则创建目录
        [MANAGER createDirectoryAtPath:CACHE_PATH withIntermediateDirectories:NO attributes:nil error:nil];
    }
}

+ (NSString *)transIconURL:(NSString *)iconUrl { // 转换用户头像地址函数
    if (iconUrl.length == 0) {
        return @"";
    }
    if (!([iconUrl hasPrefix:@"http://"] || [iconUrl hasPrefix:@"https://"] || [iconUrl hasPrefix:@"ftp://"])) {
        if ([iconUrl hasPrefix:@"/"]) {
            iconUrl = [NSString stringWithFormat:@"%@%@", CHEXIE, iconUrl];
        }else if ([iconUrl hasPrefix:@".."]) {
            iconUrl = [NSString stringWithFormat:@"%@/bbs/content/%@", CHEXIE, [iconUrl substringFromIndex:@"..".length]];
        }else {
            iconUrl = [NSString stringWithFormat:@"%@/bbsimg/i/%@.gif", CHEXIE, iconUrl];
        }
    }
    iconUrl = [iconUrl stringByReplacingOccurrencesOfString:@" " withString:@"%20"]; // URL中有空格的处理
    // NSLog(@"Icon URL:%@", icon);
    return iconUrl;
}

@end
