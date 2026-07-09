//
//  Helper.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "Helper.h"
#import <CommonCrypto/CommonCrypto.h> // MD5
#import "sys/utsname.h" // 设备型号
#import "XMLDictionary.h" // XML parsing
#import "CommonDefinitions.h"
#import "Downloader.h"
#import "ReachabilityManager.h"

#define LINE_BREAK @"\r\n"

@implementation Helper

#pragma mark Web Request

+ (NSString *)getFileImage:(NSString *)fileName {
    static NSSet *extensions;
    static dispatch_once_t onceExtToken;
    dispatch_once(&onceExtToken, ^{
        extensions = [NSSet setWithObjects:@"3g2", @"3ga", @"3gp", @"7z", @"aa", @"aac", @"ac", @"accdb", @"accdt", @"ace", @"adn", @"ai", @"aif", @"aifc", @"aiff", @"ait", @"amr", @"ani", @"apk", @"app", @"applescript", @"asax", @"asc", @"ascx", @"asf", @"ash", @"ashx", @"asm", @"asmx", @"asp", @"aspx", @"asx", @"au", @"aup", @"avi", @"axd", @"aze", @"bak", @"bash", @"bat", @"bin", @"blank", @"bmp", @"bowerrc", @"bpg", @"browser", @"bz2", @"bzempty", @"c", @"cab", @"cad", @"caf", @"cal", @"cd", @"cdda", @"cer", @"cfg", @"cfm", @"cfml", @"cgi", @"chm", @"class", @"cmd", @"code-workspace", @"codekit", @"coffee", @"coffeelintignore", @"com", @"compile", @"conf", @"config", @"cpp", @"cptx", @"cr2", @"crdownload", @"crt", @"crypt", @"cs", @"csh", @"cson", @"csproj", @"css", @"csv", @"cue", @"cur", @"dart", @"dat", @"data", @"db", @"dbf", @"deb", @"default", @"dgn", @"dist", @"diz", @"dll", @"dmg", @"dng", @"doc", @"docb", @"docm", @"docx", @"dot", @"dotm", @"dotx", @"download", @"dpj", @"ds_store", @"dsn", @"dtd", @"dwg", @"dxf", @"editorconfig", @"el", @"elf", @"eml", @"enc", @"eot", @"eps", @"epub", @"eslintignore", @"exe", @"f4v", @"fax", @"fb2", @"fla", @"flac", @"flv", @"fnt", @"fon", @"gadget", @"gdp", @"gem", @"gif", @"gitattributes", @"gitignore", @"go", @"gpg", @"gpl", @"gradle", @"gz", @"h", @"handlebars", @"hbs", @"heic", @"hlp", @"hs", @"hsl", @"htm", @"html", @"ibooks", @"icns", @"ico", @"ics", @"idx", @"iff", @"ifo", @"image", @"img", @"iml", @"in", @"inc", @"indd", @"inf", @"info", @"ini", @"inv", @"iso", @"j2", @"jar", @"java", @"jpe", @"jpeg", @"jpg", @"js", @"json", @"jsp", @"jsx", @"key", @"kf8", @"kmk", @"ksh", @"kt", @"kts", @"kup", @"less", @"lex", @"licx", @"lisp", @"lit", @"lnk", @"lock", @"log", @"lua", @"m", @"m2v", @"m3u", @"m3u8", @"m4", @"m4a", @"m4r", @"m4v", @"map", @"master", @"mc", @"md", @"mdb", @"mdf", @"me", @"mi", @"mid", @"midi", @"mk", @"mkv", @"mm", @"mng", @"mo", @"mobi", @"mod", @"mov", @"mp2", @"mp3", @"mp4", @"mpa", @"mpd", @"mpe", @"mpeg", @"mpg", @"mpga", @"mpp", @"mpt", @"msg", @"msi", @"msu", @"nef", @"nes", @"nfo", @"nix", @"npmignore", @"ocx", @"odb", @"ods", @"odt", @"ogg", @"ogv", @"ost", @"otf", @"ott", @"ova", @"ovf", @"p12", @"p7b", @"pages", @"part", @"pcd", @"pdb", @"pdf", @"pem", @"pfx", @"pgp", @"ph", @"phar", @"php", @"pid", @"pkg", @"pl", @"plist", @"pm", @"png", @"po", @"pom", @"pot", @"potx", @"pps", @"ppsx", @"ppt", @"pptm", @"pptx", @"prop", @"ps", @"ps1", @"psd", @"psp", @"pst", @"pub", @"py", @"pyc", @"qt", @"ra", @"ram", @"rar", @"raw", @"rb", @"rdf", @"rdl", @"reg", @"resx", @"retry", @"rm", @"rom", @"rpm", @"rpt", @"rsa", @"rss", @"rst", @"rtf", @"ru", @"rub", @"sass", @"scss", @"sdf", @"sed", @"sh", @"sit", @"sitemap", @"skin", @"sldm", @"sldx", @"sln", @"sol", @"sphinx", @"sql", @"sqlite", @"step", @"stl", @"svg", @"swd", @"swf", @"swift", @"swp", @"sys", @"tar", @"tax", @"tcsh", @"tex", @"tfignore", @"tga", @"tgz", @"tif", @"tiff", @"tmp", @"tmx", @"torrent", @"tpl", @"ts", @"tsv", @"ttf", @"twig", @"txt", @"udf", @"vb", @"vbproj", @"vbs", @"vcd", @"vcf", @"vcs", @"vdi", @"vdx", @"vmdk", @"vob", @"vox", @"vscodeignore", @"vsd", @"vss", @"vst", @"vsx", @"vtx", @"war", @"wav", @"wbk", @"webinfo", @"webm", @"webp", @"wma", @"wmf", @"wmv", @"woff", @"woff2", @"wps", @"wsf", @"xaml", @"xcf", @"xfl", @"xlm", @"xls", @"xlsm", @"xlsx", @"xlt", @"xltm", @"xltx", @"xml", @"xpi", @"xps", @"xrb", @"xsd", @"xsl", @"xspf", @"xz", @"yaml", @"yml", @"z", @"zip", @"zsh", nil];
    });
    NSString *extension = [[fileName pathExtension] lowercaseString];
    NSString *name = [extensions containsObject:extension] ? extension : @"folder";
    return [NSString stringWithFormat:@"/bbs/assets/fileicons-svg/%@.svg", name];
}

