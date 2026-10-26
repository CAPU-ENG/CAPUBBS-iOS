//
//  AppDelegate.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "AppDelegate.h"
#import "AnimatedImageView.h"
#import "LoginViewController.h"
#import "ContentViewController.h"
#import "ListViewController.h"
#import "CollectionViewController.h"
#import "MessageViewController.h"
#import "ComposeViewController.h"
#import "WebViewController.h"
#import <CoreSpotlight/CoreSpotlight.h>

@implementation PreviewItem
@end

@implementation AppDelegate

@synthesize window = _window;

- (UIWindow *)window {
    if (_window) {
        return _window;
    }
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            id<UIWindowSceneDelegate> delegate = (id<UIWindowSceneDelegate>)windowScene.delegate;
            if ([delegate respondsToSelector:@selector(window)]) {
                UIWindow *win = [delegate window];
                if (win) {
                    return win;
                }
            }
        }
    }
    return nil;
}

- (void)setWindow:(UIWindow *)window {
    _window = window;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    if (LIQUID_GLASS) {
//        self.window.tintColor = GREEN_TINT;
        [[UIScrollView appearance] setUseSoftEdgeEffect:YES];
    } else {
//        self.window.tintColor = BLUE;
        UINavigationBar *navBar = [UINavigationBar appearance];
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navBarAppearance configureWithDefaultBackground];
        navBarAppearance.backgroundColor = [GREEN_DARK colorWithAlphaComponent:0.8];
        navBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]}; // title color
        navBarAppearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]}; // title color
        
        navBar.standardAppearance = navBarAppearance;
        navBar.scrollEdgeAppearance = navBarAppearance;
        navBar.compactAppearance = navBarAppearance;
        navBar.compactScrollEdgeAppearance = navBarAppearance;
        navBar.tintColor = [UIColor whiteColor]; // buttons color
        
        UIToolbar *toolbar = [UIToolbar appearance];
        UIToolbarAppearance *toolBarAppearance = [[UIToolbarAppearance alloc] init];
        //    [appearance configureWithOpaqueBackground];
        
        toolbar.standardAppearance = toolBarAppearance;
        toolbar.compactAppearance = toolBarAppearance;
        toolbar.scrollEdgeAppearance = toolBarAppearance;
        toolbar.compactScrollEdgeAppearance = toolBarAppearance;
    }
    
    [[UITextField appearance] setClearButtonMode:UITextFieldViewModeWhileEditing];
//    [[UITextField appearance] setBackgroundColor:[UIColor systemBackgroundColor]];
//    if (LIQUID_GLASS) {
//        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setBackgroundColor:[UIColor clearColor]];
//    }
    [[UITextView appearance] setBackgroundColor:[UIColor systemBackgroundColor]];
    [[UITableView appearance] setBackgroundColor:[UIColor clearColor]];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.6]];
    [[UIButton appearance] setPointerInteractionEnabled:YES];
    [[UISwitch appearance] setOnTintColor:[UIColor tintColor]];
    [[UICollectionView appearance] setBackgroundColor:[UIColor clearColor]];
    
    NSDictionary *defaults = @{
        @"autoLogin" : @YES,
        @"vibrate" : @YES,
        @"picOnlyInWifi" : @NO,
        @"disableScript" : @NO,
        @"changeBackground" : @YES,
        @"autoSave" : @YES,
        @"oppositeSwipe" : @YES,
        @"toolbarEditor" : @1,
        @"viewCollectionType" : @1,
        @"textSize" : @100,
        @"superUser": @NO,
        @"checkUpdate" : @"2025-01-01",
    };
    NSDictionary *groupDefaults = @{
        @"URL" : DEFAULT_SERVER_URL,
        @"token" : @"",
        @"userInfo" : @"",
        @"iconOnlyInWifi" : @NO,
        @"simpleView" : @NO,
    };
    [DEFAULTS registerDefaults:defaults];
    [GROUP_DEFAULTS registerDefaults:groupDefaults];
    wakeLogin = NO;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:beijingTimeZone];
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:128.0 * 1024 * 1024];
    [[NSURLCache sharedURLCache] setDiskCapacity:512.0 * 1024 * 1024];
    [AnimatedImageView checkIconCachePath];
    [self migrateLegacyData];
    
    [NOTIFICATION addObserver:self selector:@selector(showAlert:) name:@"showAlert" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(collectionChanged) name:@"collectionChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(sendEmail:) name:@"sendEmail" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(previewFile:) name:@"previewFile" object:nil];
    if ([Helper checkLogin:NO] && [[DEFAULTS objectForKey:@"autoLogin"] boolValue]) {
        [self login:nil];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[ReachabilityManager sharedManager] stopMonitoring];
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
    if (([Helper checkLogin:NO] || [[DEFAULTS objectForKey:@"autoLogin"] boolValue]) && wakeLogin) {
        [self login:nil];
    }
    wakeLogin = YES;
    [[ReachabilityManager sharedManager] startMonitoring];
    [self maybeCheckUpdate];
    
    static dispatch_once_t addTapListenerToken;
    dispatch_once(&addTapListenerToken, ^{
        UITapGestureRecognizer *globalTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalTap:)];
        globalTapGesture.cancelsTouchesInView = NO;
        [[UIApplication sharedApplication].delegate.window addGestureRecognizer:globalTapGesture];
    });
    
