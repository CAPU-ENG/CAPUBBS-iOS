//
//  ActionPerformer.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReachabilityManager.h"

typedef void (^ActionPerformerResultBlock)(NSArray* result, NSError* err);

@interface ActionPerformer: NSObject <NSXMLParserDelegate> {
    NSCharacterSet *allowedCharacters;
    NSMutableArray *finalData;
    NSMutableString *currentString;
    NSMutableDictionary *tempData;
}

- (void)performActionWithDictionary:(NSDictionary*)dict toURL:(NSString*)url withBlock:(ActionPerformerResultBlock)block;
+ (BOOL)checkLogin:(BOOL)showAlert;
+ (int)checkRight;
+ (void)checkPasswordLength;
+ (NSString *)removeRe:(NSString *)text;
+ (NSString *)getBoardTitle:(NSString *)bid;
+ (NSString *)md5:(NSString *)str;
+ (NSString *)doDevicePlatform;

@end