+ (NSString *)encodeURIComponent:(NSString *)string {
    static NSCharacterSet *allowedCharacters = nil;
    static dispatch_once_t onceCharsToken;
    dispatch_once(&onceCharsToken, ^{
        allowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* "];
    });
    NSString *encoded = [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    return [encoded stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

/**
 * 强制以UTF-8解码，并将所有无效的字节序列替换为指定内容
 * @param corruptData 从服务器接收的可能已损坏的NSData
 * @param replacement 无效字节的替换，默认为空（跳过）
 * @return 清理和解码后的NSString
 */
+ (NSString *)forceDecodeUTF8StringFromData:(NSData *)corruptData replacement:(NSString *)replacement {
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

+ (void)callApiWithParams:(NSDictionary *)params toURL:(NSString*)url callback:(ApiCompletionBlock)block {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[XMLDictionaryParser sharedInstance] setTrimWhiteSpace:NO];
    });
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/api/client.php?ask=%@",CHEXIE, url];
#ifdef DEBUG
    NSLog(@"🌐 Calling API: %@", url);
//    postUrl = [NSString stringWithFormat:@"https://www.chexie.net/api/client_new.php?ask=%@", url];
#endif
    NSMutableDictionary *requestParams = [@{
        @"os": @"ios",
        @"device": [Helper getDevicePlatform],
        @"version": [Helper getOsVersionString],
        @"clientversion": APP_VERSION,
        @"clientbuild": APP_BUILD,
        @"token": TOKEN ?: @""
    } mutableCopy];
    
    NSMutableDictionary *requestFiles = [NSMutableDictionary dictionary];
    for (NSString *key in params) {
        id value = params[key];
        if ([value isKindOfClass:[NSData class]]) {
            requestFiles[key] = value;
        } else {
            requestParams[key] = value;
        }
    }
        
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:postUrl]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30;
    
    if (requestFiles.count == 0 ) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        // Convert parameters to x-www-form-urlencoded
        NSMutableArray *bodyParts = [NSMutableArray array];
        [requestParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *part = [NSString stringWithFormat:@"%@=%@",
                              [self encodeURIComponent:key],
                              [self encodeURIComponent:obj]];
            [bodyParts addObject:part];
        }];
        NSString *bodyString = [bodyParts componentsJoinedByString:@"&"];
        NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = bodyData;
    } else {
        NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        // 添加普通字段
        for (NSString *key in requestParams) {
            [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"%@", key, LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[LINE_BREAK dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[requestParams[key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[LINE_BREAK dataUsingEncoding:NSUTF8StringEncoding]];
        }
        // 添加文件字段
        for (NSString *key in requestFiles) {
            [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"%@", key, key, LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream%@", LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[LINE_BREAK dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:requestFiles[key]];
            [body appendData:[LINE_BREAK dataUsingEncoding:NSUTF8StringEncoding]];
        }
        // 结束边界
        [body appendData:[[NSString stringWithFormat:@"--%@--%@", boundary, LINE_BREAK] dataUsingEncoding:NSUTF8StringEncoding]];
        request.HTTPBody = body;
    }
    
    [Downloader loadRequest:request progress:nil completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"⚠️ API error: %@", error);
            dispatch_main_async_safe(^{
                block(nil, error);
            });
            return;
        }
        
        dispatch_global_default_async((^{
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
                [NOTIFICATION postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"加载失败", @"message": @"内容解析出现异常\n请使用网页版查看"}];
                NSError *xmlError = [NSError errorWithDomain:@"XMLParsing" code:0 userInfo:@{NSLocalizedDescriptionKey: @"XML parsing failed"}];
                dispatch_main_async_safe(^{
                    block(nil, xmlError);
                });
                return;
            }
            
            id info = xmlData[@"info"];
            NSArray *result;
            if (!info) {
                result = @[];
            } else if ([info isKindOfClass:[NSArray class]]) {
                result = info;
            } else {
                result = @[info];
            }
            
            NSString *errorMessage;
            if (result && result.count > 0 && result[0][@"code"]) {
                int code = [result[0][@"code"] intValue];
                if (code == -999) {
                    errorMessage = @"客户端版本过低，请前往App Store更新版本！";
                }
    #ifdef DEBUG
                // Should never happen in production
                if (code == 14) {
                    errorMessage = @"API ask错误";
                }
    #endif
            }
            dispatch_main_async_safe(^{
                if (errorMessage) {
                    [NOTIFICATION postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"加载失败", @"message": errorMessage}];
                    block(nil, [NSError errorWithDomain:@"APIError" code:0 userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                } else {
                    block(result, nil);
                }
            });
        }));
    }];
}

