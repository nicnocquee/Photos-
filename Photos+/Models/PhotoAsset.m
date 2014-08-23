//
//  PhotoAsset.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotoAsset.h"

#import "PhotosLibrary.h"

@interface PhotoAsset ()

@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, strong) ALAssetRepresentation *assetRepresentation;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSDictionary *metadata;

@property (nonatomic, strong) ALAsset *rawAsset;

@end

@implementation PhotoAsset

- (void)setALAsset:(ALAsset *)asset {
    self.rawAsset = asset;
    self.assetRepresentation = [asset defaultRepresentation];
    self.url = [self.assetRepresentation url];
    self.dateCreated = [asset valueForProperty:ALAssetPropertyDate];
}

- (UIImage *)thumbnailImage {
    if (!_thumbnailImage) {
        _thumbnailImage = [UIImage imageWithCGImage:[self.rawAsset thumbnail]];
    }
    return _thumbnailImage;
}

- (NSDictionary *)metadata {
    if (!_metadata) {
        _metadata = [self.assetRepresentation metadata];
    }
    return _metadata;
}

+ (NSArray *)ignoredProperties {
    return @[NSStringFromSelector(@selector(thumbnailImage)),
             NSStringFromSelector(@selector(assetRepresentation)),
             NSStringFromSelector(@selector(url)),
             NSStringFromSelector(@selector(metadata)),
             NSStringFromSelector(@selector(rawAsset))];
}

- (void)loadAssetWithCompletion:(void (^)(id asset))completion {
    if (self.url) {
        if (self.url) {
            [[[PhotosLibrary sharedLibrary] library] assetForURL:self.url resultBlock:^(ALAsset *asset) {
                if (asset) {
                    self.rawAsset = asset;
                    self.thumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
                    self.assetRepresentation = [asset defaultRepresentation];
                    if (completion) {
                        completion(asset);
                    }
                } else {
                    if (completion) {
                        completion(nil);
                    }
                }
            } failureBlock:^(NSError *error) {
                
            }];
        }
    }
}

- (BOOL)isEqualToPhotoAsset:(PhotoAsset *)asset {
    if (![asset isKindOfClass:[PhotoAsset class]]) {
        return NO;
    }
    
    if (![asset.url isEqual:self.url]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToPhotoAsset:object];
}

- (NSUInteger)hash {
    return self.url.absoluteString.hash;
}

@end
