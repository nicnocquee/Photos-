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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosLibraryDidChangeNotification:) name:screenshotsUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Screenshots", nil);
}

- (NSString *)cachedQueryString {
    return @"screenshot = 1";
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForScreenshots));
}

@end