+ (void)fetchCurrentUserInfoWithCallback: (void (^)(NSDictionary *info, NSError *err))block {
    if (![Helper checkLogin:NO]) {
        block(nil, nil);
        return;
    }
    [Helper callApiWithParams:@{@"uid": UID} toURL:@"userinfo" callback:^(NSArray *result, NSError *err) {
        if (!err && result.count > 0) {
            NSDictionary *userInfo = result[0];
            [Helper updateUserInfo:userInfo];
            block(userInfo, nil);
        } else {
            block(nil, err);
        }
    }];
}

+ (void)fetchHotPostsWithCallback:(void (^)(NSArray *data, NSInteger globalTopCount, NSError *err))block {
    [Helper callApiWithParams:nil toURL:@"globaltop" callback:^(NSArray *topResult, NSError *topErr) {
        if (topErr) {
            block(nil, 0, topErr);
            return;
        }
        [Helper callApiWithParams:@{@"hotnum":[NSString stringWithFormat:@"%d", HOT_NUM]} toURL:@"hot" callback:^(NSArray *hotResult, NSError *hotErr) {
            if (hotErr || hotResult.count == 0) {
                if (hotErr) {
                    block(nil, 0, hotErr);
                } else {
                    block(nil, 0, nil);
                }
                return;
            }
            
            NSMutableArray *tmpData = [NSMutableArray arrayWithArray:topResult];
            [tmpData addObjectsFromArray:hotResult];
            [GROUP_DEFAULTS setObject:@(topResult.count) forKey:@"globalTopCount"];
            [GROUP_DEFAULTS setObject:tmpData forKey:@"hotPosts"];
            [GROUP_DEFAULTS setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"hotPostsUpdateTime"];
            block(tmpData, topResult.count, nil);
        }];
    }];
}

#pragma mark Common Functions

+ (BOOL)checkLogin:(BOOL)showAlert {
    if ([TOKEN length] == 0) { // 判断是否登录的方法为判断token是否为空
        if (showAlert) {
            [NOTIFICATION postNotificationName:@"showAlert" object:nil userInfo:@{@"title": @"错误", @"message": @"尚未登录"}];
        }
        return NO;
    } else {
        return YES;
    }
}

+ (int)checkRight {
    NSDictionary *infoDict = USERINFO;
    if ([self checkLogin:NO] && infoDict && ![infoDict isEqual:@""]) {
        return [infoDict[@"rights"] intValue];
    } else {
        return -1;
    }
}

+ (void)updateUserInfo:(NSDictionary *)userInfo {
    [GROUP_DEFAULTS setObject:userInfo forKey:@"userInfo"];
    [GROUP_DEFAULTS setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"userInfoUpdateTime"];
    
    NSMutableArray *data = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"ID"]];
    for (int i = 0; i < data.count; i++) {
        if (![data[i][@"id"] isEqualToString:userInfo[@"username"]]) {
            continue;
        }
        if (![data[i][@"icon"] isEqualToString:userInfo[@"icon"]]) {
            NSMutableDictionary *tempDict = [data[i] mutableCopy];
            tempDict[@"icon"] = userInfo[@"icon"];
            data[i] = tempDict;
            [DEFAULTS setObject:data forKey:@"ID"];
        }
        break;
    }
    
    [NOTIFICATION postNotificationName:@"infoRefreshed" object:nil];
}

+ (NSString *)restoreTitle:(NSString *)text {
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
    text = [self simpleEscapeHTML:text processLtGt:YES];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    return text;
}

+ (NSString *)getBoardTitle:(NSString *)bid {
    if ([bid hasPrefix:@"b"]) {
        bid = [bid substringFromIndex:@"b".length];
    }
    if ([bid isEqualToString:@"-1"]) {
        return @"全部版面";
    }
    return BOARD_TITLE_MAP[bid] ?: @"未知版面";
}

