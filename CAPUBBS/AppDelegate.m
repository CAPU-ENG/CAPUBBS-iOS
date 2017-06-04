//
//  AppDelegate.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AppDelegate.h"
#import "AsyncImageView.h"
#import "LoginViewController.h"
#import "ContentViewController.h"
#import "ListViewController.h"
#import "CollectionViewController.h"
#import "MessageViewController.h"
#import "ComposeViewController.h"
#import <CoreSpotlight/CoreSpotlight.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[UINavigationBar appearance] setBarTintColor:GREEN_DARK];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UITextField appearance] setClearButtonMode:UITextFieldViewModeWhileEditing];
    [[UITextField appearance] setBackgroundColor:[UIColor lightTextColor]];
    [[UITextView appearance] setBackgroundColor:[UIColor lightTextColor]];
    [[UISegmentedControl appearance] setTintColor:BLUE];
    [[UIStepper appearance] setTintColor:BLUE];
    [[UISwitch appearance] setOnTintColor:BLUE];
    [[UISwitch appearance] setTintColor:[UIColor whiteColor]];
    [[UIToolbar appearance] setTintColor:BLUE];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
//                          @(2), @"proxy",
//                          @"school", @"proxyPosition",
                          @(YES), @"autoLogin",
                          @(YES), @"enterLogin",
                          @(NO), @"wakeLogin",
                          @(YES), @"vibrate",
                          @(NO), @"picOnlyInWifi",
                          @(YES), @"autoSave",
                          @(YES), @"oppositeSwipe",
                          @(1), @"toolbarEditor",
                          @(1), @"viewCollectionType",
                          @(100), @"textSize",
                          @(MAX_ID_NUM / 2), @"IDNum",
                          @(MAX_HOT_NUM / 2), @"hotNum",
                          @"2016-01-01", @"checkUpdate",
                          @"2016-01-01", @"checkPass",
                          nil];
    NSDictionary *group = [NSDictionary dictionaryWithObjectsAndKeys:
                           DEFAULT_SERVER_URL, @"URL",
                           @"", @"token",
                           @"", @"userInfo",
                           @(NO), @"iconOnlyInWifi",
                           @(NO), @"simpleView",
                           nil];
    [DEFAULTS registerDefaults:dict];
    [DEFAULTS removeObjectForKey:@"enterLogin"];
    [DEFAULTS removeObjectForKey:@"wakeLogin"];
    [GROUP_DEFAULTS registerDefaults:group];
    [self transferDefaults];

    [[NSURLCache sharedURLCache] setMemoryCapacity:16.0 * 1024 * 1024];
    [[NSURLCache sharedURLCache] setDiskCapacity:64.0 * 1024 * 1024];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlert:) name:@"showAlert" object:nil];
    [self performSelectorInBackground:@selector(transport) withObject:nil];
    performer = [[ActionPerformer alloc] init];
    if (IOS >= 9.0) {
        [NOTIFICATION addObserver:self selector:@selector(collectionChanged) name:@"collectionChanged" object:nil];
    }
    if ([ActionPerformer checkLogin:NO] && [[DEFAULTS objectForKey:@"autoLogin"] boolValue] == YES) {
        [self _loginAsync:YES];
    }
    return YES;
}

- (void)transferDefaults {
    NSUserDefaults *appGroup = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_IDENTIFIER];
    if ([[appGroup objectForKey:@"activated"] boolValue] == NO) {
        NSUserDefaults *standard = [NSUserDefaults standardUserDefaults];
        for (NSString *key in @[@"URL", @"uid", @"pass", @"token", @"userInfo", @"iconOnlyInWifi", @"simpleView"]) {
            id obj = [standard objectForKey:key];
            if (obj) {
                [appGroup setObject:obj forKey:key];
                [standard removeObjectForKey:key];
            }
        }
        [appGroup setObject:@(YES) forKey:@"activated"];
        [appGroup synchronize];
    }
}

