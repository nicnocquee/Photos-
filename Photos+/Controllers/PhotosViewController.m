//
//  PhotosViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosViewController.h"

#import "PhotoCell.h"

#import "PhotosViewControllerCollectionViewDelegate.h"

#import "PhotoAsset.h"

@interface PhotosViewController () <UICollectionViewDataSource>

@property (nonatomic, strong) PhotosViewControllerCollectionViewDelegate *collectionViewDelegate;

@end

@implementation PhotosViewController

- (void)awakeFromNib {
    self.navigationController.tabBarItem.title = [self tabBarItemTitle];
    self.navigationController.tabBarItem.image = [self tabBarItemImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChangeNotification:) name:ALAssetsLibraryChangedNotification object:nil];
    
    self.title = [self title];
    
    self.collectionViewDelegate = [[PhotosViewControllerCollectionViewDelegate alloc] initWithCollectionView:self.collectionView];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoCell class])];
        
    self.assets = [[NSMutableOrderedSet alloc] init];
    
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

- (void)loadPhotos {
    [self showLoadingView:YES];
    
    [self loadCachedWithCompletion:^{
        [self loadPhotosLibrary];
    }];
}

- (void)loadPhotosLibrary {
    __weak typeof (self) selfie = self;
    void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
        {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                if ([selfie cachedQueryString]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [selfie setTitleWithAnalyzingIndex:index total:group.numberOfAssets];
                    });
                }
                
                if (result) {
                    PhotoAsset *photoAsset = [selfie photoAssetForALAsset:result index:index];
                    if (photoAsset) {
                        if ([selfie cachedQueryString]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSInteger count = selfie.assets.count;
                                @synchronized(self) {
                                    [selfie.assets addObject:photoAsset];
                                }
                                if (selfie.assets.count - 1 == count) {
                                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(index)) ascending:NO];
                                    [selfie.assets sortUsingDescriptors:@[sort]];
                                    [selfie.collectionView reloadData];
                                }
                            });
                        } else {
                            @synchronized(selfie) {
                                [selfie.assets addObject:photoAsset];
                            }
                        }
                    }
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                selfie.navigationItem.titleView = nil;
                selfie.navigationItem.title = [selfie title];
                [selfie didFinishFetchingAssets];
                [selfie showLoadingView:NO];
                if (![selfie cachedQueryString]) {
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(index)) ascending:NO];
                    [selfie.assets sortUsingDescriptors:@[sort]];
                }
                [selfie.collectionView reloadData];
            });
            *stop = YES;
        }
    };
    
    dispatch_async([self libraryEnumerationQueue], ^{
        [ASSETS_LIBRARY enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:enumerate
                                    failureBlock:^(NSError *error) {
                                        NSLog(@"Error enumerate: %@", error);
                                    }];
    });
}

- (dispatch_queue_t)libraryEnumerationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.getdelightfulapp.all", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (void)setTitleWithAnalyzingIndex:(NSInteger)index total:(NSInteger)total {
    if (index == total-1) {
        [self.navigationItem setTitleView:nil];
        self.navigationItem.title = [self title];
    } else {
        float progress = ((float)(total-index)/(float)total)*100;
        NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Analyzing photos %.f%%", nil), progress];
        NSString *text = [NSString stringWithFormat:@"%@\n%@", [self title], progressString];
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[text rangeOfString:[self title]]];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[text rangeOfString:progressString]];
        
        UILabel *label = [[UILabel alloc] init];
        [label setAttributedText:attr];
        [label setNumberOfLines:2];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label sizeToFit];
        [self.navigationItem setTitleView:label];
    }
}

- (void)showLoadingView:(BOOL)show {
    if (show) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:loadingItem];
        [indicator startAnimating];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset index:(NSInteger)index{
    PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
    [photoAsset setIndex:index];
    [photoAsset setALAsset:asset];
    return photoAsset;
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    return YES;
}

- (NSString *)tabBarItemTitle {
    return self.title;
}

- (UIImage *)tabBarItemImage {
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"All Photos", nil);
}

- (void)didFinishFetchingAssets {
    
}

- (NSString *)cachedQueryString {
    return nil;
}

- (void)loadCachedWithCompletion:(void (^)())completion {
    if ([self cachedQueryString]) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
        if (cached.count > 0) {
            __weak typeof (self) selfie = self;
            __block int count = (int)cached.count;
            NSLog(@"%@ assets count before = %d", NSStringFromClass(self.class), count);
            for (PhotoAsset *asset in cached) {
                [asset loadAssetWithCompletion:^(id completedAsset) {
                    count--;
                    if (completedAsset) {
                        [selfie.assets addObject:asset];
                    } else {
                        NSLog(@"Remove assets");
                        [selfie.assets removeObject:asset];
                        [realm beginWriteTransaction];
                        [realm deleteObject:asset];
                        [realm commitWriteTransaction];
                    }
                    if (count == 0) {
                        [selfie.collectionView reloadData];
                        if (completion) {
                            completion();
                        }
                    }
                }];
            }
        } else{
            if (completion) {
                completion();
            }
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (PhotoAsset *photoAsset in self.assets) {
                [photoAsset loadAssetWithCompletion:^(id completedAsset) {
                    if (!completedAsset) {
                        [self.assets removeObject:photoAsset];
                    }
                }];
            }
            if (completion) {
                completion();
            }
        });
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PhotoCell class]) forIndexPath:indexPath];
    [cell setPhotoAsset:[self.assets objectAtIndex:indexPath.item]];
    return cell;
}

#pragma mark - Notifications

- (void)assetsLibraryDidChangeNotification:(NSNotification *)notification {
    [self loadPhotosLibrary];
}

@end
