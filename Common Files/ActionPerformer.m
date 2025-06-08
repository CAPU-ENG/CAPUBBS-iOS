//
//  ActionPerformer.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ActionPerformer.h"
#import "XMLDictionary.h" // XML parsing
#import <CommonCrypto/CommonCrypto.h> // MD5
#import "sys/utsname.h" // 设备型号

@implementation ActionPerformer

#pragma mark Web Request

- (NSString *)encodeURIComponent:(NSString *)string {
    if (!allowedCharacters) {
        allowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* "];
    }
    NSString *encoded = [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    return [encoded stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

/**
 * 强制以UTF-8解码，并将所有无效的字节序列替换为指定内容
 * @param corruptData 从服务器接收的可能已损坏的NSData
 * @param replacement 无效字节的替换，默认为空（跳过）
 * @return 清理和解码后的NSString
 */
- (NSString *)forceDecodeUTF8StringFromData:(NSData *)corruptData replacement:(NSString *)replacement {
    if (!corruptData || corruptData.length == 0) {
        return nil;
    }

    // 预先创建问号的NSData对象，以便在循环中复用
    NSData *replacementData = [replacement ?: @"" dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *cleanedData = [NSMutableData dataWithCapacity:corruptData.length];
    const unsigned char *bytes = (const unsigned char *)[corruptData bytes];
    NSUInteger length = corruptData.length;
    NSUInteger i = 0;

    while (i < length) {
        unsigned char leadByte = bytes[i];
        NSUInteger sequenceLength = 0;

        if ((leadByte & 0x80) == 0) { // 0xxxxxxx -> ASCII
            sequenceLength = 1;
        } else if ((leadByte & 0xE0) == 0xC0) { // 110xxxxx
            sequenceLength = 2;
        } else if ((leadByte & 0xF0) == 0xE0) { // 1110xxxx
            sequenceLength = 3;
        } else if ((leadByte & 0xF8) == 0xF0) { // 11110xxx
            sequenceLength = 4;
        } else {
            // 发现无效的UTF-8起始字节
            [cleanedData appendData:replacementData];
            i++;
            continue; // 继续下一个字节
        }

        if (i + sequenceLength > length) {
            // 数据末尾不足以构成一个完整序列，将其视为错误
            [cleanedData appendData:replacementData];
            break; // 结束循环
        }

        NSData *sequenceData = [NSData dataWithBytes:&bytes[i] length:sequenceLength];
        BOOL isValid = [[NSString alloc] initWithData:sequenceData encoding:NSUTF8StringEncoding] != nil;
        // 这样性能更高，但可能在极端情况下出错
//        BOOL isValid = YES;
//        for (NSUInteger j = 1; j < sequenceLength; j++) {
//            if ((bytes[i + j] & 0xC0) != 0x80) { // 非起始字节必须是 10xxxxxx
//                isValid = NO;
//                break;
//            }
//        }

        if (isValid) {
            // 这是一个有效的序列，直接追加原始字节
            [cleanedData appendData:sequenceData];
        } else {
            // 这是一个无效的序列 (例如，起始字节有效，但后续字节错误)
            [cleanedData appendData:replacementData];
        }
        
        // 移动指针到下一个序列的开始
        i += sequenceLength;
    }

    // 用清理过的数据最终生成字符串
    return [[NSString alloc] initWithData:cleanedData encoding:NSUTF8StringEncoding];
}

- (void)performActionWithDictionary:(NSDictionary *)dict toURL:(NSString*)url withBlock:(ActionPerformerResultBlock)block {
    NSString *postUrl = [NSString stringWithFormat:@"%@/api/client.php?ask=%@",CHEXIE, url];
    
    NSMutableDictionary *requestDict = [@{
        @"os": @"ios",
        @"device": [ActionPerformer doDevicePlatform],
        @"version": [[UIDevice currentDevice] systemVersion],
        @"clientversion": APP_VERSION,
        @"clientbuild": APP_BUILD,
        @"token": TOKEN
    } mutableCopy];
    for (NSString *key in [dict allKeys]) {
        NSString *data = dict[key];
        if ([data hasPrefix:@"@"]) { // 修复字符串首带有@时的错误
            data = [@" " stringByAppendingString:data];
        }
        requestDict[key] = data;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest
                                    requestWithURL:[NSURL URLWithString:postUrl]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30;
    
    // Convert parameters to x-www-form-urlencoded (or JSON, depending on server)
    NSMutableArray *bodyParts = [NSMutableArray array];
    [requestDict enumerateKeysAndObjectsUsingBlock:^(id key,
                                                           id obj,
                                                           BOOL *stop) {
        NSString *part = [NSString stringWithFormat:@"%@=%@",
                          [self encodeURIComponent: key],
                          [self encodeURIComponent: obj]];
        [bodyParts addObject:part];
    }];
    NSString *bodyString = [bodyParts componentsJoinedByString:@"&"];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = bodyData;
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"API POST error: %@", error);
            dispatch_main_async_safe(^{
                block(nil, error);
            });
            return;
        }
        
        BOOL hasError = NO;
        // Sanity check by encoding to UTF-8. Otherwise it might fail silently with lost data.
        NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!xmlString) {
            NSLog(@"API data corrupted, attempting to recover...");
            xmlString = [self forceDecodeUTF8StringFromData:data replacement:@"�"];
            if (!xmlString) {
                NSLog(@"API data recovery failed!");
                hasError = YES;
            } else {
                NSLog(@"API data recovery success!");
            }
        }
        NSDictionary *xmlData = [NSDictionary dictionaryWithXMLString:xmlString];
        if (!xmlData || ![xmlData[@"__name"] isEqualToString:@"capu"]) {
            hasError = YES;
        }
        if (hasError) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlert"
                                                                object:nil
                                                              userInfo:@{@"title": @"加载失败",
                                                                         @"message": @"内容解析出现异常\n请使用网页版查看"}];
            dispatch_main_async_safe(^{
                block(nil, [NSError errorWithDomain:@"XMLParsing" code:0 userInfo:@{NSLocalizedDescriptionKey: @"XML parsing failed"}]);
            });
        } else {
            id info = xmlData[@"info"];
            NSArray *result;
            if (!info) {
                result = @[];
            } else if ([info isKindOfClass:[NSArray class]]) {
                result = info;
            } else {
                result = @[info];
            }
            dispatch_main_async_safe(^{
                block(result, nil);
            });
        }
    }];
    [task resume];
}

