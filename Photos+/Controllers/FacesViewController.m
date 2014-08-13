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

- (CIDetector *)faceDetector {
    if (!_faceDetector) {
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    }
    return _faceDetector;
}

- (NSString *)title {
    return NSLocalizedString(@"Faces", nil);
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    BOOL shouldCheckForFace = YES;
    BOOL shouldIncludeAsset = NO;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if ([photo.urlString isEqualToString:asset.defaultRepresentation.url.absoluteString] && photo.checkedForFaces) {
                shouldCheckForFace = NO;
                shouldIncludeAsset = photo.isScreenshot;
            } else {
                [realm beginWriteTransaction];
                [photo setCheckedForFaces:YES];
                [realm commitWriteTransaction];
            }
        }
    } else {
        PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
        [photoAsset setALAsset:asset];
        [photoAsset setCheckedForFaces:YES];
        [realm beginWriteTransaction];
        [realm addObject:photoAsset];
        [realm commitWriteTransaction];
    }
    
    if (!shouldCheckForFace) {
        return shouldIncludeAsset;
    }
    
    CIImage *image = [[CIImage alloc] initWithCGImage:[asset thumbnail]];
    NSArray *features = [self.faceDetector featuresInImage:image];
    if (features.count > 0) {
        return YES;
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
    [photoAsset setCheckedForFaces:YES];
    [photoAsset setHasFaces:YES];
    [realm commitWriteTransaction];
    return photoAsset;
}

- (NSString *)cachedQueryString {
    return @"hasFaces = true && deleted = false";
}

- (dispatch_queue_t)libraryEnumerationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.getdelightfulapp.faces", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@end
