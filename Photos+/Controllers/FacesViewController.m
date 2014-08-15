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

- (void)setupNotifications {
    NSLog(@"setup notification in faces vc");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facesDidChangeNotification:) name:facesUpdatedNotification object:nil];
}

- (NSString *)title {
    return NSLocalizedString(@"Faces", nil);
}

- (NSString *)cachedQueryString {
    return @"hasFaces = true && deleted = false";
}

- (void)facesDidChangeNotification:(NSNotification *)notification {
    NSLog(@"faces did change");
    [self loadPhotos];
}

@end
