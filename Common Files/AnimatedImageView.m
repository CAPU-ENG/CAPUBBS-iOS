//
//  AnimatedImageView.m
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AnimatedImageView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImageEffects.h"

@implementation AnimatedImageView {
    NSString * latestUrl;
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
    latestUrl = nil;
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
    latestUrl = nil;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    [self _setGifWithData:fileData];
}

- (void)_setGifWithData:(NSData *)data {
    dispatch_main_async_safe(^{
        SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithData:data];
        [self setImage:image];
    });
}

- (void)setUrl:(NSString *)urlToSet {
    NSString *newUrl = [AnimatedImageView transIconURL:urlToSet];
    if ([newUrl isEqualToString:latestUrl]) {
        return;
    }
    if (newUrl.length == 0) {
        NSLog(@"Failed to translate icon URL - %@", urlToSet);
        return;
    }
    latestUrl = newUrl;
    [self loadImageWithPlaceholder:YES];
}

- (NSString *)getUrl {
    return latestUrl;
}

- (void)loadImageWithPlaceholder:(BOOL)showPlaceholder {
    [NOTIFICATION removeObserver:self];
    NSString *imageUrl = latestUrl;
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", IMAGE_CACHE_PATH, [ActionPerformer md5:imageUrl]];
    NSData *data = [MANAGER contentsAtPath:filePath];
    NSString *oldInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 一定要在主线程上刷新图片 否则软件崩溃
    if (data.length > 0 && ![oldInfo hasPrefix:@"loading"]) { // 缓存存在的话直接加载缓存
        dispatch_main_async_safe(^{
            if (SIMPLE_VIEW == YES) {
                [self setImage:[UIImage imageWithData:data]];
            } else {
                [self _setGifWithData:data];
            }
            if (imageUrl.length > 0) {
                [NOTIFICATION postNotificationName:[@"imageSet" stringByAppendingString:imageUrl] object:nil userInfo:@{@"data": data}];
            }
        });
    } else if (imageUrl.length > 0) {
        if (showPlaceholder) {
            [self setImage:PLACEHOLDER];
        }
        [NOTIFICATION addObserver:self selector:@selector(loadImageWithPlaceholder:) name:[@"imageGet" stringByAppendingString:imageUrl] object:nil];
        
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
        [AnimatedImageView checkPath];
        [MANAGER createFileAtPath:filePath contents:[newInfo dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        dispatch_global_default_async(^{
            [self startLoadingUrl:imageUrl withPlaceholder:showPlaceholder];
        });
    }
}

- (void)startLoadingUrl:(NSString *)imageUrl withPlaceholder:(BOOL)hasPlaceholder {
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", IMAGE_CACHE_PATH, [ActionPerformer md5:imageUrl]];
    BOOL shouldSkipLoading = [[GROUP_DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue] && IS_CELLULAR;
    if (!shouldSkipLoading) {
        // NSLog(@"Load Img - %@", imageUrl);
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:imageData];
        ImageFileType imageType = [AnimatedImageView fileType:imageData];
        if (imageType != ImageFileTypeUnknown) {
            if (![AnimatedImageView isAnimated:imageData]) {
                imageData = [self resizeImage:image];
            }
            // NSLog(@"Icon Type:%@, Size:%dkb", imageType, (int)(imageData.length/1024));
            [AnimatedImageView checkPath];
            [MANAGER createFileAtPath:filePath contents:imageData attributes:nil];
            [NOTIFICATION postNotificationName:[@"imageGet" stringByAppendingString:imageUrl] object:nil];
            return;
        }
    }
    [MANAGER removeItemAtPath:filePath error:nil];
    if (!hasPlaceholder) {
        dispatch_main_async_safe(^{
            [self setImage:PLACEHOLDER];
        });
    }
    if (!shouldSkipLoading) {
        NSLog(@"Image Load Failed - %@", imageUrl);
    }
}

- (NSData *)resizeImage:(UIImage *)oriImage {
    UIImage *resizeImage = oriImage;
    int maxWidth = 450; // 详细信息界面图片大小150 * 150 @3x模式下450 * 450可保证清晰
    if (oriImage.size.width > maxWidth) {
        UIGraphicsBeginImageContext(CGSizeMake(maxWidth, maxWidth*oriImage.size.height/oriImage.size.width));
        [oriImage drawInRect:CGRectMake(0, 0, maxWidth, maxWidth*oriImage.size.height/oriImage.size.width)];
        resizeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(oriImage.CGImage);
    BOOL hasAlpha = (alphaInfo == kCGImageAlphaFirst ||
                     alphaInfo == kCGImageAlphaLast ||
                     alphaInfo == kCGImageAlphaPremultipliedFirst ||
                     alphaInfo == kCGImageAlphaPremultipliedLast);
    if (hasAlpha) { // 带透明信息的png不可转换成jpeg否则丢失透明性
        return UIImagePNGRepresentation(resizeImage);
    } else {
        if (resizeImage.size.width >= maxWidth) {
            return UIImageJPEGRepresentation(resizeImage, 0.75);
        } else {
            return UIImageJPEGRepresentation(resizeImage, 1);
        }
    }
}

+ (BOOL)isAnimated:(NSData *)imageData {
    if (!imageData) {
        return NO;
    }
    SDAnimatedImage *animatedImage = [[SDAnimatedImage alloc] initWithData:imageData];
    return animatedImage && animatedImage.sd_imageFrameCount > 1;
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
        // WebP 在 iOS 14+ 才原生支持，所以对于更早系统不要识别，不然无法渲染
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
    if (![MANAGER fileExistsAtPath:IMAGE_CACHE_PATH]) { // 如果没有IMAGE_CACHE_PATH目录则创建目录
        [MANAGER createDirectoryAtPath:IMAGE_CACHE_PATH withIntermediateDirectories:NO attributes:nil error:nil];
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
