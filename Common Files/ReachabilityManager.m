//
//  ReachabilityManager.m
//  CAPUBBS
//
//  Created by Zhikang Fan on 5/26/25.
//  Copyright © 2025 熊典. All rights reserved.
//

#import "ReachabilityManager.h"
@import Network;

@interface ReachabilityManager ()
@property (nonatomic, assign) NetworkType currentNetworkTypeInternal;
@property (nonatomic, strong) nw_path_monitor_t monitor;
@end

@implementation ReachabilityManager

+ (instancetype)sharedManager {
    static ReachabilityManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ReachabilityManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentNetworkTypeInternal = NetworkTypeUnknown;
    }
    return self;
}

- (void)startMonitoring {
    if (self.monitor) {
        [self stopMonitoring];
    }
    self.monitor = nw_path_monitor_create();
    
    nw_path_monitor_set_queue(self.monitor, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0));
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) == nw_path_status_satisfied) {
            if (nw_path_uses_interface_type(path, nw_interface_type_wifi)) {
                self->_currentNetworkTypeInternal = NetworkTypeWiFi;
            } else if (nw_path_uses_interface_type(path, nw_interface_type_cellular)) {
                self->_currentNetworkTypeInternal = NetworkTypeCellular;
            } else {
                self->_currentNetworkTypeInternal = NetworkTypeUnknown;
            }
        } else {
            self->_currentNetworkTypeInternal = NetworkTypeNone;
        }
        NSLog(@"Current connectivity: %lu", (unsigned long)self->_currentNetworkTypeInternal);
    });
    nw_path_monitor_start(self.monitor);
}

- (void)stopMonitoring {
    if (self.monitor) {
        nw_path_monitor_cancel(self.monitor);
        self.monitor = nil;
    }
}

- (NetworkType)currentNetworkType {
    return self.currentNetworkTypeInternal;
}

@end
