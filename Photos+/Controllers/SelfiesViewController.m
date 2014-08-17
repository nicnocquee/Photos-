//
//  SelfiesViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "SelfiesViewController.h"

@interface SelfiesViewController ()

@end

@implementation SelfiesViewController

- (void)setupNotifications {
    NSLog(@"setup notification in selfies vc");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfiesDidChangeNotification:) name:selfiesUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Selfies", nil);
}

- (NSString *)cachedQueryString {
    return @"selfies = 1";
}

- (void)selfiesDidChangeNotification:(NSNotification *)notification {
    NSLog(@"selfies did change");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[insertedAssetKey]) {
        PhotoAsset *asset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", userInfo[insertedAssetKey]];
        [self insertPhotoAsset:asset];
    }
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForSelfies));
}

@end
