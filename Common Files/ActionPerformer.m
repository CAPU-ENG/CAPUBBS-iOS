//
//  ActionPerformer.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ActionPerformer.h"
#import <CommonCrypto/CommonCrypto.h> // MD5
#import "sys/utsname.h" // 设备型号
#import "CommonDefinitions.h"

@implementation ActionPerformer

#pragma mark Web Request

- (void)performActionWithDictionary:(NSDictionary *)dict toURL:(NSString*)url withBlock:(ActionPerformerResultBlock)block {
    NSString *postUrl = [NSString stringWithFormat:@"%@/api/client.php?ask=%@",CHEXIE, url];
    
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    [requestDictionary setObject:@"ios" forKey:@"os"];
    [requestDictionary setObject:TOKEN forKey:@"token"];
    for (NSString *key in [dict allKeys]) {
        NSString *data = dict[key];
        if ([data hasPrefix:@"@"]) { // 修复字符串首带有@时的错误
            data = [@" " stringByAppendingString:data];
        }
        [requestDictionary setObject:data forKey:key];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [manager POST:postUrl parameters:requestDictionary progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        [responseObject setDelegate:self];
        if (![responseObject parse]) {
            block(nil, [responseObject parserError]);
            NSLog(@"%@", [responseObject parserError]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"加载失败", @"message": @"内容解析出现异常\n请使用网页版查看"}];
        }else {
            block([NSArray arrayWithArray:finalData], nil);
        }
        return;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"%@", error.localizedDescription);
        block(nil, error);
        return;
    }];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"capu"]) {
        finalData = [[NSMutableArray alloc] init];
    }else if ([elementName isEqualToString:@"info"]) {
        tempData = [[NSMutableDictionary alloc] init];
    }else {
        currentString = nil;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"capu"]) {
        return;
    }
    if ([elementName isEqualToString:@"info"]) {
        [finalData addObject:tempData];
    }else {
        [tempData setObject:currentString ? [currentString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] : @"" forKey:elementName];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentString) {
        currentString = [[NSMutableString alloc] init];
    }
    [currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    if (!currentString) {
        currentString = [[NSMutableString alloc] init];
    }
    NSString *string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    [currentString appendString:string];
}

#pragma mark Common Functions

+ (BOOL)checkLogin:(BOOL)showAlert {
    if ([TOKEN length] == 0) { // 判断是否登录的方法为判断token是否为空
        if (showAlert) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"错误", @"message": @"尚未登录"}];
        }
        return NO;
    }else {
        return YES;
    }
}

+ (int)checkRight {
    if ([self checkLogin:NO] && ![USERINFO isEqual:@""]) {
        return [[USERINFO objectForKey:@"rights"] intValue];
    }else {
        return -1;
    }
}

+ (void)checkPasswordLength {
    if ([PASS length] < 6) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
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
    NSDictionary *dict = @{@"x86_64": @"iOS Simulator",
                           
                           @"iPhone8,1": @"iPhone 6s",
                           @"iPhone8,2": @"iPhone 6s Plus",
                           @"iPhone7,1": @"iPhone 6 Plus",
                           @"iPhone7,2": @"iPhone 6",
                           @"iPhone6,1": @"iPhone 5s",
                           @"iPhone6,2": @"iPhone 5s",
                           @"iPhone5,3": @"iPhone 5c",
                           @"iPhone5,4": @"iPhone 5c",
                           @"iPhone5,1": @"iPhone 5",
                           @"iPhone5,2": @"iPhone 5",
                           @"iPhone4,1": @"iPhone 4s",
                           @"iPhone3,1": @"iPhone 4",
                           @"iPhone3,2": @"iPhone 4",
                           @"iPhone3,3": @"iPhone 4",
                           @"iPhone2,1": @"iPhone 3Gs",
                           @"iPhone1,2": @"iPhone 3G",
                           @"iPhone1,1": @"iPhone",
                           
                           @"iPod6,1": @"iPod touch 6",
                           @"iPod5,1": @"iPod touch 5",
                           @"iPod4,1": @"iPod touch 4",
                           @"iPod3,1": @"iPod touch 3",
                           @"iPod2,1": @"iPod touch 2",
                           @"iPod1,1": @"iPod touch",
                           
                           @"iPad6,8": @"iPad Pro",
                           
                           @"iPad5,3": @"iPad Air 2",
                           @"iPad5,4": @"iPad Air 2",
                           @"iPad4,1": @"iPad Air",
                           @"iPad4,2": @"iPad Air",
                           @"iPad4,3": @"iPad Air",
                           @"iPad3,4": @"iPad 4",
                           @"iPad3,5": @"iPad 4",
                           @"iPad3,6": @"iPad 4",
                           @"iPad3,1": @"iPad 3",
                           @"iPad3,2": @"iPad 3",
                           @"iPad3,3": @"iPad 3",
                           @"iPad2,1": @"iPad 2",
                           @"iPad2,2": @"iPad 2",
                           @"iPad2,3": @"iPad 2",
                           @"iPad2,4": @"iPad 2",
                           @"iPad1,1": @"iPad 1",
                           @"iPad1,2": @"iPad 1",
                           
                           @"iPad5,1": @"iPad mini 4",
                           @"iPad5,2": @"iPad mini 4",
                           @"iPad4,7": @"iPad mini 3",
                           @"iPad4,8": @"iPad mini 3",
                           @"iPad4,9": @"iPad mini 3",
                           @"iPad4,4": @"iPad mini 2",
                           @"iPad4,5": @"iPad mini 2",
                           @"iPad4,6": @"iPad mini 2",
                           @"iPad2,5": @"iPad mini",
                           @"iPad2,6": @"iPad mini",
                           @"iPad2,7": @"iPad mini"};
    
    if ([dict[platform] length] > 0) {
        platform = dict[platform];
    }

    // NSLog(@"Platform = %@",platform);
    return platform;
}

@end
