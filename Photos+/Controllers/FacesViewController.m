//
//  FacesViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "FacesViewController.h"

@interface FacesViewController ()

@property (nonatomic, strong) CIDetector *faceDetector;

@end

@implementation FacesViewController

- (void)setupNotifications {
    NSLog(@"setup notification in faces vc");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facesDidChangeNotification:) name:facesUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Faces", nil);
}

- (NSString *)cachedQueryString {
    return @"hasFaces = 1";
}

- (void)facesDidChangeNotification:(NSNotification *)notification {
    NSLog(@"faces did change");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[insertedAssetKey]) {
        PhotoAsset *asset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", userInfo[insertedAssetKey]];
        [self insertPhotoAsset:asset];
    }
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForFaces));
}

@end
