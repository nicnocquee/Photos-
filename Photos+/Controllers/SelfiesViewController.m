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

- (BOOL)assetHasBeenChecked:(ALAsset *)asset isSelfie:(BOOL*)isSelfie{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if ([photo.urlString isEqualToString:asset.defaultRepresentation.url.absoluteString] && photo.checkedForSelfies) {
                *isSelfie = photo.isSelfies;
                return YES;
            }
        }
    }
    return NO;
}

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset {
    BOOL isSelfie;
    if ([self assetHasBeenChecked:asset isSelfie:&isSelfie]) {
        if (!isSelfie) {
            return nil;
        }
    }
    if (![self shouldIncludeAsset:asset]) {
        return nil;
    }
    PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
    [photoAsset setALAsset:asset];
    [photoAsset setCheckedForSelfies:YES];
    return photoAsset;
}

- (void)didFinishFetchingAssets {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        for (PhotoAsset *photoAsset in self.assets) {
            RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", photoAsset.urlString];
            if ([cached firstObject]) {
                PhotoAsset *asset = [cached firstObject];
                [realm beginWriteTransaction];
                [asset setSelfies:YES];
                [realm commitWriteTransaction];
            } else {
                [realm beginWriteTransaction];
                [photoAsset setSelfies:YES];
                [realm addObject:photoAsset];
                [realm commitWriteTransaction];
            }
        }
    });
}

- (NSString *)cachedQueryString {
    return @"selfies = true && deleted = false";
}

@end
