//
//  ActionPerformer.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequestDelegate.h"
#import "ASIHTTPRequest.h"
typedef void (^ActionPerformerResultBlock)(NSArray* result,NSError* err);

@interface ActionPerformer : NSObject<NSURLConnectionDataDelegate,NSXMLParserDelegate,ASIHTTPRequestDelegate>{
    ActionPerformerResultBlock resultBlock;
    NSURLConnection *connection;
    NSMutableData *respondData;
    
    NSMutableArray *finalData;
    NSString *currentField;
    NSMutableString *currentString;
    NSMutableDictionary *tempData;
    ASIHTTPRequest *request;
    
    BOOL testToggle;
    NSDictionary *tempDict;
    NSString *tempURL;
}
-(void)performActionWithDictionary:(NSDictionary*)dict toURL:(NSString*)url withBlock:(ActionPerformerResultBlock)block;

@end
