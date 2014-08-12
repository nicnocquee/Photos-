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
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if ([photo.urlString isEqualToString:asset.defaultRepresentation.url.absoluteString] && photo.checkedForScreenshot) {
                return NO;
            }
        }
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
    PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
    [photoAsset setALAsset:asset];
    [photoAsset setCheckedForScreenshot:YES];
    return photoAsset;
}

- (NSString *)title {
    return NSLocalizedString(@"Screenshots", nil);
}

- (void)didFinishFetchingAssets {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       RLMRealm *realm = [RLMRealm defaultRealm];
        
        for (PhotoAsset *photoAsset in self.assets) {
            RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", photoAsset.urlString];
            if ([cached firstObject]) {
                PhotoAsset *asset = [cached firstObject];
                [realm beginWriteTransaction];
                [asset setScreenshot:YES];
                [realm commitWriteTransaction];
            } else {
                [realm beginWriteTransaction];
                [photoAsset setScreenshot:YES];
                [realm addObject:photoAsset];
                [realm commitWriteTransaction];
            }
        }
    });
}

- (NSString *)cachedQueryString {
    return @"screenshot = true && deleted = false";
}

@end
