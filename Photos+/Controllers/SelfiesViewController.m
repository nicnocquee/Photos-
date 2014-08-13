//
//  SelfiesViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "SelfiesViewController.h"

#import <ImageIO/CGImageProperties.h>

@interface SelfiesViewController ()

@end

@implementation SelfiesViewController

- (NSString *)title {
    return NSLocalizedString(@"Selfies", nil);
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    BOOL shouldCheckForSelfie = YES;
    BOOL shouldIncludeAsset = NO;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", asset.defaultRepresentation.url.absoluteString];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if (photo.checkedForSelfies) {
                shouldCheckForSelfie = NO;
                shouldIncludeAsset = photo.isSelfies;
            } else {
                [realm beginWriteTransaction];
                [photo setCheckedForSelfies:YES];
                [realm commitWriteTransaction];
            }
        }
    } else {
        PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
        [photoAsset setALAsset:asset];
        [photoAsset setCheckedForSelfies:YES];
        [realm beginWriteTransaction];
        [realm addObject:photoAsset];
        [realm commitWriteTransaction];
    }
    
    if (!shouldCheckForSelfie) {
        return shouldIncludeAsset;
    }
    
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    NSDictionary *metadata = [assetRepresentation metadata];
    if (metadata) {
        NSDictionary *exif = metadata[(NSString *)kCGImagePropertyExifDictionary];
        if (exif) {
            NSString *lensModel = exif[@"LensModel"];
            if (lensModel && [lensModel rangeOfString:@"front camera"].location != NSNotFound) {
                return YES;
            }
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
    [photoAsset setSelfies:YES];
    [photoAsset setCheckedForSelfies:YES];
    [realm commitWriteTransaction];
    return photoAsset;
}

- (NSString *)cachedQueryString {
    return @"selfies = true && deleted = false";
}

- (dispatch_queue_t)libraryEnumerationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.getdelightfulapp.selfies", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@end
