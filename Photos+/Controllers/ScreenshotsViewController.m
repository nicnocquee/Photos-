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

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    BOOL shouldCheckForScreenshot = YES;
    BOOL shouldIncludeAsset = NO;
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", asset.defaultRepresentation.url.absoluteString];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if (photo.checkedForScreenshot) {
                shouldCheckForScreenshot = NO;
                shouldIncludeAsset = photo.isScreenshot;
                break;
            } else {
                [realm beginWriteTransaction];
                [photo setCheckedForScreenshot:YES];
                [realm commitWriteTransaction];
            }
        }
    } else {
        PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
        [photoAsset setALAsset:asset];
        [photoAsset setCheckedForScreenshot:YES];
        [realm beginWriteTransaction];
        [realm addObject:photoAsset];
        [realm commitWriteTransaction];
    }
    
    if (!shouldCheckForScreenshot) {
        return shouldIncludeAsset;
    }
    
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    CGSize size = [assetRepresentation dimensions];
    CGSize windowSize = [[UIApplication sharedApplication] keyWindow].frame.size;
    if (CGSizeEqualToSize(size, windowSize)) {
        return YES;
    }
    
    for (NSValue *dimension in [UIDevice deviceDimensions]) {
        if (CGSizeEqualToSize(size, [dimension CGSizeValue])) {
            return YES;
        }
    }
    
    return NO;
}

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset {
    if (![self shouldIncludeAsset:asset]) {
        return nil;
    }
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", asset.defaultRepresentation.url.absoluteString];
    PhotoAsset *photoAsset = [cached firstObject];
    [realm beginWriteTransaction];
    [photoAsset setALAsset:asset];
    [photoAsset setCheckedForScreenshot:YES];
    [photoAsset setScreenshot:YES];
    [realm commitWriteTransaction];
    return photoAsset;
}

- (NSString *)title {
    return NSLocalizedString(@"Screenshots", nil);
}

- (NSString *)cachedQueryString {
    return @"screenshot = true && deleted = false";
}

- (dispatch_queue_t)libraryEnumerationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.getdelightfulapp.screenshots", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@end
