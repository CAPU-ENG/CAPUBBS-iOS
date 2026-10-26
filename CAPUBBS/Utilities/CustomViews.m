//
//  CustomViews.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 9/26/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "CustomViews.h"

@implementation UIView (LiquidGlass)

- (void)applyLiquidGlassWithCorner:(UICornerConfiguration *)corner
                             clear:(BOOL)clear
                       interactive:(BOOL)interactive {
    // Remove any existing UIVisualEffectView
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIVisualEffectView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    // Remove existing background color
    self.backgroundColor = [UIColor clearColor];
    
    UIGlassEffect *effect = [UIGlassEffect effectWithStyle:clear ? UIGlassEffectStyleClear : UIGlassEffectStyleRegular];
    effect.interactive = interactive;
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = self.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.userInteractionEnabled = interactive;
    effectView.cornerConfiguration = corner;

    [self insertSubview:effectView atIndex:0];
}

@end

@implementation UIScrollView (LiquidGlass)

// 定义一个静态地址作为关联对象的 Key
static const void *kUseSoftEdgeEffectKey = &kUseSoftEdgeEffectKey;

- (void)setUseSoftEdgeEffect:(BOOL)useSoft {
    // 1. 存储该状态 (将 BOOL 包装为 NSNumber)
    objc_setAssociatedObject(self, kUseSoftEdgeEffectKey, @(useSoft), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 2. 执行 UI 外观修改
    UIScrollEdgeEffectStyle *style = useSoft ? [UIScrollEdgeEffectStyle softStyle] : [UIScrollEdgeEffectStyle hardStyle];
    if ([self respondsToSelector:@selector(topEdgeEffect)] && self.topEdgeEffect) {
        self.topEdgeEffect.style = style;
    }
    if ([self respondsToSelector:@selector(bottomEdgeEffect)] && self.bottomEdgeEffect) {
        self.bottomEdgeEffect.style = style;
    }
}

- (BOOL)useSoftEdgeEffect {
    // 读取存储的状态
    NSNumber *value = objc_getAssociatedObject(self, kUseSoftEdgeEffectKey);
    if (value) {
        return [value boolValue];
    }
    // 如果没有被设置过，默认返回 NO (其实iOS 26默认是YES，iOS 27以后才是NO，但在这里并不重要)
    return NO;
}

@end
