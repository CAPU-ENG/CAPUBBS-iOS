//
//  ReachabilityManager.h
//  CAPUBBS
//
//  Created by Zhikang Fan on 5/26/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NetworkType) {
    NetworkTypeUnknown,
    NetworkTypeWiFi,
    NetworkTypeCellular,
    NetworkTypeNone
};

NS_ASSUME_NONNULL_BEGIN

@interface ReachabilityManager : NSObject

@property (nonatomic, readonly) NetworkType currentNetworkType;

+ (instancetype)sharedManager;

- (void)startMonitoring;
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