- (void)showAlert:(NSNotification *)noti {
    NSDictionary *dict = noti.userInfo;
    [[[UIAlertView alloc] initWithTitle:dict[@"title"] message:dict[@"message"] delegate:nil cancelButtonTitle:(dict[@"cancelTitle"] ? : @"好") otherButtonTitles:nil, nil] show];
}

- (BOOL)application:(nonnull UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * __nullable))restorationHandler {
    NSString *identifier = userActivity.userInfo[@"kCSSearchableItemActivityIdentifier"];
    NSArray *info = [identifier componentsSeparatedByString:@"\n"];
    NSDictionary *dict;
    if (userActivity.webpageURL.absoluteString.length > 0) {
        dict = [ContentViewController getLink:userActivity.webpageURL.absoluteString];
    }
    
    BOOL continueFronCollectionSearch = ([info[0] isEqualToString:@"collection"]);
    BOOL continueFromHandoff = (dict.count > 0 && ![dict[@"tid"] isEqualToString:@""]);
    if (continueFronCollectionSearch || continueFromHandoff) {
        dispatch_global_default_async(^{
            NSMutableDictionary *naviDict = [NSMutableDictionary dictionaryWithDictionary:@{@"open": @"post"}];
            if (continueFronCollectionSearch) {
                naviDict[@"bid"] = info[1];
                naviDict[@"tid"] = info[2];
                naviDict[@"naviTitle"] = info[3];
            } else if (continueFromHandoff) {
                naviDict[@"bid"] = dict[@"bid"];
                naviDict[@"tid"] = dict[@"tid"];
                naviDict[@"page"] = dict[@"p"];
                naviDict[@"floor"] = dict[@"floor"];
                naviDict[@"naviTitle"] = userActivity.title;
            }
            [self _handleUrlRequestWithDictionary:naviDict];
        });
    }
    
    dict = userActivity.userInfo;
    if ([dict[@"type"] isEqualToString:@"compose"]) {
        dispatch_global_default_async(^{
            if (userActivity.webpageURL.absoluteString.length == 0 && [dict[@"bid"] length] > 0) {
                NSMutableDictionary *listDict = [NSMutableDictionary dictionaryWithDictionary:@{@"open": @"list"}];
                listDict[@"bid"] = dict[@"bid"];
                [self _handleUrlRequestWithDictionary:listDict];
            }
            
            NSMutableDictionary *naviDict = [NSMutableDictionary dictionaryWithDictionary:@{@"open": @"compose"}];
            [naviDict addEntriesFromDictionary:dict];
            naviDict[@"naviTitle"] = userActivity.title;
            [self _handleUrlRequestWithDictionary:naviDict];
        });
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    dispatch_global_default_async(^{
        if ([shortcutItem.type isEqualToString:@"Hot"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"hot"}];
        }else if ([shortcutItem.type isEqualToString:@"Collection"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"collection"}];
        }else if ([shortcutItem.type isEqualToString:@"Message"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"message"}];
        }else if ([shortcutItem.type isEqualToString:@"Compose"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"compose"}];
        }
    });
    completionHandler(YES);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [urlString substringFromIndex:[@"capubbs://" length]];
    NSArray *paramsArray = [urlString componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *param in paramsArray) {
        if (param.length == 0) {
            NSLog(@"Handle Url error - wrong parameter");
            return NO;
        }
        NSArray *tempArray = [param componentsSeparatedByString:@"="];
        if (tempArray.count != 2) {
            NSLog(@"Handle Url error - wrong parameter");
            return NO;
        }
        [params addEntriesFromDictionary:@{tempArray[0]: tempArray[1]}];
    }
    if (params.allKeys.count > 0) {
        dispatch_global_default_async(^{
            [self _handleUrlRequestWithDictionary:params];
        });
    }
    return YES;
}