+ (NSString *)htmlStringWithText:(NSString *)text attachments:(NSArray *)attachements sig:(NSString *)sig textSize:(int)textSize {
    if ([[DEFAULTS objectForKey:@"disableScript"] boolValue]) {
        if (text.length > 0) {
            text = [text stringByReplacingOccurrencesOfString:@"(?i)(<script\\b[^>]*?>[\\s\\S]*?<\\/script>)" withString:@"<font color='gray'>[脚本被禁止执行]</font>" options:NSRegularExpressionSearch range:NSMakeRange(0, text.length)];
        }
        if (sig.length > 0) {
            sig = [sig stringByReplacingOccurrencesOfString:@"(?i)(<script\\b[^>]*?>[\\s\\S]*?<\\/script>)" withString:@"<font color='gray'>[脚本被禁止执行]</font>" options:NSRegularExpressionSearch range:NSMakeRange(0, sig.length)];
        }
    }
    
    NSString *body = @"";
    if (text) {
        body = [NSString stringWithFormat:@"<div class='textblock'>%@</div>", text];
    }
    if (attachements && attachements.count > 0) {
        NSMutableArray *attachEls = [NSMutableArray array];
        for (NSDictionary *attach in attachements) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:attach options:0 error:&error];
            if (!error) {
                NSString *fileName = attach[@"name"];
                NSString *imageUrl = [self getFileImage:fileName];
                NSString *price = [attach[@"price"] intValue] == 0 ? @"免费" : ([attach[@"free"] isEqualToString:@"YES"] ? @"您可以免费下载" : [NSString stringWithFormat:@"售价：%@", attach[@"price"]]);
                NSString *size = [self fileSizeStr:[attach[@"size"] intValue]];
                int count = [attach[@"count"] intValue];
                NSString *downloadCount = count > 0 ? [NSString stringWithFormat:@"下载次数：%d", count] : @"暂时无人下载";
                NSString *attachEl =
                [NSString stringWithFormat:
                 @"<a class='attachdark' href='capubbs-attach://%@'>"
                 "<img class='fileicon' src='%@' alt='文件图标'>"
                 "<div class='fileinfo'><div class='filename'>%@</div><div class='sub'>%@ • %@ • %@</div></div>"
                 "</a>", [jsonData base64EncodedStringWithOptions:0], imageUrl, fileName, price, size, downloadCount];
                [attachEls addObject:attachEl];
            } else {
                NSLog(@"Failed to encode attachment: %@", attach);
            }
        }
        if (attachEls.count > 0) {
            body = [NSString stringWithFormat:@"%@<div class='attachblock'><span id='attachtipdark'>本帖包含以下%ld个附件：</span><div class='attachsdark'>%@</div></div>", body, attachEls.count, [attachEls componentsJoinedByString:@""]];
        }
    }
    if (sig.length > 0) {
        body = [NSString stringWithFormat:@"%@<div class='sigblock'>%@"
                "<div class='sig'>%@</div></div>", body, text ? @"<span class='sigtip'>--------</span>" : @"", sig];
    }
    
    NSString *jQueryScript = @"";
    if ([body containsString:@"<script"] && [body containsString:@"/script>"]) {
        NSError *error = nil;
        NSString *jQueryContent = [NSString stringWithContentsOfFile:JQUERY_MIN_JS encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            jQueryScript = [NSString stringWithFormat:@"<script>%@</script>", jQueryContent];
        } else {
            NSLog(@"Failed to load jquery script: %@", error);
        }
    }
    
    NSString *hideImageHeaders = [[DEFAULTS objectForKey:@"picOnlyInWifi"] boolValue] && IS_CELLULAR ?
    @"<style type='text/css'>"
    "img{display:none;}img.image-hidden{display:block !important;background-color:#f0f0f0 !important;border:1px solid #ccc !important;}"
    "</style>"
    "<script>window._hideAllImages=true</script>"
    : @"";
    NSString *sigBlockStyle = text ? @".sigblock{color:gray;font-size:0.85em;margin-top:1em;}" : @"";
    NSString *bodyBackground = text ? @"rgba(255,255,255,0.75)" : @"transparent";
    
    return [NSString stringWithFormat:@"<html>"
            "<head>"
            "<meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>"
            "%@"
            "%@"
            "<style type='text/css'>"
            "img{max-width:min(100%%,700px);}"
            "body{font-size:16px;word-wrap:break-word;zoom:%d%%;}"
            "#body-wrapper{padding:0 0.25em;}"
            "#body-mask{position:absolute;top:0;bottom:0;left:0;right:0;z-index:-1;background-color:%@;transition:background-color 0.1s linear;}"
            ".quoteblock{background-color:rgba(235,235,235,0.5);color:gray;font-size:0.85em;padding:0.6em 2em 0;margin:0.6em 0;border-radius:0.5em;border:1px solid #ddd;position:relative;}"
            ".quoteblock::before,.quoteblock::after{position:absolute;font-size:4em;color:#d8e7f1;font-family:sans-serif;pointer-events:none;line-height:1;}"
            ".quoteblock::before{content:'“';top:0.05em;left:0.1em;}"
            ".quoteblock::after{content:'”';bottom:-0.5em;right:0.15em;}"
            ".textblock,.sig{overflow-x:scroll;}"
            ".textblock{min-height:3em;}"
            ".attachblock{font-size:0.85em; padding:1em 0 0.5em;}"
            "#attachtipdark{color:gray;}"
            ".attachsdark{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px, 1fr));margin-top:0.5em;gap:0.65em;padding:0.65em;border-radius:0.75em;border:1px dashed #ddd;}"
            ".attachdark{display:flex;flex-direction:row;align-items:center;overflow:hidden;text-decoration:none;font-family:'SF Mono','Menlo','Consolas',monospace;padding:0.5em;background-color:rgba(235,235,235,0.5);border-radius:0.5em;}"
            ".attachdark .fileicon{width:2.5em;max-height:2.5em;object-fit:contain;margin-right:0.5em;pointer-events:none;}"
            ".attachdark .fileinfo .filename{color:black;margin-bottom:0.1em;text-overflow:ellipsis;}"
            ".attachdark .fileinfo .sub{color:gray;font-size:0.85em;}"
            "%@"
            ".sig{max-height:400px;overflow-y:scroll;}"
            "</style>"
            "</head>"
            "<body><div id='body-mask'></div><div id='body-wrapper'>%@</div></body>"
            "</html>", jQueryScript, hideImageHeaders, textSize, bodyBackground, sigBlockStyle, body];
}