#ifdef DEBUG
//    [AppDelegate openLink:[Helper getLink:@"/bbs/content/?p=17&bid=4&tid=19919#195"] postTitle:nil]; // Apple Music
//    [AppDelegate openLink:[Helper getLink:@"/bbs/content/?p=25&bid=4&tid=19837#298"] postTitle:nil]; // Pictures
//    [AppDelegate openLink:[Helper getLink:@"/bbs/content/?p=25&bid=4&tid=19837#293"] postTitle:nil]; // Attachments
//    [self _handleUrlRequestWithDictionary:@{@"open": @"compose", @"bid": @"9", @"title": @"Test"}]; // Compose
//    [self _handleUrlRequestWithDictionary:@{@"open": @"message"}]; // Message center
#endif
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

+ (UIViewController *)getTopViewController {
    __block UIViewController *topVC = nil;
    dispatch_main_sync_safe(^{
        UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
        if (!keyWindow) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) {
                            keyWindow = w;
                            break;
                        }
                    }
                    if (!keyWindow && windowScene.windows.count > 0) {
                        keyWindow = windowScene.windows.firstObject;
                    }
                }
            }
        }
        if (!keyWindow) {
            return;
        }
        topVC = keyWindow.rootViewController;
        while (topVC.presentedViewController && !topVC.presentedViewController.isBeingDismissed && ![topVC isKindOfClass:[UIAlertController class]]) {
            topVC = topVC.presentedViewController;
        }
    });
    return topVC;
}

+ (UIViewController *)viewControllerForView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        responder = [responder nextResponder];
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

+ (void)setAdaptiveSheetFor:(UIViewController *)viewController popoverSource:(UIView *)source halfScreen:(BOOL)halfScreen {
    if (!viewController || !viewController.navigationController) {
        return;
    }
    UINavigationController *navi = viewController.navigationController;
    UISheetPresentationController *sheetPC;
    if (source && ([source isKindOfClass:[UIView class]] || [source isKindOfClass:[UIBarButtonItem class]])) {
        navi.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPC = navi.popoverPresentationController;
        if (popoverPC) {
            if ([source isKindOfClass:[UIBarButtonItem class]]) {
                popoverPC.barButtonItem = (UIBarButtonItem *)source;
            } else {
                popoverPC.sourceView = source;
                popoverPC.sourceRect = source.bounds;
            }
            sheetPC = popoverPC.adaptiveSheetPresentationController;
        }
    } else {
        // This is not adaptive, but the best fallback we can do (sheet on iPhone but not iPad)
        // The modal presentation style is form / page sheet by default
        if (viewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ||
            viewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ||
            !halfScreen) {
            sheetPC = navi.sheetPresentationController;
        }
    }
    if (!sheetPC) {
        return;
    }
    if (halfScreen) {
        sheetPC.detents = @[[UISheetPresentationControllerDetent mediumDetent], [UISheetPresentationControllerDetent largeDetent]];
        sheetPC.prefersGrabberVisible = YES;
        sheetPC.prefersScrollingExpandsWhenScrolledToEdge = NO;
    }
    sheetPC.prefersEdgeAttachedInCompactHeight = YES;
    sheetPC.widthFollowsPreferredContentSizeWhenEdgeAttached = YES;
}

+ (void)setPrefersLargeTitles:(UINavigationController *)navigationController {
    if (LIQUID_GLASS) {
        navigationController.navigationBar.prefersLargeTitles = YES;
    }
}

+ (UIStatusBarStyle)preferredStatusBarStyle {
    if (LIQUID_GLASS) {
        return UIStatusBarStyleDarkContent;
    } else {
        return UIStatusBarStyleLightContent;
    }
}

+ (UIBarButtonItem *)getCloseButtonForTarget:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:target action:action];
}

+ (UIView *)keyboardToolViewWithLeftButtons:(NSArray<UIButton *> *)leftButtons
                                rightButtons:(NSArray<UIButton *> *)rightButtons {
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    wrapperView.frame = CGRectMake(0, 0, 0, 40); // Only height matters here
    
    UIView *keyboardToolView = [[UIView alloc] init];
    keyboardToolView.translatesAutoresizingMaskIntoConstraints = NO;
    keyboardToolView.layer.cornerRadius = 18;
    keyboardToolView.backgroundColor = [UIColor systemBackgroundColor];
    
    [wrapperView addSubview:keyboardToolView];
    [NSLayoutConstraint activateConstraints:@[
        [keyboardToolView.leadingAnchor constraintEqualToAnchor:wrapperView.leadingAnchor constant:4],
        [keyboardToolView.trailingAnchor constraintEqualToAnchor:wrapperView.trailingAnchor constant:-4],
        [keyboardToolView.topAnchor constraintEqualToAnchor:wrapperView.topAnchor],
        [keyboardToolView.bottomAnchor constraintEqualToAnchor:wrapperView.bottomAnchor constant:-4],
    ]];

    // 左侧 Stack
    UIStackView *leftStack = [[UIStackView alloc] initWithArrangedSubviews:leftButtons];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.spacing = 12;
    leftStack.translatesAutoresizingMaskIntoConstraints = NO;

    // 右侧 Stack
    UIStackView *rightStack = [[UIStackView alloc] initWithArrangedSubviews:rightButtons];
    rightStack.axis = UILayoutConstraintAxisHorizontal;
    rightStack.spacing = 12;
    rightStack.translatesAutoresizingMaskIntoConstraints = NO;

    [keyboardToolView addSubview:leftStack];
    [keyboardToolView addSubview:rightStack];

    [NSLayoutConstraint activateConstraints:@[
        // 左侧 stack 靠左
        [leftStack.leadingAnchor constraintEqualToAnchor:keyboardToolView.safeAreaLayoutGuide.leadingAnchor constant:12],
        [leftStack.centerYAnchor constraintEqualToAnchor:keyboardToolView.centerYAnchor],

        // 右侧 stack 靠右
        [rightStack.trailingAnchor constraintEqualToAnchor:keyboardToolView.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [rightStack.centerYAnchor constraintEqualToAnchor:keyboardToolView.centerYAnchor],
    ]];

    return wrapperView;
}

+ (UIButton *)keyboardToolButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)showAlert:(NSNotification *)noti {
    NSDictionary *dict = noti.userInfo;
    [[AppDelegate getTopViewController] showAlertWithTitle:dict[@"title"] message:dict[@"message"] cancelTitle:dict[@"cancelTitle"] ? : @"好"];
}

