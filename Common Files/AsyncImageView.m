//
//  AsyncImageView.m
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AsyncImageView.h"
#import <MobileCoreServices/MobileCoreServices.h>
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
    float animationTime = 0.5;
    image = [UIImageEffects imageByApplyingExtraLightEffectToImage:image];
    if (animated) {
        if (self.image) { // 原本有图片
            [UIView animateWithDuration:animationTime / 2 animations:^{
                [self setAlpha:0.25];
            } completion:^(BOOL finished) {
                [self setImage:image];
                [UIView animateWithDuration:animationTime / 2 animations:^{
                    [self setAlpha:1.0];
                }];
            }];
        } else {
            [self setAlpha:0.0];
            [self setImage:image];
            [UIView animateWithDuration:animationTime animations:^{
                [self setAlpha:1.0];
            }];
        }
    } else {
        [self setImage:image];
    }
}

- (void)setGif:(NSString *)imageName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    [self setGifWithData:fileData];
}

- (void)setGifWithData:(NSData *)data {
    dispatch_main_async_safe(^{
        SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithData:data];
        [self setImage:image];
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
            } else {
                [self setGifWithData:data];
            }
            [NOTIFICATION postNotificationName:[@"imageSet" stringByAppendingString:url] object:nil userInfo:@{@"data": data}];
        });
    } else if (url.length > 0) {
        if (showPlaceholder) {
            [self setImage:PLACEHOLDER];
        }
        [NOTIFICATION addObserver:self selector:@selector(loadImageWithPlaceholder:) name:[@"imageGet" stringByAppendingString:url] object:nil];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
        [formatter setTimeZone:beijingTimeZone];
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
    }
}

- (void)startLoadingImage:(BOOL)hasPlaceholder {
    NSString *imageTag = url;
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:url]];
    if (!([[GROUP_DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue] && IS_CELLULAR)) {
        // NSLog(@"Load Img - %@", imageTag);
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image = [UIImage imageWithData:imageData];
        ImageFileType imageType = [AsyncImageView fileType:imageData];
        if (imageType != ImageFileTypeUnknown) {
            if (imageType != ImageFileTypeGIF) {
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

- (NSData *)resizeImage:(UIImage *)oriImage imageType:(ImageFileType)type {
    UIImage *resizeImage = oriImage;
    int maxWidth = 450; // 详细信息界面图片大小150 * 150 @3x模式下450 * 450可保证清晰
    if (oriImage.size.width > maxWidth) {
        UIGraphicsBeginImageContext(CGSizeMake(maxWidth, maxWidth*oriImage.size.height/oriImage.size.width));
        [oriImage drawInRect:CGRectMake(0, 0, maxWidth, maxWidth*oriImage.size.height/oriImage.size.width)];
        resizeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    if (type == ImageFileTypePNG) { // 带透明信息的png不可转换成jpeg否则丢失透明性
        return UIImagePNGRepresentation(resizeImage);
    } else {
        if (resizeImage.size.width >= maxWidth) {
            return UIImageJPEGRepresentation(resizeImage, 0.75);
        } else {
            return UIImageJPEGRepresentation(resizeImage, 1);
        }
    }
}

+ (ImageFileType)fileType:(NSData *)imageData {
    if (!imageData || imageData.length == 0) {
        return ImageFileTypeUnknown;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (!source) {
        return ImageFileTypeUnknown;
    }

    CFStringRef uti = CGImageSourceGetType(source);
    CFRelease(source);

    if (!uti) {
        return ImageFileTypeUnknown;
    }

    if (UTTypeConformsTo(uti, kUTTypeJPEG)) {
        return ImageFileTypeJPEG;
    }
    if (UTTypeConformsTo(uti, kUTTypePNG)) {
        return ImageFileTypePNG;
    }
    if (UTTypeConformsTo(uti, kUTTypeGIF)) {
        return ImageFileTypeGIF;
    }
    if (UTTypeConformsTo(uti, (__bridge CFStringRef)@"public.heic")) {
        return ImageFileTypeHEIC;
    }
    if (UTTypeConformsTo(uti, (__bridge CFStringRef)@"public.heif")) {
        return ImageFileTypeHEIF;
    }
    if (@available(iOS 14.0, *)) {
        // WebP 在 iOS 14+ 才原生支持
        if (UTTypeConformsTo(uti, (__bridge CFStringRef)@"public.webp") ||
            UTTypeConformsTo(uti, (__bridge CFStringRef)@"org.webmproject.webp")) {
            return ImageFileTypeWEBP;
        }
    }

    return ImageFileTypeUnknown;
}

+ (NSString *)fileExtension:(ImageFileType)type {
    switch (type) {
        case ImageFileTypeJPEG:
            return @"jpg";
        case ImageFileTypePNG:
            return @"png";
        case ImageFileTypeGIF:
            return @"gif";
        case ImageFileTypeHEIC:
            return @"heic";
        case ImageFileTypeHEIF:
            return @"heif";
        case ImageFileTypeWEBP:
            return @"webp";
        case ImageFileTypeUnknown:
        default:
            return nil;
    }
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
        } else if ([iconUrl hasPrefix:@".."]) {
            iconUrl = [NSString stringWithFormat:@"%@/bbs/content/%@", CHEXIE, [iconUrl substringFromIndex:@"..".length]];
        } else {
            iconUrl = [NSString stringWithFormat:@"%@/bbsimg/i/%@.gif", CHEXIE, iconUrl];
        }
    }
    iconUrl = [iconUrl stringByReplacingOccurrencesOfString:@" " withString:@"%20"]; // URL中有空格的处理
    // NSLog(@"Icon URL:%@", icon);
    return iconUrl;
}

@end
