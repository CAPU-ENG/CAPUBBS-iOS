//
//  AsyncImageView.m
//  CAPUBBS
//
//  Created by 熊典 on 14-8-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AsyncImageView.h"
#import "ActionPerformer.h"
#import "YLGIFImage.h"
#import "UIImageEffects.h"

@implementation AsyncImageView

@synthesize url = _url;

- (void)setImage:(UIImage *)image {
    if ([self.image isEqual:image]) {
        return;
    }
    if ([self.image isEqual:PLACEHOLDER] && ![self isAnimating]) {
        float animationTime = 0.3;
        [UIView animateWithDuration:animationTime / 2 animations:^{
            [self setAlpha:0.25];
        }completion:^(BOOL finished) {
            if (!finished) { // 动画被打断 一般见于cell重用
                [self setAlpha:1.0];
                [self loadImage];
            }else {
                [super setImage:image];
                [UIView animateWithDuration:animationTime / 2 animations:^{
                    [self setAlpha:1.0];
                }completion:^(BOOL finished) {
                    if (!finished) { // 动画被打断 一般见于cell重用
                        [self loadImage];
                    }
                }];
            }
        }];
    }else {
        [super setImage:image];
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
    [self setImage:[YLGIFImage imageNamed:imageName]];
}

- (void)setUrl:(NSString *)urlToSet {
    _url = [AsyncImageView transIconURL:urlToSet];
    if (_url.length == 0) {
        NSLog(@"Fail to translate icon URL - %@", urlToSet);
        return;
    }
    if ([self isAnimating]) {
        [self stopAnimating];
    }
    if ([self.image isEqual:PLACEHOLDER]) {
        [super setImage:nil];
    }
    [self loadImage];
}

- (void)loadImage {
    [NOTIFICATION removeObserver:self];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:_url]];
    NSData *data = [MANAGER contentsAtPath:filePath];
    NSString *oldInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 一定要在主线程上刷新图片 否则软件崩溃
    if (data.length > 0 && ![oldInfo hasPrefix:@"loading"]) { // 缓存存在的话直接加载缓存
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[DEFAULTS objectForKey:@"simpleView"] boolValue] == YES) {
                [self setImage:[UIImage imageWithData:data]];
            }else {
                [self setImage:[YLGIFImage imageWithData:data]];
            }
        });
        [NOTIFICATION postNotificationName:[@"imageSet" stringByAppendingString:_url] object:nil userInfo:@{@"data": data}];
    }else {
        [self setImage:PLACEHOLDER];
        [NOTIFICATION addObserver:self selector:@selector(loadImage) name:[@"imageGet" stringByAppendingString:_url] object:nil];
        
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
        [self performSelectorInBackground:@selector(startLoadingImage) withObject:nil];
    }
}

- (void)startLoadingImage {
    NSString *imageTag = _url;
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:_url]];
    if (!([[DEFAULTS objectForKey:@"iconOnlyInWifi"] boolValue] && IS_CELLULAR)) {
        // NSLog(@"Load Img - %@", imageTag);
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_url]];
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
            iconUrl = [NSString stringWithFormat:@"http://%@%@", CHEXIE, iconUrl];
        }else if ([iconUrl hasPrefix:@".."]) {
            iconUrl = [NSString stringWithFormat:@"http://%@/bbs/content/%@", CHEXIE, [iconUrl substringFromIndex:@"..".length]];
        }else {
            iconUrl = [NSString stringWithFormat:@"http://%@/bbsimg/i/%@.gif", CHEXIE, iconUrl];
        }
    }
    iconUrl = [iconUrl stringByReplacingOccurrencesOfString:@" " withString:@"%20"]; // URL中有空格的处理
    // NSLog(@"Icon URL:%@", icon);
    return iconUrl;
}

@end
