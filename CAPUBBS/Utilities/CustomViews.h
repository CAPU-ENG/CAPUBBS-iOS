//
//  CustomViews.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 9/26/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LiquidGlass)

- (void)applyLiquidGlassWithCorner:(UICornerConfiguration *)corner
                             clear:(BOOL)clear
                       interactive:(BOOL)interactive API_AVAILABLE(ios(26.0));

@end

@interface UIScrollView (LiquidGlass)

// 声明一个自定义属性，并标记为 UI_APPEARANCE_SELECTOR
@property (nonatomic, assign) BOOL useSoftEdgeEffect UI_APPEARANCE_SELECTOR API_AVAILABLE(ios(26.0));

@end
