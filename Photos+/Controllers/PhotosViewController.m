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

static void * photosToCheckKVO = &photosToCheckKVO;

@interface PhotosViewController () <UICollectionViewDataSource>

@property (nonatomic, strong) PhotosViewControllerCollectionViewDelegate *collectionViewDelegate;

@end

@implementation PhotosViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupNotifications];
        [self initObservers];
    }
    return self;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosLibraryDidChangeNotification:) name:photosUpdatedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:photosUpdatedNotification object:nil];
}

- (void)awakeFromNib {
    self.navigationController.tabBarItem.title = [self tabBarItemTitle];
    self.navigationController.tabBarItem.image = [self tabBarItemImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.title = [self title];
    
    self.collectionViewDelegate = [[PhotosViewControllerCollectionViewDelegate alloc] initWithCollectionView:self.collectionView];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoCell class])];
        
    self.assets = [[NSMutableOrderedSet alloc] init];
    
    [self loadPhotos];
}

- (void)initObservers {
    [[PhotosLibrary sharedLibrary] addObserver:self forKeyPath:[self photosLibraryPropertyToObserve] options:NSKeyValueObservingOptionNew context:photosToCheckKVO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    if ([self cachedQueryString]) {
        NSArray *photos = [PhotoAsset instancesWhere:[NSString stringWithFormat:@"%@ order by dateCreated desc", [self cachedQueryString]]];
        [self.assets addObjectsFromArray:photos];
        [self setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count]];
    } else {
        [self.assets removeAllObjects];
        NSArray *photos = [PhotoAsset instancesOrderedBy:@"dateCreated DESC"];
        [self.assets addObjectsFromArray:photos];
        NSLog(@"number of assets: %d", (int)self.assets.count);
    }
    [self setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count]];
    
    [self.collectionView reloadData];
    
    if (self.assets.count > 0) {
        for (PhotoAsset *photoAsset in self.assets) {
            [[[PhotosLibrary sharedLibrary] library] assetForURL:photoAsset.url resultBlock:^(ALAsset *asset) {
                if (!asset) {
                    [[PhotosLibrary sharedLibrary] removeAssetWithURL:photoAsset.url];
                }
            } failureBlock:^(NSError *error) {
                
            }];
        }
    }
    
}

- (NSInteger)insertPhotoAsset:(PhotoAsset *)photoAsset {
    NSInteger indexToInsert = 0;
    NSInteger index = [self.assets indexOfObject:photoAsset];
    NSInteger count = self.assets.count;
    if (index != NSNotFound) {
        //NSLog(@"inserted asset exists, ignore");
        indexToInsert = NSNotFound;
    } else {
        //NSLog(@"to insert asset index %d", (int)photoAsset.assetIndex);
        NSArray *assets = [self.assets.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"assetIndex > %d", (int)photoAsset.assetIndex]];
        if (assets.count > 0) {
            assets = [assets sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assetIndex" ascending:NO]]];
            PhotoAsset *nextAsset = [assets lastObject];
            NSAssert(nextAsset, @"Next asset should not be nil");   
            //NSLog(@"last asset index %d", (int)nextAsset.assetIndex);
            NSInteger indexInAssets = [self.assets indexOfObject:nextAsset];
            NSInteger insertIndex = MIN(indexInAssets+1, self.assets.count);
            [self.assets insertObject:photoAsset atIndex:insertIndex];
            indexToInsert = insertIndex;
        } else {
            [self.assets insertObject:photoAsset atIndex:0];
        }
    }
    
    if (self.assets.count > count) {
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:indexToInsert inSection:0]]];
    }
    return indexToInsert;
}

- (void)removePhotoAsset:(PhotoAsset *)photoAsset {
    NSLog(@"[%@] Removing asset url: %@", NSStringFromClass(self.class), photoAsset.url);
}

- (NSString *)cachedQueryString {
    return nil;
}

- (void)setTitleForProgress:(NSNumber *)prog {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:NEW_DATABASE_DEFAULT_KEY]) {
        [self.navigationItem setTitleView:nil];
        self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count];
    } else {
        float progress = [prog floatValue];
        if (progress >= 100) {
            [self.navigationItem setTitleView:nil];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count];
        } else {
            NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Analyzing photos %.f%%", nil), progress];
            NSString *title = [self title];
            if (self.assets.count > 0) {
                title = [title stringByAppendingString:[NSString stringWithFormat:@" (%d)", (int)self.assets.count]];
            }
            NSString *text = [NSString stringWithFormat:@"%@\n%@", title, progressString];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
            [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[text rangeOfString:title]];
            [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[text rangeOfString:progressString]];
            
            UILabel *label = [[UILabel alloc] init];
            [label setNumberOfLines:2];
            label.tag = 1200;
            [label setTextAlignment:NSTextAlignmentCenter];
            [self.navigationItem setTitleView:label];
            [label setAttributedText:attr];
            [label sizeToFit];
        }
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

- (NSString *)tabBarItemTitle {
    return self.title;
}

- (UIImage *)tabBarItemImage {
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"All Photos", nil);
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForAllPhotos));
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

- (void)photosLibraryDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[insertedAssetKey]) {
        PhotoAsset *asset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", userInfo[insertedAssetKey]];
        [self insertPhotoAsset:asset];
    }
    if (userInfo[deletedAssetKey]) {
        NSURL *url = userInfo[deletedAssetKey];
        NSInteger index = [self.assets indexOfObjectPassingTest:^BOOL(PhotoAsset *obj, NSUInteger idx, BOOL *stop) {
            if (obj.url == url) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if (index != NSNotFound) {
            [self.assets removeObjectAtIndex:index];
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        }
    }
}

- (void)willEnterForeground:(NSNotification *)notification {
    NSLog(@"%@ did become active", NSStringFromClass(self.class));
    
    [[PhotosLibrary sharedLibrary] checkAssetsExist];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == photosToCheckKVO) {
        NSInteger index = [change[@"new"] integerValue];
        NSInteger total = [[PhotosLibrary sharedLibrary] numberOfPhotosToCheck];
        if (total > 0 && index >= 0) {
            float progress = ((float)(total-index)/(float)total)*100;
            [self performSelectorOnMainThread:@selector(setTitleForProgress:) withObject:@(progress) waitUntilDone:YES];
        }
    }
}

@end