#pragma mark Common Functions

+ (BOOL)checkLogin:(BOOL)showAlert {
    if ([TOKEN length] == 0) { // 判断是否登录的方法为判断token是否为空
        if (showAlert) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"错误", @"message": @"尚未登录"}];
        }
        return NO;
    } else {
        return YES;
    }
}

+ (int)checkRight {
    if ([self checkLogin:NO] && ![USERINFO isEqual:@""]) {
        return [[USERINFO objectForKey:@"rights"] intValue];
    } else {
        return -1;
    }
}

+ (void)checkPasswordLength {
    if ([PASS length] < 6) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
        [formatter setTimeZone:beijingTimeZone];
        NSDate *currentDate = [NSDate date];
        NSDate *lastDate =[formatter dateFromString:[DEFAULTS objectForKey:@"checkPass"]];
        NSTimeInterval time = [currentDate timeIntervalSinceDate:lastDate];
        if ((int)time > 3600 * 24) { // 每天提醒一次
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"提醒", @"message": @"您的密码过于简单！\n建议在个人信息中修改密码", @"cancelTitle": @"今日不再提醒"}];
            [DEFAULTS setObject:[formatter stringFromDate:currentDate] forKey:@"checkPass"];
        }
    }
}

+ (NSString *)removeRe:(NSString *)text {
    BOOL remove = YES;
    while (remove) {
        remove = NO;
        if ([text hasPrefix:@"Re:"] || [text hasPrefix:@"Re："]) {
            remove = YES;
            text = [text substringFromIndex:@"Re:".length];
        }
        if ([text hasPrefix:@" "]) {
            remove = YES;
            text = [text substringFromIndex:@" ".length];
        }
    }
    return text;
}