- (void)sendEmail:(NSNotification *)notification {
    NSDictionary *mailInfo = notification.userInfo;
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setToRecipients:mailInfo[@"recipients"]];
        if (mailInfo[@"subject"]) {
            [mail setSubject:mailInfo[@"subject"]];
        }
        if (mailInfo[@"body"]) {
            BOOL isHTML = mailInfo[@"isHTML"] ? [mailInfo[@"isHTML"] boolValue] : NO;
            [mail setMessageBody:mailInfo[@"body"] isHTML:isHTML];
        }
        [[AppDelegate getTopViewController] presentViewControllerSafe:mail];
    } else {
        [[AppDelegate getTopViewController] showAlertWithTitle:@"您的设备无法发送邮件" message:mailInfo[@"fallbackMessage"] ?: @"请查看系统设置"];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)previewFile:(NSNotification *)noti {
    [self _previewFile:noti attempt:1];
}

- (void)_previewFile:(NSNotification *)noti attempt:(int)attempt {
    NSDictionary *dict = noti.userInfo;
    // Already previewing a file
    if (previewItems) {
        if (attempt <= 10) {
            dispatch_global_after(0.2, ^{
                [self _previewFile:noti attempt:attempt + 1];
            });
        }
        return;
    }
    NSData *previewFileData = dict[@"fileData"];
    NSString *previewFileName = dict[@"fileName"];
    if (!previewFileData || !previewFileName) {
        return;
    }
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:previewFileName];
    if (![previewFileData writeToFile:path atomically:YES]) {
        return;
    }
    
    PreviewItem *previewItem = [[PreviewItem alloc] init];
    previewItem.previewItemURL = [NSURL fileURLWithPath:path];
    previewItem.previewItemTitle = dict[@"fileTitle"];
    if (dict[@"frame"] && [dict[@"frame"] isKindOfClass:[UIView class]]) {
        previewItem.previewFrame = dict[@"frame"];
    } else {
        previewItem.previewFrame = nil;
    }
    if (dict[@"transitionImage"] && [dict[@"transitionImage"] isKindOfClass:[UIImage class]]) {
        previewItem.previewTransitionImage = dict[@"transitionImage"];
    } else {
        previewItem.previewTransitionImage = nil;
    }
    previewItems = @[previewItem];
    
    dispatch_main_sync_safe(^{
        if (![QLPreviewController canPreviewItem:previewItem]) {
            [[AppDelegate getTopViewController] showAlertWithTitle:@"系统无法预览该文件" message:@"可以保存文件或使用其它App打开"];
        }
        QLPreviewController *previewController = [[QLPreviewController alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
        [[AppDelegate getTopViewController] presentViewControllerSafe:previewController];
    });
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return previewItems.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return previewItems[index];
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    if (!previewItems) {
        return;
    }
    for (PreviewItem *previewItem in previewItems) {
        [MANAGER removeItemAtURL:previewItem.previewItemURL error:nil];
    }
    previewItems = nil;
}

- (UIImage *)previewController:(QLPreviewController *)controller transitionImageForPreviewItem:(id<QLPreviewItem>)item contentRect:(CGRect *)contentRect {
    PreviewItem *previewItem = (PreviewItem *)item;
    if (!previewItem || !previewItem.previewFrame) {
        *contentRect = CGRectZero;
        return nil;
    }
    if (previewItem.previewTransitionImage) {
        *contentRect = previewItem.previewFrame.bounds;
        return previewItem.previewTransitionImage;
    } else if ([previewItem.previewFrame isKindOfClass:[UIImageView class]]) {
        *contentRect = previewItem.previewFrame.bounds;
        return ((UIImageView *)previewItem.previewFrame).image;
    }
    *contentRect = CGRectZero;
    return nil;
}

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id<QLPreviewItem>)item inSourceView:(UIView * _Nullable * _Nonnull)view {
    PreviewItem *previewItem = (PreviewItem *)item;
    if (!previewItem || !previewItem.previewFrame) {
        *view = nil;
        return CGRectZero;
    }
    *view = previewItem.previewFrame;
    return previewItem.previewFrame.bounds;
}

