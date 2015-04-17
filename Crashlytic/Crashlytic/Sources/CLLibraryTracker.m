//
//  CLLibraryTracker.m
//  Crashlytics
//
//  Created by KS on 1/29/15.
//

#import "CLLibraryTracker.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import "CLCoreData.h"
#import "CLDefs.h"
#import <dlfcn.h>
#import "Image.h"

@interface CLLibraryTracker ()
@property (nonatomic) NSMutableDictionary *currentImages;
@property (nonatomic) CLCoreData *coreData;
@end

@implementation CLLibraryTracker
static CLLibraryTracker *_logger = nil;

-(instancetype) init
{
    self = [super init];
    if (self) {
        self.currentImages = [NSMutableDictionary dictionary];
        self.coreData = [[CLCoreData alloc] init];
        
        //  register for fetching/syncing data when in foreground/background
        [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationDidBecomeActive)
                                 name:UIApplicationDidBecomeActiveNotification
                               object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationDidEnterBackground)
                                 name:UIApplicationDidEnterBackgroundNotification
                               object:nil];
    }
    return self;
}

+ sharedTracker
{
    static dispatch_once_t onceToken;
    if (!_logger) {
        dispatch_once(&onceToken, ^{
            _logger = [[self alloc] init];

            //  register in static context
            _dyld_register_func_for_add_image(add_image);
            _dyld_register_func_for_remove_image(remove_image);
        });
    }
    return _logger;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIApplication Callbacks

-(void) applicationDidBecomeActive
{
    [_coreData fetchAllWithBlock:^(NSArray *images, NSError *err){

        //  Report last known images
        NSLog(@"Previously loaded images (%ld)...",
              (unsigned long)images.count);
        NSLog(@"BaseAddr   | Image Name");
        NSLog(@"-----------------------");
        for (Image *img in images) {
            
            NSLog(@"%ld \t| %@", [img.baseAddress longValue],
                  [[img.imageName componentsSeparatedByString:@"/"] lastObject]);
        }
        
        //  Clear out previously known images for simplicity
        [_coreData removeAllImagesImmidiately:YES withCompletion:^{
        }];
    }];
}

-(void) applicationDidEnterBackground
{
    __block UIBackgroundTaskIdentifier bgId = UIBackgroundTaskInvalid;
    
    bgId = [[UIApplication sharedApplication]
            beginBackgroundTaskWithExpirationHandler:^{
                if (bgId != UIBackgroundTaskInvalid) {
                    [[UIApplication sharedApplication] endBackgroundTask:bgId];
                    bgId = UIBackgroundTaskInvalid;
                }
            }];
    
    //  sync images in the context before going to background
    for (NSNumber *baddr in self.currentImages) {
        [_coreData addImageWithbaseAddress:baddr
                                      name:self.currentImages[baddr]
                                  syncImmidiately:NO];
    }
    [_coreData sync];
}

#pragma mark - DYLD Callbacks

void add_image(const struct mach_header *header, intptr_t ptr)
{
    Dl_info info;
    if (dladdr(header, &info)) {
        NSNumber *baddr = [NSNumber numberWithLong:(intptr_t) info.dli_fbase];
        NSString *name = [NSString stringWithCString:info.dli_fname
                                            encoding:NSUTF8StringEncoding];
        _logger.currentImages[baddr] = name;
    }
}

void remove_image(const struct mach_header *header, intptr_t ptr)
{
    Dl_info info;
    if (dladdr(header, &info)) {
        NSNumber *baddr = [NSNumber numberWithLong:(intptr_t) info.dli_fbase];
        [_logger.currentImages removeObjectForKey:baddr];
    }
}

@end