+ (NSDictionary *)getLink:(NSString *)path {
    NSString *bid = @"", *tid = @"", *p = @"", *floor = @"";
    NSURLComponents *components = [NSURLComponents componentsWithString:path];
    if (!components) {
        return @{@"bid" : bid, @"tid" : tid, @"p" : p, @"floor" : floor};
    }
    
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems) {
        if (item.value) { // 只添加有值的参数
            params[item.name] = item.value;
        }
    }
    
    NSString *urlPath = components.path;
    if ([urlPath containsString:@"/bbs/content"] || [urlPath containsString:@"/bbs/main"]) {
        bid = params[@"bid"] ?: @"";
        tid = params[@"tid"] ?: @"";
        p = params[@"p"];
        if (tid.length > 0) {
            floor = components.fragment ?: @"";
        }
    } else if ([urlPath containsString:@"/cgi-bin/bbs.pl"]) {
        bid = params[@"b"] ?: @"";
        tid = params[@"see"] ?: @"";
        NSString *oldbid = params[@"id"];
        if (oldbid) {
            // 这个转换表可以作为静态字典或属性，避免重复创建
            NSDictionary *trans = @{@"act": @"1", @"capu": @"2", @"bike": @"3", @"water": @"4", @"acad": @"5", @"asso": @"6", @"skill": @"7", @"race": @"9", @"web": @"28"};
            bid = trans[oldbid] ?: bid;
        }
        if (tid.length > 0) {
            long count = 0; // 转换26进制tid
            NSString *lowerTid = [tid lowercaseString];
            for (int i = 0; i < lowerTid.length; i++) {
                int charValue = [lowerTid characterAtIndex:lowerTid.length - 1 - i] - 'a';
                if (charValue >= 0 && charValue < 26) {
                    count += charValue * pow(26, i);
                }
            }
            count++;
            tid = [NSString stringWithFormat:@"%ld", count];
        }
    }
    if (p.length == 0) {
        p = @"1";
    }
    return @{@"bid" : bid, @"tid" : tid, @"p" : p, @"floor" : floor};
}

/// 从论坛转义过的 HTML 恢复成正确的格式，例如 \<font>xxx\</font> 恢复成 [font=][/font]
+ (NSString *)restoreFormat:(NSString *)text {
    if (!text || text.length == 0) {
        return text;
    }
    NSRegularExpressionOptions options = NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators;
    // NSLog(@"%@", text);
    NSArray *oriExp = @[@"(<quote>)(.*?)(<a href=['\"]/bbs/user)(.*?)(>@)(.*?)(</a> ：<br><br>)((.|[\r\n])*?)(<br><br></font></div></quote>)",
                        @"(<a href=['\"]/bbs/user)(.*?)(>@)(.*?)(</a>)",
                        @"(<a href=['\"]#['\"]>)((.|[\r\n])*?)(</a>)", // 修复网页版@格式的错误
                        @"(<a href=['\"])(.+?)(['\"][^>]*>)(.+?)(</a>)",
                        @"<img[^>]*?\\bsrc=['\"]([^'\"]+)['\"][^>]*?>",
                        @"<b[^>]*>(.+?)</b>",
                        @"<i[^>]*>(.+?)</i>"];
    NSArray *repExp = @[@"[quote=$6]$8[/quote]",
                        @"[at]$4[/at]",
                        @"$2",
                        @"[url=$2]$4[/url]",
                        @"[img]$1[/img]",
                        @"[b]$1[/b]",
                        @"[i]$1[/i]"];
    NSRegularExpression *regExp;
    for (int i = 0; i < oriExp.count; i++) {
        regExp = [NSRegularExpression regularExpressionWithPattern:oriExp[i] options:options error:nil];
        text = [regExp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:repExp[i]];
    }
    
    while (YES) {
        NSString *textHTML = nil;
        NSString *textBody = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"<font([^>]*)>([^<]*?)</font>" options:options error:nil];
        NSTextCheckingResult *match = [regexp firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
        if (match) {
            NSRange attributesRange = [match rangeAtIndex:1];
            if (attributesRange.location != NSNotFound) {
                textHTML = [text substringWithRange:attributesRange];
            }
            NSRange bodyRange = [match rangeAtIndex:2];
            if (bodyRange.location != NSNotFound) {
                textBody = [text substringWithRange:bodyRange];
            }
        }
        if (!textHTML || !textBody) {
            break;
        }
        
        NSString *finalTextBody = textBody;
        regexp = [NSRegularExpression regularExpressionWithPattern:@"(color|size|face)=['\"]([^'\"]+)['\"]" options:options error:nil];
        
        NSArray<NSTextCheckingResult *> *matches = [regexp matchesInString:textHTML options:0 range:NSMakeRange(0, textHTML.length)];
        for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
            NSString *key = [textHTML substringWithRange:[match rangeAtIndex:1]];
            NSString *value = [textHTML substringWithRange:[match rangeAtIndex:2]];
            if ([key caseInsensitiveCompare:@"color"] == NSOrderedSame) {
                finalTextBody = [NSString stringWithFormat:@"[color=%@]%@[/color]", value, finalTextBody];
            }
            else if ([key caseInsensitiveCompare:@"size"] == NSOrderedSame) {
                finalTextBody = [NSString stringWithFormat:@"[size=%@]%@[/size]", value, finalTextBody];
            }
            else if ([key caseInsensitiveCompare:@"face"] == NSOrderedSame) {
                finalTextBody = [NSString stringWithFormat:@"[font=%@]%@[/font]", value, finalTextBody];
            }
        }
        text = [text stringByReplacingCharactersInRange:match.range withString:finalTextBody];
    }
    
    return text;
}