- (void)_handleUrlRequestWithDictionary:(NSDictionary *)dict {
    NSString *open = dict[@"open"];
    if (open) {
        UIViewController *view = self.window.rootViewController;
        while ([view presentedViewController] != nil) {
            view = [view presentedViewController];
        }
        UINavigationController *navi;
        if ([open isEqualToString:@"message"]) {
            // 同步登陆
            [self _loginAsync:NO];
            [DEFAULTS setObject:[NSNumber numberWithBool:NO] forKey:@"wakeLogin"];
            
            MessageViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"message"];
            
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
            [navi setToolbarHidden:NO];
        } else if ([open isEqualToString:@"hot"]) {
            ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
            dest.bid = @"hot";
            
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
            [navi setToolbarHidden:NO];
        } else if ([open isEqualToString:@"collection"]) {
            CollectionViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"collection"];
            
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
        } else if ([open isEqualToString:@"compose"]) {
            ComposeViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"compose"];
            
            if (dict[@"bid"] && dict[@"pid"]) {
                dest.bid = dict[@"bid"];
                dest.tid = dict[@"tid"];
                dest.floor = dict[@"floor"];
                dest.defaultTitle = dict[@"title"];
                dest.defaultContent = dict[@"content"];
                dest.title = dict[@"naviTitle"];
            }
            
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
            navi.modalPresentationStyle = UIModalPresentationFormSheet;
        } else if ([open isEqualToString:@"list"]) {
            ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
            dest.bid = dict[@"bid"];
            
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
            [navi setToolbarHidden:NO];
        } else if ([open isEqualToString:@"post"]) {
            // 同步登陆
            [self _loginAsync:NO];
            [DEFAULTS setObject:[NSNumber numberWithBool:NO] forKey:@"wakeLogin"];
            
            ContentViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"content"];
            
            dest.bid = dict[@"bid"];
            dest.tid = dict[@"tid"];
            if (dict[@"page"]) {
                dest.floor = [NSString stringWithFormat:@"%d", [dict[@"page"] intValue] * 12];
            }
            if (dict[@"floor"]) {
                dest.exactFloor = dict[@"floor"];
            }
            if (dict[@"naviTitle"]) {
                dest.title = dict[@"naviTitle"];
            } else {
                dest.title = @"加载中";
            }
            
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
        }
        [view presentViewController:navi animated:YES completion:nil];
        NSLog(@"Open with %@", open);
    }
}

- (void)back {
    UIViewController *view = self.window.rootViewController;
    while ([view presentedViewController] != nil) {
        view = [view presentedViewController];
    }
    [view dismissViewControllerAnimated:YES completion:nil];
}

- (void)collectionChanged { // 后台更新系统搜索内容
    dispatch_global_default_async(^{
        [self updateCollection];
    });
}

- (void)updateCollection {
    NSMutableArray *seachableItems = [[NSMutableArray alloc] init];
    NSArray *array = [DEFAULTS objectForKey:@"collection"];
    for (NSDictionary *dict in array) {
        NSString *bid = dict[@"bid"];
        NSString *tid = dict[@"tid"];
        NSString *title = dict[@"title"];
        NSString *author = dict[@"author"];
        NSString *text = dict[@"text"];
        CSSearchableItemAttributeSet *attr = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:@"views"];
        attr.title = title;
        // 切割text长度 防止太长导致内容丢失
        if (text.length > 6000) {
            text = [text substringToIndex:6000];
        }
        if (author.length > 0 && text.length > 0) {
            attr.contentDescription = [NSString stringWithFormat:@"%@ - %@", author, text];
        }
        attr.thumbnailData = UIImagePNGRepresentation([UIImage imageNamed:[NSString stringWithFormat:@"b%@", bid]]);
        attr.keywords = @[@"CAPUBBS", @"收藏"];
        CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[NSString stringWithFormat:@"collection\n%@\n%@\n%@", bid, tid, title] domainIdentifier:BUNDLE_IDENTIFIER attributeSet:attr];
        [seachableItems addObject:item];
    }
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[BUNDLE_IDENTIFIER] completionHandler:^(NSError * __nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:seachableItems completionHandler:^(NSError * __nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }else {
                NSLog(@"Collection Saved");
            }
        }];
    }];
}

