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
//                          [NSNumber numberWithInt:2], @"proxy",
//                          @"school", @"proxyPosition",
                          [NSNumber numberWithBool:YES], @"autoLogin",
                          [NSNumber numberWithBool:YES], @"enterLogin",
                          [NSNumber numberWithBool:NO], @"wakeLogin",
                          [NSNumber numberWithBool:YES], @"vibrate",
                          [NSNumber numberWithBool:NO], @"picOnlyInWifi",
                          [NSNumber numberWithBool:NO], @"iconOnlyInWifi",
                          [NSNumber numberWithBool:YES], @"autoSave",
                          [NSNumber numberWithBool:YES], @"oppositeSwipe",
                          [NSNumber numberWithBool:NO], @"simpleView",
                          [NSNumber numberWithInt:1], @"toolbarEditor",
                          [NSNumber numberWithInt:1], @"viewCollectionType",
                          [NSNumber numberWithInt:100], @"textSize",
                          [NSNumber numberWithInt:MAX_ID_NUM / 2], @"IDNum",
                          [NSNumber numberWithInt:MAX_HOT_NUM / 2], @"hotNum",
                          @"2016-01-01", @"checkUpdate",
                          @"2016-01-01", @"checkPass",
                          @"www.chexie.net", @"URL",
                          @"", @"token",
                          @"", @"userInfo",
                          nil];
    [DEFAULTS registerDefaults:dict];
    [DEFAULTS removeObjectForKey:@"token"]; // 打开软件后清空登录状态
    [DEFAULTS removeObjectForKey:@"enterLogin"];
    [DEFAULTS removeObjectForKey:@"wakeLogin"];
    [[NSURLCache sharedURLCache] setMemoryCapacity:16.0 * 1024 * 1024];
    [[NSURLCache sharedURLCache] setDiskCapacity:64.0 * 1024 * 1024];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlert:) name:@"showAlert" object:nil];
    [self performSelectorInBackground:@selector(transport) withObject:nil];
    performer = [[ActionPerformer alloc] init];
    if (IOS >= 9.0) {
        [NOTIFICATION addObserver:self selector:@selector(collectionChanged) name:@"collectionChanged" object:nil];
    }
    return YES;
}

- (void)showAlert:(NSNotification *)noti {
    NSDictionary *dict = noti.userInfo;
    [[[UIAlertView alloc] initWithTitle:dict[@"title"] message:dict[@"message"] delegate:nil cancelButtonTitle:(dict[@"cancelTitle"] ? : @"好") otherButtonTitles:nil, nil] show];
}

- (BOOL)application:(nonnull UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * __nullable))restorationHandler {
    NSString *identifier = userActivity.userInfo[@"kCSSearchableItemActivityIdentifier"];
    NSArray *info = [identifier componentsSeparatedByString:@"\n"];
    UIViewController *view;
    UINavigationController *navi;
    NSDictionary *dict;
    if (userActivity.webpageURL.absoluteString.length > 0) {
        dict = [ContentViewController getLink:userActivity.webpageURL.absoluteString];
    }
    
    BOOL continueFronCollectionSearch = ([info[0] isEqualToString:@"collection"]);
    BOOL continueFromHandoff = (dict.count > 0 && ![dict[@"tid"] isEqualToString:@""]);
    if (continueFronCollectionSearch || continueFromHandoff) {
        view = self.window.rootViewController;
        while ([view presentedViewController] != nil) {
            view = [view presentedViewController];
        }
        
        ContentViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"content"];
        if (continueFronCollectionSearch) {
            dest.bid = info[1];
            dest.tid = info[2];
            dest.title = info[3];
        }else if (continueFromHandoff) {
            dest.bid = dict[@"bid"];
            dest.tid = dict[@"tid"];
            dest.floor = [NSString stringWithFormat:@"%d", [dict[@"p"] intValue] * 12];
            dest.exactFloor = dict[@"floor"];
            dest.title = userActivity.title;
        }
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
        [view presentViewController:navi animated:YES completion:nil];
    }
    
    dict = userActivity.userInfo;
    if ([dict[@"type"] isEqualToString:@"compose"]) {
        view = self.window.rootViewController;
        while ([view presentedViewController] != nil) {
            view = [view presentedViewController];
        }
        
        if (userActivity.webpageURL.absoluteString.length == 0 && [dict[@"bid"] length] > 0) {
            ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
            dest.bid = dict[@"bid"];
            
            navi = [[UINavigationController alloc] initWithRootViewController:dest];
            [navi setToolbarHidden:NO];
            dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
            [view presentViewController:navi animated:YES completion:nil];
            view = [view presentedViewController];
        }
        
        ComposeViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"compose"];
        dest.bid = dict[@"bid"];
        dest.tid = dict[@"tid"];
        dest.floor = dict[@"floor"];
        dest.defaultTitle = dict[@"title"];
        dest.defaultContent = dict[@"content"];
        dest.title = userActivity.title;
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        navi.modalPresentationStyle = UIModalPresentationFormSheet;
        [view presentViewController:navi animated:YES completion:nil];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    UIViewController *view = self.window.rootViewController;
    while ([view presentedViewController] != nil) {
        view = [view presentedViewController];
    }
    UINavigationController *navi;
    if ([shortcutItem.type isEqualToString:@"Hot"]) {
        ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
        dest.bid = @"hot";
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        [navi setToolbarHidden:NO];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
    }else if ([shortcutItem.type isEqualToString:@"Collection"]) {
        CollectionViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"collection"];
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
    }else if ([shortcutItem.type isEqualToString:@"Message"]) {
        MessageViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"message"];
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        [navi setToolbarHidden:NO];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back)];
    }else if ([shortcutItem.type isEqualToString:@"Compose"]) {
        ComposeViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"compose"];
        
        navi = [[UINavigationController alloc] initWithRootViewController:dest];
        navi.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [view presentViewController:navi animated:YES completion:nil];
}

- (void)back {
    UIViewController *view = self.window.rootViewController;
    while ([view presentedViewController] != nil) {
        view = [view presentedViewController];
    }
    [view dismissViewControllerAnimated:YES completion:nil];
}

- (void)collectionChanged { // 后台更新系统搜索内容
    [self performSelectorInBackground:@selector(updateCollection) withObject:nil];
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
    if (([ActionPerformer checkLogin:NO] || [[DEFAULTS objectForKey:@"autoLogin"] boolValue] == YES) && [[DEFAULTS objectForKey:@"wakeLogin"] boolValue] == YES) { // 已登录 或 不是第一次打开软件且开启了自动登录
        NSString *uid = UID;
        if (uid.length > 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:uid, @"username", [ActionPerformer md5:PASS], @"password", @"ios", @"os", [ActionPerformer doDevicePlatform], @"device", [[UIDevice currentDevice] systemVersion], @"version", nil];
            [performer performActionWithDictionary:dict toURL:@"login" withBlock:^(NSArray *result,NSError *err) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (err || result.count == 0 || ![[[result objectAtIndex:0] objectForKey:@"code"] isEqualToString:@"0"]) {
                    [DEFAULTS removeObjectForKey:@"token"];
                    [[[UIAlertView alloc] initWithTitle:@"警告" message:@"后台登录失败,您现在处于未登录状态，请检查原因！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
                }else {
                    [DEFAULTS setObject:[[result objectAtIndex:0] objectForKey:@"token"] forKey:@"token"];
                    NSLog(@"AutoLog Completed - %@", uid);
                }
                [NOTIFICATION postNotificationName:@"userChanged" object:nil];
            }];
        }
    }
    [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"wakeLogin"];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
