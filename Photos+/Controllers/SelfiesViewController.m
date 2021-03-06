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

- (void)setupNotifications {
    NSLog(@"setup notification in selfies vc");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfiesDidChangeNotification:) name:selfiesUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Selfies", nil);
}

- (NSString *)cachedQueryString {
    return @"selfies = true && deleted = false";
}

- (void)selfiesDidChangeNotification:(NSNotification *)notification {
    NSLog(@"selfies did change");
    [self loadPhotos];
}

@end