+ (NSString *)simpleEscapeHTML:(NSString *)text processLtGt:(BOOL)ltGt {
    if (!text || text.length == 0) {
        return text;
    }
    int index = 0;
    while (index < text.length) {
        if ([[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@"<"]) {
            index++;
            while (index < text.length) {
                if ([[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@">"]) {
                    break;
                }
                // 防止出现嵌套的情况比如 <span style=...<br>...>
                if (index + 3 < text.length && [[text substringWithRange:NSMakeRange(index, 4)] isEqualToString:@"<br>"]) {
                    text = [text stringByReplacingCharactersInRange:NSMakeRange(index, 4) withString:@""];
                }
                if (index + 5 < text.length && [[text substringWithRange:NSMakeRange(index, 6)] isEqualToString:@"<br />"]) {
                    text = [text stringByReplacingCharactersInRange:NSMakeRange(index, 6) withString:@""];
                }
                index++;
            }
        }
        index++;
    }
    
    NSString *expression = @"<br[^>]*>"; // 恢复换行
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"\n"];
    
    NSDictionary *entityMap = @{
        @"&nbsp;": @" ",   @"&amp;": @"&",    @"&apos;": @"'",
        @"&quot;": @"\"",  @"&ldquo;": @"“",  @"&rdquo;": @"”",
        @"&#39;": @"'",    @"&mdash;": @"——", @"&hellip;": @"…"
    };
    for (NSString *key in entityMap) {
        text = [text stringByReplacingOccurrencesOfString:key withString:entityMap[key]];
    }
    if (ltGt) {
        NSDictionary *entityMap = @{@"&lt;": @"<", @"&gt;": @">"};
        for (NSString *key in entityMap) {
            text = [text stringByReplacingOccurrencesOfString:key withString:entityMap[key]];
        }
    }
    return text;
}

+ (NSString *)toCompatibleFormat:(NSString *)text {
    if (!text || text.length == 0) return @"";

    static NSRegularExpression *tagRegex;
    static NSRegularExpression *tagNameRegex;
    static NSRegularExpression *selfClosingTagRegex;
    static NSSet<NSString *> *voidTags;
    static NSSet<NSString *> *rawTextTags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // (?s) 开启 dot-all 模式。先匹配 <!--...-->，再匹配普通标签
        tagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?s)<!--.*?-->|</?[a-zA-Z!?](?:\"[^\"]*\"|'[^']*'|[^>\"']+)*>" options:0 error:nil];
        tagNameRegex = [NSRegularExpression regularExpressionWithPattern:@"^</?([a-zA-Z][a-zA-Z0-9:-]*)" options:0 error:nil];
        selfClosingTagRegex = [NSRegularExpression regularExpressionWithPattern:@"/\\s*>$" options:0 error:nil];
        // 永远不会有闭合标签的 HTML 空元素
        voidTags = [NSSet setWithObjects:@"img", @"br", @"hr", @"input", @"meta", @"link", @"area", @"base", @"col", @"param", @"source", @"track", @"wbr", @"embed", nil];
        // 需要进入 Raw Text 模式的标签
        rawTextTags = [NSSet setWithObjects:@"script", @"style", @"pre", nil];
    });

    NSMutableString *result = [NSMutableString stringWithCapacity:text.length];
    NSMutableArray<NSString *> *tagStack = [NSMutableArray array];
    
    // 维护特殊状态
    NSString *rawTextTag = nil;
    NSUInteger searchLocation = 0;

    while (searchLocation < text.length) {
        
        // 状态 1：如果进入了 script 或 style
        if (rawTextTag) {
            // 直接找对应的闭合标签，例如 </script> 或 </style>
            NSString *closePattern = [NSString stringWithFormat:@"</%@\\s*>", rawTextTag];
            NSRange searchRange = NSMakeRange(searchLocation, text.length - searchLocation);
            
            NSRange closeRange = [text rangeOfString:closePattern
                                             options:NSRegularExpressionSearch | NSCaseInsensitiveSearch
                                               range:searchRange];
            
            if (closeRange.location != NSNotFound) {
                // 找到了完整的闭合标签
                NSUInteger endLocation = NSMaxRange(closeRange);
                NSRange rawRange = NSMakeRange(searchLocation, endLocation - searchLocation);
                
                // 这中间的所有内容（包括假 tag、空格、换行）完全原样保留
                [result appendString:[text substringWithRange:rawRange]];
                
                // 出栈并恢复状态
                if (tagStack.count > 0 && [[tagStack lastObject] isEqualToString:rawTextTag]) {
                    [tagStack removeLastObject];
                }
                rawTextTag = nil;
                searchLocation = endLocation;
            } else {
                // 如果找不到闭合标签（HTML 不规范），就把剩下的全当 raw text 处理
                [result appendString:[text substringFromIndex:searchLocation]];
                break;
            }
            continue;
        }
        
        // 状态 2：正常找下一个 tag
        NSRange searchRange = NSMakeRange(searchLocation, text.length - searchLocation);
        NSTextCheckingResult *match = [tagRegex firstMatchInString:text options:0 range:searchRange];
        
        if (!match) {
            // 没找到 tag，跳出循环处理末尾
            break;
        }
        
        NSRange tagRange = match.range;
        
        // 1. 处理 gap (两个 tag 之间的文本)
        if (tagRange.location > searchLocation) {
            NSString *gapText = [text substringWithRange:NSMakeRange(searchLocation, tagRange.location - searchLocation)];
            if (tagStack.count > 0) {
                [result appendString:gapText];
            } else {
                [result appendString:[self processPlainText:gapText]];
            }
        }
        
        // 2. 拼接标签本身
        NSString *tagString = [text substringWithRange:tagRange];
        [result appendString:tagString];
        
        // 3. 提取标签名并更新 stack 和 rawTextTag 状态
        NSTextCheckingResult *nameMatch = [tagNameRegex firstMatchInString:tagString options:0 range:NSMakeRange(0, tagString.length)];
        if (nameMatch && nameMatch.numberOfRanges > 1) {
            NSString *tagName = [[tagString substringWithRange:[nameMatch rangeAtIndex:1]] lowercaseString];
            
            BOOL isClosing = [tagString hasPrefix:@"</"];
            if (isClosing) {
                // 容错退栈
                NSInteger matchedIndex = [tagStack indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
                    return [obj isEqualToString:tagName];
                }];
                if (matchedIndex != NSNotFound) {
                    NSRange popRange = NSMakeRange(matchedIndex, tagStack.count - matchedIndex);
                    [tagStack removeObjectsInRange:popRange];
                }
            } else {
                BOOL isSelfClosing = [selfClosingTagRegex firstMatchInString:tagString options:0 range:NSMakeRange(0, tagString.length)] != nil;
                
                if (![voidTags containsObject:tagName] && !isSelfClosing) {
                    [tagStack addObject:tagName];
                    
                    if ([rawTextTags containsObject:tagName]) {
                        rawTextTag = tagName;
                    }
                }
            }
        }
        
        searchLocation = NSMaxRange(tagRange);
    }

    // 4. 处理最后的尾部纯文本
    if (searchLocation < text.length) {
        NSString *remainder = [text substringFromIndex:searchLocation];
        if (tagStack.count > 0) {
            [result appendString:remainder];
        } else {
            [result appendString:[self processPlainText:remainder]];
        }
    }

    return result;
}