+ (void)openLink:(NSDictionary *)linkInfo postTitle:(NSString *)title {
    if ([linkInfo[@"bid"] length] == 0) {
        return;
    }
    NSDictionary *naviDict = [linkInfo[@"tid"] length] > 0 ? @{
        @"open": @"post",
        @"bid": linkInfo[@"bid"],
        @"tid": linkInfo[@"tid"],
        @"page": linkInfo[@"p"],
        @"floor": linkInfo[@"floor"],
        @"naviTitle": title ?: @""
    } : @{
        @"open": @"list",
        @"bid": linkInfo[@"bid"],
        @"page": linkInfo[@"p"],
    };
    dispatch_main_async_safe(^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        dispatch_global_default_async(^{
            [appDelegate _handleUrlRequestWithDictionary:naviDict];
        });
    });
}

+ (void)openURL:(NSString *)url fullScreen:(BOOL)fullScreen {
    dispatch_main_async_safe((^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        dispatch_global_default_async(^{
            [appDelegate _handleUrlRequestWithDictionary:@{
                @"open": @"web",
                @"url": url,
                @"fullScreen": @(fullScreen),
            }];
        });
    }));
}

+ (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if (interaction == UITextItemInteractionPresentActions) {
        return YES;
    }
    NSString *path = URL.absoluteString;
    if ([path hasPrefix:@"mailto:"]) {
        NSString *mailAddress = [path substringFromIndex:@"mailto:".length];
        [NOTIFICATION postNotificationName:@"sendEmail" object:nil userInfo:@{
            @"recipients": @[mailAddress]
        }];
        return NO;
    }
    
    if ([path hasPrefix:@"tel:"] || [path hasPrefix:@"sms:"] || [path hasPrefix:@"facetime:"] || [path hasPrefix:@"maps:"]) {
        // Directly open
        return YES;
    }
    
    if ([Helper isHttpScheme:URL.scheme]) {
        NSDictionary *linkInfo = [Helper getLink:path];
        if (linkInfo.count > 0 && [linkInfo[@"bid"] length] > 0) {
            [self openLink:linkInfo postTitle:nil];
        } else {
            [self openURL:path fullScreen:YES];
        }
        return NO;
    } else {
        return YES;
    }
}

+ (void)handleImageClickWithMessage:(WKScriptMessage *)message hud:(MBProgressHUD *)hud {
    NSDictionary *payload = message.body;
    if ([payload[@"loading"] boolValue]) {
        [hud showWithProgressMessage:@"图片加载中"];
        return;
    }
    NSString *base64Data = payload[@"data"] ?: @"";
    NSString *imgSrc = payload[@"src"] ?: @"";
    NSURL *imageUrl = [NSURL safeURLWithString:imgSrc];
    NSString *alt = payload[@"alt"] ?: @"";
    // 去掉前缀
    NSRange range = [base64Data rangeOfString:@","];
    if (range.location != NSNotFound) {
        NSString *alt = payload[@"alt"];
        NSString *base64String = [base64Data substringFromIndex:range.location + 1];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        ImageFileType type = [AnimatedImageView fileType:imageData];
        if (type != ImageFileTypeUnknown) {
            [hud hideWithSuccessMessage:@"图片加载成功"];
            NSString *fileName = [Helper fileNameFromURL:imageUrl] ?: [[Helper md5:imgSrc] stringByAppendingPathExtension:[AnimatedImageView fileExtension:type]];
            [self presentImage:imageData fileName:fileName title:alt];
            return;
        }
    }
    
    NSString *errorMessage = payload[@"error"] ?: @"图片加载失败";
    // Try reload in app to overcome CORS. (Most external sites will fail the js fetch request)
    if (imageUrl) {
        [hud showWithProgressMessage:@"图片加载中"];
        [Downloader loadURL:imageUrl progress:^(float progress, NSUInteger expectedBytes) {
            [hud updateToProgress:progress];
        } completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            ImageFileType type = [AnimatedImageView fileType:data];
            if (error || type == ImageFileTypeUnknown) {
                [hud hideWithFailureMessage:error ? errorMessage : @"图片格式不支持"];
                return;
            }
            [hud hideWithSuccessMessage:@"图片加载成功"];
            NSString *fileName;
            if (response.suggestedFilename && response.suggestedFilename.pathExtension.length > 0) {
                fileName = response.suggestedFilename;
            } else {
                fileName = [Helper fileNameFromURL:imageUrl] ?: [[Helper md5:imgSrc] stringByAppendingPathExtension:[AnimatedImageView fileExtension:type]];
            }
            [self presentImage:data fileName:fileName title:alt];
        }];
    } else {
        [hud hideWithFailureMessage:errorMessage];
    }
}

