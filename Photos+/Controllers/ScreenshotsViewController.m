//
//  ScreenshotsViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "ScreenshotsViewController.h"

#import "UIDevice+Additionals.h"

@interface ScreenshotsViewController ()

@end

@implementation ScreenshotsViewController

- (void)setupNotifications {
    NSLog(@"setup notification in sccreenhsots vc");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenshotsDidChangeNotification:) name:screenshotsUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Screenshots", nil);
}

- (NSString *)cachedQueryString {
    return @"screenshot = true && deleted = false";
}

- (void)screenshotsDidChangeNotification:(NSNotification *)notification {
    NSLog(@"screenshots did change");
    [self loadPhotos];
}

@end