+ (NSString *)processPlainText:(NSString *)text {
    if (!text || text.length == 0) return @"";
    NSMutableString *mut = [text mutableCopy];
    
    static NSRegularExpression *newlineRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        newlineRegex = [NSRegularExpression regularExpressionWithPattern:@"\r\n|\n\r|\r|\n" options:0 error:nil];
    });
    [newlineRegex replaceMatchesInString:mut options:0 range:NSMakeRange(0, mut.length) withTemplate:@"<br>"];
    // 连续两个以上空格才转换
    [mut replaceOccurrencesOfString:@"  " withString:@"&nbsp; " options:0 range:NSMakeRange(0, mut.length)];
    
    return mut;
}

+ (NSString *)transToHTML:(NSString *)text {
    if (!text || text.length == 0) {
        return @"";
    }
    // Restore spaces & new lines
    text = [self toCompatibleFormat:text];

    NSArray *oriExp = @[@"(\\[img])(.+?)(\\[/img])",
                        @"(\\[quote=)(.+?)(])([\\s\\S]+?)(\\[/quote])",
                        @"(\\[size=)(.+?)(])([\\s\\S]+?)(\\[/size])",
                        @"(\\[font=)(.+?)(])([\\s\\S]+?)(\\[/font])",
                        @"(\\[color=)(.+?)(])([\\s\\S]+?)(\\[/color])",
                        @"(\\[color=)(.+?)(])([\\s\\S]+?)",
                        @"(\\[at])(.+?)(\\[/at])",
                        @"(\\[url])(.+?)(\\[/url])",
                        @"(\\[url=)(.+?)(])([\\s\\S]+?)(\\[/url])",
                        @"(\\[b])(.+?)(\\[/b])",
                        @"(\\[i])(.+?)(\\[/i])"];
    NSArray *newExp = @[@"<img src='$2'>",
                        @"<quote><div class='quoteblock'><font>引用自 [at]$2[/at] ：<br><br>$4<br><br></font></div></quote>",
                        @"<font size='$2'>$4</font>",
                        @"<font face='$2'>$4</font>",
                        @"<font color='$2'>$4</font>",
                        @"<font color='$2'>$4</font>",
                        @"<a href='/bbs/user?name=$2'>@$2</a>",
                        @"<a href='$2'>$2</a>",
                        @"<a href='$2'>$4</a>",
                        @"<b>$2</b>",
                        @"<i>$2</i>"];
    for (int i = 0; i < oriExp.count; i++) {
        NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:oriExp[i] options:0 error:nil];
        text = [regExp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:newExp[i]];
    }
    return text;
}

+ (NSString *)removeHTML:(NSString *)text restoreFormat:(BOOL)restoreFormat {
    if (!text || text.length == 0) {
        return text;
    }
    if (restoreFormat) {
        text = [self restoreFormat:text];
    }
    text = [self simpleEscapeHTML:text processLtGt:NO];
    
    NSRegularExpressionOptions options = NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators;

    // 去除注释
    NSString *expression = @"<!--.*?-->";
    NSRegularExpression * regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    // 去除 script / iframe / style 内容
    for (NSString *tag in @[@"script", @"iframe", @"style"]) {
        expression = [NSString stringWithFormat:@"<%@[^>]*>.*?</%@>", tag, tag];
        regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
        text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    }
    
    // 处理 div / p / tr 为换行
    for (NSString *tag in @[@"div", @"p", @"tr"]) {
        expression = [NSString stringWithFormat:@"<%@[^>]*>(.*?)</%@>", tag, tag];
        regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
        text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"$1\n"];
    }
    
    // 处理 td 为tab
    expression = @"<td[^>]*>(.*?)</td>";
    regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"$1\t"];

    // 处理 span 为不换行
    expression = @"<span[^>]*>(.*?)</span>";
    regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"$1"];
    
    if (restoreFormat) {
        // 再尝试恢复一次格式，之前可能有漏掉的
        text = [self restoreFormat:text];
    }
    
    // 去除所有HTML标签
    expression = @"<[^>]+>";
    regexp = [NSRegularExpression regularExpressionWithPattern:expression options:options error:nil];
    text = [regexp stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    // NSLog(@"%@", text);
    return text;
}

