//
//  PhotoAsset.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotoAsset.h"

@interface PhotoAsset ()

@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, strong) ALAssetRepresentation *assetRepresentation;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSDictionary *metadata;

@property (nonatomic, strong) NSString *urlString;

@end

@implementation PhotoAsset

- (void)setALAsset:(ALAsset *)asset {
    self.thumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
    self.assetRepresentation = [asset defaultRepresentation];
    self.url = [self.assetRepresentation url];
    self.urlString = [self.url absoluteString];
    self.metadata = [self.assetRepresentation metadata];
}

+ (NSArray *)ignoredProperties {
    return @[NSStringFromSelector(@selector(thumbnailImage)),
             NSStringFromSelector(@selector(assetRepresentation)),
             NSStringFromSelector(@selector(url)),
             NSStringFromSelector(@selector(metadata))];
}

- (void)loadAssetWithCompletion:(void (^)(id asset))completion {
    if (self.urlString) {
        self.url = [NSURL URLWithString:self.urlString];
        if (self.url) {
            [ASSETS_LIBRARY assetForURL:self.url resultBlock:^(ALAsset *asset) {
                if (asset) {
                    self.thumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
                    self.assetRepresentation = [asset defaultRepresentation];
                    self.metadata = [self.assetRepresentation metadata];
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
    
    if (![asset.urlString isEqualToString:self.urlString]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToPhotoAsset:object];
}

- (NSUInteger)hash {
    return self.urlString.hash;
}

@end
