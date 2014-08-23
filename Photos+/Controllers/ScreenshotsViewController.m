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
    return @"screenshot = 1";
}

- (void)screenshotsDidChangeNotification:(NSNotification *)notification {
    NSLog(@"screenshots did change");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[insertedAssetKey]) {
        PhotoAsset *asset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", userInfo[insertedAssetKey]];
        [self insertPhotoAsset:asset];
    }
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForScreenshots));
}

@end
