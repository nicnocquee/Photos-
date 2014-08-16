//
//  AppDelegate+Services.m
//  Photos+
//
//  Created by  on 8/16/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "AppDelegate+Services.h"

#import <Crashlytics/Crashlytics.h>

@implementation AppDelegate (Services)

- (void)runCrashlyticsIfAvailable {
    [Crashlytics startWithAPIKey:@"some_api_key_here"];
}

@end
