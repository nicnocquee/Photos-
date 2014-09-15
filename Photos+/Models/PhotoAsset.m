//
//  PhotoAsset.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotoAsset.h"

#import "PhotosLibrary.h"

#import <ImageIO/ImageIO.h>

@interface PhotoAsset ()

@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, strong) ALAssetRepresentation *assetRepresentation;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSDictionary *metadata;

@property (nonatomic, strong) NSDictionary *exifMetadata;

@property (nonatomic, strong) NSDictionary *tiffMetadata;

@property (nonatomic, strong) ALAsset *rawAsset;

@end

@implementation PhotoAsset

- (void)setALAsset:(ALAsset *)asset {
    self.rawAsset = asset;
    self.assetRepresentation = [asset defaultRepresentation];
    self.url = [asset valueForProperty:ALAssetPropertyAssetURL];
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

- (NSDictionary *)exifMetadata {
    if (!_exifMetadata) {
        _exifMetadata = self.metadata[(NSString *)kCGImagePropertyExifDictionary];
    }
    return _exifMetadata;
}

- (NSDictionary *)tiffMetadata {
    if (!_tiffMetadata) {
        _tiffMetadata = self.metadata[(NSString *)kCGImagePropertyTIFFDictionary];
    }
    return _tiffMetadata;
}

- (NSNumber *)latitude {
    NSDictionary *gpsData = self.metadata[(NSString *)kCGImagePropertyGPSDictionary];
    return gpsData[(NSString *)kCGImagePropertyGPSLatitude];
}

- (NSNumber *)longitude {
    NSDictionary *gpsData = self.metadata[(NSString *)kCGImagePropertyGPSDictionary];
    return gpsData[(NSString *)kCGImagePropertyGPSLongitude];
}

- (NSString *)latitudeLongitudeString {
    return [self clLocation]?[[self clLocation] description]:nil;
}

- (NSString *)dimensionString {
    return [NSString stringWithFormat:@"%.0fx%.0f", self.rawAsset.defaultRepresentation.dimensions.width, self.rawAsset.defaultRepresentation.dimensions.height];
}

- (NSDate *)dateTakenDate {
    NSString *dateTakenStr = self.metadata[(NSString *)kCGImagePropertyExifDictionary][(NSString *)kCGImagePropertyExifDateTimeOriginal];
    if (!dateTakenStr) {
        return nil;
    }
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    }
    NSDate *date = [dateFormatter dateFromString:dateTakenStr];
    return date;
}

- (NSDateFormatter *)readableDateFormatter {
    static NSDateFormatter *readableDateFormatter = nil;
    if (readableDateFormatter == nil) {
        readableDateFormatter = [[NSDateFormatter alloc] init];
        [readableDateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"EdMMMyyyy HH:mm" options:0 locale:[NSLocale currentLocale]]];
    }
    return readableDateFormatter;
}

- (NSString *)dateTakenString {
    NSDate *date = [self dateTakenDate];
    
    return [[self readableDateFormatter] stringFromDate:date];
}

- (NSString *)dateCreatedString {
    if (!self.dateCreated) {
        return nil;
    }
    
    return [[self readableDateFormatter] stringFromDate:self.dateCreated];
}

- (CLLocation *)clLocation {
    return [self.rawAsset valueForProperty:ALAssetPropertyLocation];
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