+ (void)presentImage:(NSData *)imageData fileName:(NSString *)fileName title:(NSString *)alt {
    [NOTIFICATION postNotificationName:@"previewFile" object:nil userInfo:@{
        @"fileData": imageData,
        @"fileName": fileName,
        @"fileTitle": alt.length > 0 ? alt : @"查看图片"
    }];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if (!HAS_SHOWN_EULA) {
        return NO;
    }
    
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        NSArray *collectionParts = @[];
        NSString *identifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        if (identifier.length > 0) {
            collectionParts = [identifier componentsSeparatedByString:@"\n"];
        }
        // Continue from collection search
        if (collectionParts.count >= 4 && [collectionParts[0] isEqualToString:@"collection"]) {
            NSDictionary *naviDict = @{
                @"open": @"post",
                @"bid": collectionParts[1],
                @"tid": collectionParts[2],
                @"naviTitle": collectionParts[3]
            };
            [self _handleUrlRequestWithDictionary:naviDict];
            return YES;
        }
    }
    
    NSDictionary *activityInfo = userActivity.userInfo;
    BOOL isCompose = activityInfo && [activityInfo[@"type"] isEqualToString:@"compose"];
    NSDictionary *linkInfo;
    if (userActivity.webpageURL && userActivity.webpageURL.absoluteString.length > 0) {
        linkInfo = [Helper getLink:userActivity.webpageURL.absoluteString];
    }
    // From universal link or handfoff
    if ([linkInfo[@"bid"] length] > 0) {
        [AppDelegate openLink:linkInfo postTitle:isCompose ? @"" : userActivity.title];
        if (!isCompose) {
            return YES;
        }
    }
    
    if (isCompose) {
        dispatch_global_after(0.5, ^{
            NSMutableDictionary *naviDict = [NSMutableDictionary dictionaryWithDictionary:@{
                @"open": @"compose",
                @"naviTitle": userActivity.title ?: @""
            }];
            [naviDict addEntriesFromDictionary:activityInfo];
            [self _handleUrlRequestWithDictionary:naviDict];
        });
        return YES;
    }
    
    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (!HAS_SHOWN_EULA) {
        completionHandler(NO);
        return;
    }
    
    dispatch_global_default_async(^{
        if ([shortcutItem.type isEqualToString:@"Hot"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"hot"}];
        } else if ([shortcutItem.type isEqualToString:@"Collection"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"collection"}];
        } else if ([shortcutItem.type isEqualToString:@"Message"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"message"}];
        } else if ([shortcutItem.type isEqualToString:@"Compose"]) {
            [self _handleUrlRequestWithDictionary:@{@"open": @"compose"}];
        }
    });
    completionHandler(YES);
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (!HAS_SHOWN_EULA) {
        return NO;
    }
    
    if ([url.scheme isEqualToString:@"capubbs"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in components.queryItems) {
            if (item.name.length == 0 || item.value == nil) {
                continue;
            }
            params[item.name] = item.value;
        }
        if (params.count > 0) {
            dispatch_global_default_async(^{
                [self _handleUrlRequestWithDictionary:params];
            });
            return YES;
        }
        return NO;
    }
    
    if (url.isFileURL) {
        BOOL needsStopAccessing = [url startAccessingSecurityScopedResource];

        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
        if (needsStopAccessing) {
            [url stopAccessingSecurityScopedResource];
        }
        if (error) {
            NSLog(@"Handle file error - %@", error);
            return NO;
        }
        
        NSArray *importData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error) {
            NSLog(@"Handle file error - wrong json format");
            return NO;
        }
        
        BOOL hasValidCollection = NO;
        if ([importData isKindOfClass:[NSArray class]]) {
            for (id item in importData) {
                if ([item isKindOfClass:[NSDictionary class]] && item[@"type"] && item[@"data"] && item[@"sig"] && [[Helper getSigForData:item[@"data"]] isEqualToString:item[@"sig"]]) {
                    if (!hasValidCollection && [item[@"type"] isEqualToString:@"capubbs_collection"] && [item[@"data"] isKindOfClass:[NSArray class]]) {
                        hasValidCollection = YES;
                        [self _handleImportCollectionData:item[@"data"]];
                    }
                }
            }
        }
        if (!hasValidCollection) {
            [[AppDelegate getTopViewController] showAlertWithTitle:@"提示" message:@"您打开了一个JSON文件，但里面不包含有效的导入内容"];
        }
        return hasValidCollection;
    }
    
    return NO;
}

