//
//  SceneDelegate.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 9/14/26.
//  Copyright © 2026 熊典. All rights reserved.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        if (LIQUID_GLASS) {
            self.window.tintColor = GREEN_TINT;
        } else {
            self.window.tintColor = BLUE;
        }
        
        if (connectionOptions.URLContexts.count > 0) {
            [self scene:scene openURLContexts:connectionOptions.URLContexts];
        }
        
        if (connectionOptions.userActivities.count > 0) {
            NSUserActivity *userActivity = connectionOptions.userActivities.anyObject;
            if (userActivity) {
                [self scene:scene continueUserActivity:userActivity];
            }
        }
        
        if (connectionOptions.shortcutItem) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            [self windowScene:windowScene performActionForShortcutItem:connectionOptions.shortcutItem completionHandler:^(BOOL succeeded) {}];
        }
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate applicationDidBecomeActive:[UIApplication sharedApplication]];
}

- (void)sceneWillResignActive:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate applicationWillResignActive:[UIApplication sharedApplication]];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate applicationWillEnterForeground:[UIApplication sharedApplication]];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate applicationDidEnterBackground:[UIApplication sharedApplication]];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    for (UIOpenURLContext *context in URLContexts) {
        NSURL *url = context.URL;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        if (context.options.sourceApplication) {
            options[UIApplicationOpenURLOptionsSourceApplicationKey] = context.options.sourceApplication;
        }
        if (context.options.annotation) {
            options[UIApplicationOpenURLOptionsAnnotationKey] = context.options.annotation;
        }
        [appDelegate application:[UIApplication sharedApplication] openURL:url options:options];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate application:[UIApplication sharedApplication] continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> * _Nullable rest) {}];
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate application:[UIApplication sharedApplication] performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
}

@end
