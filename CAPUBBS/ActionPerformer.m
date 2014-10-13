//
//  ActionPerformer.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ActionPerformer.h"
#import "IPGetter.h"

@implementation ActionPerformer
- (void)performActionWithDictionary:(NSDictionary *)dict toURL:(NSString*)url withBlock:(ActionPerformerResultBlock)block{
    resultBlock=block;

//    NSString *ip=[IPGetter getIPAddress];
    request=[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.chexie.net/api/client.php?ask=%@",url]]];

    tempDict=dict;
    tempURL=url;
    NSMutableString *tempS=[NSMutableString string];
    for (NSString *key in [dict allKeys]) {
//        NSLog(@"%@=%@",key,[dict objectForKey:key]);
//        NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *data=[dict objectForKey:key];
//        data=[data stringByAddingPercentEscapesUsingEncoding:gbkEncoding];
//        data=[data stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?#[]\""] invertedSet]];
        data=[data stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [tempS appendFormat:@"%@=%@&",key,data];
    }
    [tempS appendFormat:@"os=ios&token=%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"token"]];
    if (tempS.length!=0) {
        [request setPostBody:[NSMutableData dataWithData:[tempS dataUsingEncoding:NSUTF8StringEncoding]]];
        [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
        [request setRequestMethod:@"POST"];

    }
    [request setDelegate:self];
    NSLog(@"request started");

    [request startAsynchronous];
}
-(void)sayYes{
    resultBlock(@[[NSDictionary dictionaryWithObjectsAndKeys:@"0",@"d", nil]],nil);
}
-(void)sayNo{
    resultBlock(@[[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"d", nil]],nil);
}
- (void)requestFailed:(ASIHTTPRequest *)requestcur{
    resultBlock(nil,requestcur.error);
    [self cleanup];
}
-(void)requestFinished:(ASIHTTPRequest *)requestcur{
    NSLog(@"request finished");
    [request setResponseEncoding:NSUTF8StringEncoding];
    NSXMLParser *parser=[[NSXMLParser alloc] initWithData:[requestcur responseData]];
    [parser setDelegate:self];

    if(![parser parse]){
        resultBlock(nil,[parser parserError]);
        NSLog(@"%@",request.responseString);
    }else{
        resultBlock([NSArray arrayWithArray:finalData],nil);
    }
    [self cleanup];
}
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
//    [respondData appendData:data];
//}
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
//    NSXMLParser *parser=[[NSXMLParser alloc] initWithData:respondData];
//    [parser setDelegate:self];
//    if(![parser parse]){
//        resultBlock(nil,[parser parserError]);
//    }else{
//        resultBlock([NSArray arrayWithArray:finalData],nil);
//    }
//    [self cleanup];
//}
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
//    resultBlock(nil,error);
//    [self cleanup];
//}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    if ([elementName isEqualToString:@"capu"]) {
        finalData=[[NSMutableArray alloc] init];
    }else if ([elementName isEqualToString:@"info"]) {
        tempData=[[NSMutableDictionary alloc] init];
    }else{
        currentString=nil;
    }
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"capu"]) {
        
    }else if ([elementName isEqualToString:@"info"]){
        [finalData addObject:tempData];
    }else{
        [tempData setObject:currentString?[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]:@"" forKey:elementName];
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if (!currentString) {
        currentString=[[NSMutableString alloc] init];
    }
    [currentString appendString:string];
}
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{
    if (!currentString) {
        currentString=[[NSMutableString alloc] init];
    }
    [currentString appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}
-(void)cleanup{
    resultBlock=nil;
    respondData=nil;
    connection=nil;
    request=nil;
}
@end