- (void)_handleImportCollectionData:(NSArray *)data {
    [[AppDelegate getTopViewController] showAlertWithTitle:[NSString stringWithFormat:@"发现%ld项收藏", data.count] message:@"是否导入？\n导入时会自动排除重复项" confirmTitle:@"导入" confirmAction:^(UIAlertAction *action) {
        dispatch_global_default_async(^{
            int successCount = 0;
            int duplicateCount = 0;
            int failCount = 0;
            NSMutableArray *collections = [NSMutableArray arrayWithArray:[DEFAULTS objectForKey:@"collection"]];
            for (id newItem in data) {
                if (![newItem isKindOfClass:[NSDictionary class]]) {
                    failCount++;
                    continue;
                }
                
                NSString *bid = newItem[@"bid"];
                NSString *tid = newItem[@"tid"];
                NSString *collectionTime = newItem[@"collectionTime"];
                NSString *title = newItem[@"title"];
                if (!bid.length || !tid.length || !collectionTime.length || !title.length) {
                    failCount++;
                    continue;
                }
                
                BOOL hasDuplicate = NO;
                for (NSDictionary *myItem in collections) {
                    if ([myItem[@"bid"] isEqualToString:bid] && [myItem[@"tid"] isEqualToString:tid]) {
                        hasDuplicate = YES;
                        break;
                    }
                }
                if (hasDuplicate) {
                    duplicateCount++;
                } else {
                    successCount++;
                    [collections addObject:newItem];
                }
            }
            if (successCount > 0) {
                [DEFAULTS setObject:collections forKey:@"collection"];
                [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
            }
            [[AppDelegate getTopViewController] showAlertWithTitle:@"导入结束" message:[NSString stringWithFormat:@"成功：%d\n重复：%d\n失败：%d", successCount, duplicateCount, failCount]];
        });
    }];
}

- (void)_handleUrlRequestWithDictionary:(NSDictionary *)dict {
    if (!HAS_SHOWN_EULA) {
        return;
    }
    
    NSString *open = dict[@"open"];
    if (open.length == 0) {
        return;
    }
    UIViewController *view = [AppDelegate getTopViewController];
    if ([open isEqualToString:@"message"]) {
        [self login:^(BOOL success) {
            if (!success) {
                return;
            }
            wakeLogin = NO;
            
            dispatch_main_sync_safe(^{
                MessageViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"message"];
                
                dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(back)];
                UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
                navi.modalPresentationStyle = UIModalPresentationFullScreen;
                navi.toolbarHidden = NO;
                [view presentViewControllerSafe:navi];
            });
        }];
    } else if ([open isEqualToString:@"hot"]) {
        dispatch_main_sync_safe(^{
            ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
            dest.bid = @"hot";
            
            dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(back)];
            UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
            navi.modalPresentationStyle = UIModalPresentationFullScreen;
            navi.toolbarHidden = NO;
            [view presentViewControllerSafe:navi];
        });
    } else if ([open isEqualToString:@"collection"]) {
        dispatch_main_sync_safe(^{
            CollectionViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"collection"];
            
            dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(back)];
            UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
            navi.modalPresentationStyle = UIModalPresentationFullScreen;
            [view presentViewControllerSafe:navi];
        });
    } else if ([open isEqualToString:@"compose"]) {
        [self login:^(BOOL success) {
            if (!success) {
                return;
            }
            wakeLogin = NO;
            
            dispatch_main_sync_safe(^{
                ComposeViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"compose"];
                
                if (dict[@"bid"]) {
                    dest.bid = dict[@"bid"];
                    dest.tid = dict[@"tid"];
                    dest.floor = dict[@"floor"];
                    dest.defaultTitle = dict[@"title"];
                    dest.defaultContent = dict[@"content"];
                    dest.title = dict[@"naviTitle"];
                }
                
                UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
                navi.modalPresentationStyle = UIModalPresentationPageSheet;
                [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
                [view presentViewControllerSafe:navi];
            });
        }];
    } else if ([open isEqualToString:@"list"]) {
        dispatch_main_sync_safe(^{
            ListViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"list"];
            dest.bid = dict[@"bid"];
            NSInteger page = [dict[@"page"] integerValue];
            if (page > 0) {
                dest.page = page;
            }
            
            dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(back)];
            UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
            navi.modalPresentationStyle = UIModalPresentationFullScreen;
            navi.toolbarHidden = NO;
            [view presentViewControllerSafe:navi];
        });
    } else if ([open isEqualToString:@"post"]) {
        dispatch_main_sync_safe(^{
            ContentViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"content"];
            
            dest.bid = dict[@"bid"];
            dest.tid = dict[@"tid"];
            if (dict[@"page"]) {
                dest.destinationPage = dict[@"page"];
            }
            if (dict[@"floor"]) {
                dest.destinationFloor = dict[@"floor"];
                // dest.openDestinationLzl = YES; // Do we need it? not tested yet
            }
            if (dict[@"naviTitle"]) {
                dest.title = dict[@"naviTitle"];
            } else {
                dest.title = @"帖子加载中";
            }
            
            dest.navigationItem.leftBarButtonItem = [AppDelegate getCloseButtonForTarget:self action:@selector(back)];
            UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
            navi.modalPresentationStyle = UIModalPresentationFullScreen;
            [view presentViewControllerSafe:navi];
        });
    } else if ([open isEqualToString:@"web"]) {
        dispatch_main_sync_safe(^{
            WebViewController *dest = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"webview"];
            dest.URL = dict[@"url"];
            
            UINavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:dest];
            if ([dict[@"fullScreen"] boolValue]) {
                navi.modalPresentationStyle = UIModalPresentationFullScreen;
            } else {
                navi.modalPresentationStyle = UIModalPresentationPageSheet;
                [AppDelegate setAdaptiveSheetFor:dest popoverSource:nil halfScreen:NO];
            }
            [view presentViewControllerSafe:navi];
        });
    }
    NSLog(@"Open with %@", open);
}