// 单个文件的大小
+ (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSDictionary<NSFileAttributeKey, id> *attributes = [MANAGER attributesOfItemAtPath:filePath error:nil];
    if ([attributes[NSFileType] isEqualToString:NSFileTypeRegular]) {
        return [attributes fileSize];
    }
    return 0;
}

// 遍历文件获得文件夹大小
+ (unsigned long long)folderSizeAtPath:(NSString *)folderPath {
    if (![MANAGER fileExistsAtPath:folderPath]) {
        return 0;
    }
    
    NSDirectoryEnumerator *enumerator = [MANAGER enumeratorAtPath:folderPath];
    NSString *fileName;
    unsigned long long folderSize = 0;
        
    while ((fileName = [enumerator nextObject])) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:filePath];
    }
    
    return folderSize;
}

+ (void)cleanUpFilesInDirectory:(NSString *)directoryPath minInterval:(NSTimeInterval)interval {
    NSDirectoryEnumerator *enumerator = [MANAGER enumeratorAtPath:directoryPath];
    NSString *fileName;
        
    while ((fileName = [enumerator nextObject])) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        NSDictionary<NSFileAttributeKey, id> *attributes = [MANAGER attributesOfItemAtPath:filePath error:nil];
        if (!attributes) {
            continue;
        }
        // Skip folders. Don't delete folder entirely, otherwise will throw many db error (webkit related)
        if ([attributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
            continue;
        }
        NSDate *modificationDate = attributes[NSFileModificationDate];
        if (-[modificationDate timeIntervalSinceNow] > interval) {
            [MANAGER removeItemAtPath:filePath error:nil];
        }
    }
}

+ (NSString *)fileSizeStr:(NSInteger)size {
    if (size >= 1024 * 1024) {
        float num = size * 1.0 / (1024 * 1024);
        return [NSString stringWithFormat:num >= 10 ? @"%.1fMB" : @"%.2fMB", num];
    } else if (size >= 1024 / 10) {
        float num = size * 1.0 / 1024;
        return [NSString stringWithFormat:num >= 10 ? @"%.1fKB" : @"%.2fKB", num];
    } else {
        return [NSString stringWithFormat:@"%ldB", size];
    }
}

+ (NSString *)fileNameFromURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    
    // 使用 components 提取纯净的 path，避免 query 和 fragment 干扰
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *path = components.path;
    if (!path.length) {
        return nil;
    }
    
    NSString *fileName = [path.lastPathComponent stringByRemovingPercentEncoding];
    if (!fileName.length || !fileName.pathExtension.length) {
        return nil;
    }

    return fileName;
}

+ (BOOL)isHttpScheme:(NSString *)scheme {
    return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
}

+ (NSString *)md5:(NSString *)str { // 字符串MD5值算法
    if (!str) {
        return @"";
    }
    const char* cStr=[str UTF8String];
    CC_LONG dataLength = (CC_LONG)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; // CC_MD5_DIGEST_LENGTH = 16
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Suppress CC_MD5 deprecated warning
    CC_MD5(cStr, dataLength, digist);
#pragma clang diagnostic pop
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int  i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [outPutStr appendFormat:@"%02X", digist[i]];// 小写 x 表示输出的是小写 MD5 ，大写 X 表示输出的是大写 MD5
    }
    return [outPutStr copy];
}

+ (BOOL)isPureInt:(NSString *)str {
    if (!str || str.length == 0) {
            return NO;
        }
    NSScanner *scan = [NSScanner scannerWithString:str];
    scan.charactersToBeSkipped = nil;
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

+ (NSString *)getSigForData:(id)data {
    NSError *error = nil;
    NSData *dataJson = [NSJSONSerialization dataWithJSONObject:data
                                                       options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys
                                                         error:&error];
    if (!error) {
        NSString *dataString = [[NSString alloc] initWithData:dataJson encoding:NSUTF8StringEncoding];
        if (dataString) {
            return [self md5:[dataString stringByAppendingString:SALT]];
        }
    }
    return nil;
}

+ (NSString *)getDevicePlatform { // 获取设备信息
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // return platform;
    NSDictionary *dict = @{
        // Simulator
        @"x86_64": @"iOS Simulator",
        @"arm64": @"iOS Simulator",
    };
    
    if (dict[platform]) {
        platform = dict[platform];
    }
    
    // NSLog(@"Platform = %@",platform);
    return platform;
}

+ (NSString *)getOsVersionString {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *versionString;

    if (version.patchVersion > 0) {
        // 如果有第三位版本号 (例如 18.6.5)
        versionString = [NSString stringWithFormat:@"%ld.%ld.%ld",
                         (long)version.majorVersion,
                         (long)version.minorVersion,
                         (long)version.patchVersion];
    } else {
        // 如果只有前两位版本号 (例如 15.0)
        versionString = [NSString stringWithFormat:@"%ld.%ld",
                         (long)version.majorVersion,
                         (long)version.minorVersion];
    }
    // NSLog(@"VersionString = %@",versionString);
    return versionString;
}

@end
