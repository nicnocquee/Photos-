//
//  AppDelegate.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "AppDelegate.h"

#import "AppDelegate+Services.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self runCrashlyticsIfAvailable];
    
    [self loadDatabase];
    
    [[PhotosLibrary sharedLibrary] loadPhotos];
    NSLog(@"app delegate");
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)loadDatabase {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dbPath = [documentsPath stringByAppendingPathComponent:@"photosplus.sqlite3"];
    
    [FCModel openDatabaseAtPath:dbPath withSchemaBuilder:^(FMDatabase *db, int *schemaVersion) {
        [db beginTransaction];
        
        void (^failedAt)(int statement) = ^(int statement){
            int lastErrorCode = db.lastErrorCode;
            NSString *lastErrorMessage = db.lastErrorMessage;
            [db rollback];
            NSAssert3(0, @"Migration statement %d failed, code %d: %@", statement, lastErrorCode, lastErrorMessage);
        };
        
        if (*schemaVersion < 1) {
            if (![db executeUpdate:
                  @"CREATE TABLE PhotoAsset ("
                  @" id INTEGER PRIMARY KEY,"
                  @" url TEXT NOT NULL DEFAULT '',"
                  @" screenshot BOOL NOT NULL default false,"
                  @" selfies BOOL NOT NULL default false,"
                  @" hasFaces BOOL NOT NULL default false,"
                  @" checkedForSelfies BOOL NOT NULL default false,"
                  @" checkedForScreenshot BOOL NOT NULL default false,"
                  @" checkedForFaces BOOL NOT NULL default false,"
                  @" assetIndex INTEGER NOT NULL default 0,"
                  @" location TEXT,"
                  @" cameraType TEXT,"
                  @" dateTaken REAL,"
                  @" metadata BLOB,"
                  @" dateCreated REAL"
                  @")"
                  ]) {
                failedAt(1);
            }
            
            if (![db executeUpdate:@"CREATE INDEX IF NOT EXISTS url on PhotoAsset (url)"]) {
                failedAt(1);
            }
            
            *schemaVersion = 1;
        }
        
        [db commit];
    }];
}

@end