- (void)back {
    [[AppDelegate getTopViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)collectionChanged { // 后台更新系统搜索内容
    dispatch_global_default_async(^{
        [self updateCollection];
    });
}

- (void)updateCollection {
    NSMutableArray *seachableItems = [NSMutableArray array];
    NSArray *collections = [DEFAULTS objectForKey:@"collection"];
    if (!collections || collections.count == 0) {
        [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[BUNDLE_IDENTIFIER] completionHandler:nil];
        return;
    }
    for (NSDictionary *dict in collections) {
        NSString *bid = dict[@"bid"];
        NSString *tid = dict[@"tid"];
        NSString *title = dict[@"title"];
        NSString *author = dict[@"author"] ?: @"";
        NSString *text = dict[@"text"] ?: @"";
        CSSearchableItemAttributeSet *attr = [[CSSearchableItemAttributeSet alloc] initWithContentType:UTTypeText];
        attr.title = title;
        if (text.length > 0) {
            if (author.length > 0) {
                text = [NSString stringWithFormat:@"%@ - %@", author, text];
            } else if (bid) {
                text = [NSString stringWithFormat:@"%@ - %@", [Helper getBoardTitle:bid], text];
            }
        }
        attr.textContent = text;
        NSString *textSummary = (text.length > 2000) ? [text substringToIndex:2000] : text;
        attr.contentDescription = textSummary;
        
        UIImage *boardIcon = [UIImage imageNamed:[NSString stringWithFormat:@"b%@", bid]];
        attr.thumbnailData = UIImagePNGRepresentation(boardIcon ?: PLACEHOLDER);
        attr.keywords = @[@"CAPUBBS", @"收藏", @"CAPU", @"北大车协", @"车协", @"chexie"];
        CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[NSString stringWithFormat:@"collection\n%@\n%@\n%@", bid, tid, title] domainIdentifier:BUNDLE_IDENTIFIER attributeSet:attr];
        [seachableItems addObject:item];
    }
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[BUNDLE_IDENTIFIER] completionHandler:^(NSError * __nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
        [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:seachableItems completionHandler:^(NSError * __nullable error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                NSLog(@"Collection Saved To System");
            }
        }];
    }];
}

- (void)migrateLegacyData {
    if (![[GROUP_DEFAULTS objectForKey:@"activated"] boolValue]) {
        for (NSString *key in @[@"URL", @"uid", @"pass", @"token", @"userInfo", @"iconOnlyInWifi", @"simpleView"]) {
            id obj = [DEFAULTS objectForKey:key];
            if (obj) {
                [GROUP_DEFAULTS setObject:obj forKey:key];
                [DEFAULTS removeObjectForKey:key];
            }
        }
        [GROUP_DEFAULTS setObject:@(YES) forKey:@"activated"];
    }
    
    if (![[DEFAULTS objectForKey:@"clearDirtyData3.2"] boolValue]) { // 3.2之前版本采用NSUserDefaults储存头像 文件夹里面有许多垃圾数据
        NSString *rootFolder = NSHomeDirectory();
        NSArray *childPaths = [MANAGER subpathsAtPath:rootFolder];
        for (NSString *path in childPaths) {
            NSString *childPath = [NSString stringWithFormat:@"%@/%@", rootFolder, path];
            NSArray *testPaths = [MANAGER subpathsAtPath:childPath];
            if ([childPath containsString:@"CAPUBBS.plist"] && ![childPath hasSuffix:@".plist"] && testPaths.count == 0) {
                [MANAGER removeItemAtPath:childPath error:nil];
            }
        }
        
        // 清除旧缓存
        [DEFAULTS removeObjectForKey:@"iconCache"];
        [DEFAULTS removeObjectForKey:@"iconSize"];
        [DEFAULTS setObject:@(YES) forKey:@"clearDirtyData3.2"];
    }
    
    if (![[DEFAULTS objectForKey:@"transportID3.3"] boolValue]) { // 3.3之后版本ID储存采用一个Dictionary
        NSMutableArray *IDs = [NSMutableArray array];
        for (int i = 0; i < 10; i++) {
            NSString *uid = [DEFAULTS objectForKey:[NSString stringWithFormat:@"id%d", i]];
            if (uid.length > 0) {
                [IDs addObject:@{
                    @"id" : uid,
                    @"pass" : [DEFAULTS objectForKey:[NSString stringWithFormat:@"password%d", i]]
                }];
                [DEFAULTS removeObjectForKey:[NSString stringWithFormat:@"id%d", i]];
                [DEFAULTS removeObjectForKey:[NSString stringWithFormat:@"password%d", i]];
            }
        }
        [DEFAULTS setObject:IDs forKey:@"ID"];
        [DEFAULTS setObject:@(YES) forKey:@"transportID3.3"];
    }
    
//    if (![[DEFAULTS objectForKey:@"clearIconCache3.5"] boolValue]) { // 3.5之后链接全更改为https 缓存失效
//        [MANAGER removeItemAtPath:ICON_CACHE_PATH error:nil];
//        [DEFAULTS setObject:@(YES) forKey:@"clearIconCache3.5"];
//    }
    
    if (![[DEFAULTS objectForKey:@"migrateIconCache4.1"] boolValue]) {
        if ([[DEFAULTS objectForKey:@"clearIconCache3.5"] boolValue]) { // 3.5之前的旧缓存全部无效
            NSString *oldCachePath1 = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"IconCache"];
            NSString *oldCachePath2 = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"IconCache"];
            for (NSString *oldPath in @[oldCachePath1, oldCachePath2]) {
                if (![MANAGER fileExistsAtPath:oldPath]) {
                    continue;
                }
                NSDirectoryEnumerator *enumerator = [MANAGER enumeratorAtPath:oldPath];
                NSString *fileName;
                while ((fileName = [enumerator nextObject])) {
                    NSString *sourcePath = [oldPath stringByAppendingPathComponent:fileName];
                    NSString *destinationPath = [ICON_CACHE_PATH stringByAppendingPathComponent:fileName];
                    if (![MANAGER fileExistsAtPath:destinationPath]) {
                        [MANAGER moveItemAtPath:sourcePath toPath:destinationPath error:nil];
                    }
                }
                [MANAGER removeItemAtPath:oldPath error:nil];
            }
        }
        [DEFAULTS setObject:@(YES) forKey:@"clearIconCache3.5"];
        [DEFAULTS setObject:@(YES) forKey:@"migrateIconCache4.1"];
    }
    
    // Reset default server URL
    if (![[DEFAULTS objectForKey:@"resetUrl4.3"] boolValue]) {
        [GROUP_DEFAULTS setObject:DEFAULT_SERVER_URL forKey:@"URL"];
        [DEFAULTS setObject:@(YES) forKey:@"resetUrl4.3"];
    }
    
    if ([[DEFAULTS objectForKey:@"IDNum"] intValue] == 10 && [[DEFAULTS objectForKey:@"hotNum"] intValue] == 40) {
        [DEFAULTS setObject:@(YES) forKey:@"superUser"];
    }
    [DEFAULTS removeObjectForKey:@"IDNum"];
    [DEFAULTS removeObjectForKey:@"hotNum"];
}