+ (NSString *)getBoardTitle:(NSString *)bid {
    NSArray *titles = @[@"车协工作区", @"行者足音", @"车友宝典", @"纯净水", @"考察与社会", @"五湖四海", @"一技之长", @"竞赛竞技", @"网站维护"];
    if ([bid hasPrefix:@"b"]) {
        bid = [bid substringFromIndex:@"b".length];
    }
    for (int i = 0; i < NUMBERS.count; i++) {
        if ([bid isEqualToString:[NUMBERS objectAtIndex:i]]) {
            return [titles objectAtIndex:i];
        }
    }
    return @"未知版面";
}

+ (NSString *)md5:(NSString *)str { // 字符串MD5值算法
    if (!str || str.length == 0) {
        return @"";
    }
    const char* cStr=[str UTF8String];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; // CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(cStr, (unsigned int)strlen(cStr), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++) {
        [outPutStr appendFormat:@"%02X", digist[i]];// 小写 x 表示输出的是小写 MD5 ，大写 X 表示输出的是大写 MD5
    }
    return outPutStr;
}

+ (NSString *)doDevicePlatform { // 获取设备信息
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // return platform;
    NSDictionary *dict = @{
        // Simulator
        @"x86_64": @"iOS Simulator",
        @"arm64": @"iOS Simulator",
        
        //        @"iPhone8,1": @"iPhone 6s",
        //        @"iPhone8,2": @"iPhone 6s Plus",
        //        @"iPhone7,1": @"iPhone 6 Plus",
        //        @"iPhone7,2": @"iPhone 6",
        //        @"iPhone6,1": @"iPhone 5s",
        //        @"iPhone6,2": @"iPhone 5s",
        //        @"iPhone5,3": @"iPhone 5c",
        //        @"iPhone5,4": @"iPhone 5c",
        //        @"iPhone5,1": @"iPhone 5",
        //        @"iPhone5,2": @"iPhone 5",
        //        @"iPhone4,1": @"iPhone 4s",
        //        @"iPhone3,1": @"iPhone 4",
        //        @"iPhone3,2": @"iPhone 4",
        //        @"iPhone3,3": @"iPhone 4",
        //        @"iPhone2,1": @"iPhone 3Gs",
        //        @"iPhone1,2": @"iPhone 3G",
        //        @"iPhone1,1": @"iPhone",
        //
        //        @"iPod6,1": @"iPod touch 6",
        //        @"iPod5,1": @"iPod touch 5",
        //        @"iPod4,1": @"iPod touch 4",
        //        @"iPod3,1": @"iPod touch 3",
        //        @"iPod2,1": @"iPod touch 2",
        //        @"iPod1,1": @"iPod touch",
        //
        //        @"iPad6,8": @"iPad Pro",
        //
        //        @"iPad5,3": @"iPad Air 2",
        //        @"iPad5,4": @"iPad Air 2",
        //        @"iPad4,1": @"iPad Air",
        //        @"iPad4,2": @"iPad Air",
        //        @"iPad4,3": @"iPad Air",
        //        @"iPad3,4": @"iPad 4",
        //        @"iPad3,5": @"iPad 4",
        //        @"iPad3,6": @"iPad 4",
        //        @"iPad3,1": @"iPad 3",
        //        @"iPad3,2": @"iPad 3",
        //        @"iPad3,3": @"iPad 3",
        //        @"iPad2,1": @"iPad 2",
        //        @"iPad2,2": @"iPad 2",
        //        @"iPad2,3": @"iPad 2",
        //        @"iPad2,4": @"iPad 2",
        //        @"iPad1,1": @"iPad 1",
        //        @"iPad1,2": @"iPad 1",
        //
        //        @"iPad5,1": @"iPad mini 4",
        //        @"iPad5,2": @"iPad mini 4",
        //        @"iPad4,7": @"iPad mini 3",
        //        @"iPad4,8": @"iPad mini 3",
        //        @"iPad4,9": @"iPad mini 3",
        //        @"iPad4,4": @"iPad mini 2",
        //        @"iPad4,5": @"iPad mini 2",
        //        @"iPad4,6": @"iPad mini 2",
        //        @"iPad2,5": @"iPad mini",
        //        @"iPad2,6": @"iPad mini",
        //        @"iPad2,7": @"iPad mini",
    };
    
    if ([dict[platform] length] > 0) {
        platform = dict[platform];
    }
    
    // NSLog(@"Platform = %@",platform);
    return platform;
}

@end