- (void)transport {
    if ([[DEFAULTS objectForKey:@"clearDirtyData3.2"] boolValue] == NO) { // 3.2之前版本采用NSUserDefaults储存头像 文件夹里面有许多垃圾数据
        NSString *rootFolder = NSHomeDirectory();
        NSArray *childPaths = [MANAGER subpathsAtPath:rootFolder];
        for (NSString *path in childPaths) {
            NSString *childPath = [NSString stringWithFormat:@"%@/%@", rootFolder, path];
            NSArray *testPaths = [MANAGER subpathsAtPath:childPath];
            if ([childPath containsString:@"CAPUBBS.plist"] && ![childPath hasSuffix:@".plist"] && testPaths.count == 0) {
                [MANAGER removeItemAtPath:childPath error:nil];
            }
        }
        
        // 转移头像缓存
        [AsyncImageView checkPath];
        NSDictionary *cache = [DEFAULTS objectForKey:@"iconCache"];
        for (NSString *key in cache) {
            [MANAGER createFileAtPath:[NSString stringWithFormat:@"%@/%@", CACHE_PATH, [ActionPerformer md5:key]] contents:[cache objectForKey:key] attributes:nil];
        }
        
        // 清除旧缓存
        [DEFAULTS removeObjectForKey:@"iconCache"];
        [DEFAULTS removeObjectForKey:@"iconSize"];
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"clearDirtyData3.2"];
    }
    
    if ([[DEFAULTS objectForKey:@"transportID3.3"] boolValue] == NO) { // 3.3之后版本ID储存采用一个Dictionary
        NSMutableArray *IDs = [[NSMutableArray alloc] init];
        for (int i = 0; i < MAX_ID_NUM; i++) {
            NSString *uid = [DEFAULTS objectForKey:[NSString stringWithFormat:@"id%d", i]];
            if (uid.length > 0) {
                [IDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:uid, @"id", [DEFAULTS objectForKey:[NSString stringWithFormat:@"password%d", i]], @"pass", nil]];
                [DEFAULTS removeObjectForKey:[NSString stringWithFormat:@"id%d", i]];
                [DEFAULTS removeObjectForKey:[NSString stringWithFormat:@"password%d", i]];
            }
        }
        [DEFAULTS setObject:IDs forKey:@"ID"];
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"transportID3.3"];
    }
    
    if ([[DEFAULTS objectForKey:@"clearIconCache3.5"] boolValue] == NO) { // 3.5之后链接全更改为https 缓存失效
        [MANAGER removeItemAtPath:CACHE_PATH error:nil];
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"clearIconCache3.5"];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"Become Active");
    // 返回后自动登录
    // 条件为 已登录 或 不是第一次打开软件且开启了自动登录
    if (([ActionPerformer checkLogin:NO] || [[DEFAULTS objectForKey:@"autoLogin"] boolValue] == YES) && [[DEFAULTS objectForKey:@"wakeLogin"] boolValue] == YES) {
        [self _loginAsync:YES];
    }
    [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"wakeLogin"];

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)_loginAsync:(BOOL)async {
    NSString *uid = UID;
    if (uid.length > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:uid, @"username", [ActionPerformer md5:PASS], @"password", @"ios", @"os", [ActionPerformer doDevicePlatform], @"device", [[UIDevice currentDevice] systemVersion], @"version", nil];
        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
        [performer performActionWithDictionary:dict toURL:@"login" withBlock:^(NSArray *result,NSError *err) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (err || result.count == 0 || ![[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
                [GROUP_DEFAULTS removeObjectForKey:@"token"];
                [[[UIAlertView alloc] initWithTitle:@"警告" message:@"后台登录失败,您现在处于未登录状态，请检查原因！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
            }else {
                [GROUP_DEFAULTS setObject:[[result objectAtIndex:0] objectForKey:@"token"] forKey:@"token"];
                NSLog(@"Login Completed - %@ Async:%@", uid, async ? @"YES" : @"NO");
            }
            dispatch_semaphore_signal(signal);
            [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
        }];
        if (!async) {
            dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