- (void)handleGlobalTap:(UITapGestureRecognizer *)gesture {
    [NOTIFICATION postNotificationName:@"globalTap" object:nil];
}

- (void)login:(void (^)(BOOL success))callback {
    NSString *uid = UID;
    if (uid.length == 0) {
        if (callback) {
            callback(NO);
        }
        return;
    }
    NSDictionary *dict = @{
        @"username" : uid,
        @"password" : [Helper md5:PASS],
    };
    [Helper callApiWithParams:dict toURL:@"login" callback:^(NSArray *result,NSError *err) {
        BOOL success = !err && result.count > 0 && [result[0][@"code"] isEqualToString:@"0"];
        if (!success) {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                [GROUP_DEFAULTS removeObjectForKey:@"token"];
                [[AppDelegate getTopViewController] showAlertWithTitle:@"警告" message:@"后台登录失败,您现在处于未登录状态，请检查您的网络连接！"];
            }
        } else {
            [GROUP_DEFAULTS setObject:result[0][@"token"] forKey:@"token"];
            NSLog(@"Login Completed");
        }
        [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
        if (callback) {
            callback(success);
        }
    }];
}

- (void)maybeCheckUpdate {
    NSDate *currentDate = [NSDate date];
    NSDate *lastDate =[formatter dateFromString:[DEFAULTS objectForKey:@"checkUpdate"]];
    NSTimeInterval time = [currentDate timeIntervalSinceDate:lastDate];
    if (time > 3600 * 24) { // 每隔1天检测一次更新
        NSLog(@"Check For Update");
        [self checkUpdate:^(BOOL success) {
            if (!success) {
                // 如果7天没成功检查更新，提示失败
                if (time > 7 * 3600 * 24) {
                    [[AppDelegate getTopViewController] showAlertWithTitle:@"警告" message:@"向App Store检查更新失败，请检查您的网络连接！"];
                    [DEFAULTS setObject:[formatter stringFromDate:currentDate] forKey:@"checkUpdate"];
                }
            } else {
                [DEFAULTS setObject:[formatter stringFromDate:currentDate] forKey:@"checkUpdate"];
            }
        }];
    } else {
        NSLog(@"Needn't Check Update");
    }
}

- (void)checkUpdate:(void (^)(BOOL success))callback {
    dispatch_global_default_async((^{
        NSString *currentVersion = APP_VERSION;
//        currentVersion = @"3.9.5";
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://itunes.apple.com/lookup?id=826386033"] options:NSDataReadingMappedIfSafe error:&error];
        if (error || !data) {
            NSLog(@"Check Update Failed: %@", error);
            callback(NO);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error || !json) {
            NSLog(@"JSON Parse Error: %@", error);
            callback(NO);
            return;
        }
        
        NSArray *infoArray = json[@"results"];
        if (infoArray.count == 0) {
            NSLog(@"No app info returned from App Store.");
            callback(NO);
            return;
        }
        
        callback(YES);
        NSDictionary *releaseInfo = infoArray[0];
        NSString *latestVersion = releaseInfo[@"version"];
//        latestVersion = @"3.9.6";
        NSLog(@"App Store latest version: %@", latestVersion);
        if ([currentVersion compare:latestVersion options:NSNumericSearch] == NSOrderedAscending) {
            NSString *newVerURL = releaseInfo[@"trackViewUrl"];
            [[AppDelegate getTopViewController] showAlertWithTitle:[NSString stringWithFormat:@"发现新版本%@", latestVersion] message:releaseInfo[@"releaseNotes"] confirmTitle:@"更新" confirmAction:^(UIAlertAction *action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:newVerURL] options:@{} completionHandler:nil];
            } cancelTitle:@"暂不"];
        }
    }));
}

@end
