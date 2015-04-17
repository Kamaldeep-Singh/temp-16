//
//  CLCoreData.m
//  Crashlytics
//
//  Created by KS on 2/1/15.
//  Copyright (c) 2015 Twitter. All rights reserved.
//

#import "CLCoreData.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "Image.h"
#import "CLDefs.h"

@interface CLCoreData ()
@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSManagedObjectContext *mainContext;
@end

@implementation CLCoreData

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSError *err = nil;
        
        //  Find model
        NSURL *url = [[NSBundle mainBundle]
              URLForResource:@"Crashlytic.framework/Resources/CrashlyticsModel"
              withExtension:@"momd"];
        
        NSAssert(url, @"Unable to find data model");
        
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc]
                                       initWithContentsOfURL:url];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        url = [[[[NSFileManager defaultManager]
                 URLsForDirectory:NSDocumentDirectory
                 inDomains:NSUserDomainMask] lastObject]
               URLByAppendingPathComponent:@"CrashlyticsModel.sqlite"];
        [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                    URL:url options:nil error:&err];
        
        //  Private context
        NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc]
               initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        ctx.persistentStoreCoordinator = psc;
        self.context = ctx;

        //  Main context
        ctx = [[NSManagedObjectContext alloc]
               initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainContext = ctx;
        
        [self registerObservers];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) registerObservers
{
    //  Register for updating state across contexts
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSavePrivateContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.context];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSaveMainContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.mainContext];
}

-(void) didSavePrivateContext:(NSNotification *)notf
{
    @synchronized(self) {
        [self.context performBlock:^{
            [self.context mergeChangesFromContextDidSaveNotification:notf];
        }];
    }
}

-(void) didSaveMainContext:(NSNotification *)notf
{
    @synchronized(self) {
        [self.mainContext performBlock:^{
            [self.mainContext mergeChangesFromContextDidSaveNotification:notf];
        }];
    }
}

-(void) sync
{
    //  a thread blocking call
    [_context performBlockAndWait:^{
        NSError *err = nil;
        if ([_context hasChanges] && ![_context save:&err]) {
            [_context rollback];
        }
    }];
}

@end

@implementation CLCoreData (ImageAPI)

-(void) addImageWithbaseAddress:(NSNumber *)address
                           name:(NSString *)name
                syncImmidiately:(BOOL)sync
{
    [_context performBlock:^{
        Image *image = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Image"
                        inManagedObjectContext:_context];
        image.baseAddress = address;
        image.imageName = name;
        image.created = [NSDate date];
        if (sync) [self sync];
    }];
}

-(void) removeImageWithName:(NSString *)name syncImmidiately:(BOOL)sync

{
    [_context performBlock:^{
        NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
        [req setPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
        NSError *err = nil;
        NSArray *arr = [_context executeFetchRequest:req error:&err];
        for (Image *img in arr) {
            [_context deleteObject:img];
        }
        if (sync) [self sync];
    }];
}


-(void) fetchAllWithBlock:(void (^)(NSArray *, NSError *))block
{
    [_context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest
                                   fetchRequestWithEntityName:@"Image"];
        NSError *err = nil;
        NSArray *images = [_context executeFetchRequest:request error:&err];
        block(images, err);
    }];
}

-(void) removeAllImagesImmidiately:(BOOL)sync
                    withCompletion:(void (^)(void))completion;
{
    [_context performBlock:^{
        NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
        NSError *err = nil;
        NSArray *arr = [_context executeFetchRequest:req error:&err];
        for (Image *img in arr) {
            [_context deleteObject:img];
        }
        if(sync) [self sync];
        completion();
    }];
}


@end
