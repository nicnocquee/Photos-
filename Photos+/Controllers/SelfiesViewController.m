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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosLibraryDidChangeNotification:) name:selfiesUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Selfies", nil);
}

- (NSString *)cachedQueryString {
    return @"selfies = 1";
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForSelfies));
}

@end
