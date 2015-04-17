//
//  CLCoreData.h
//  Crashlytics
//
//  Created by KS on 2/1/15.
//

#import <Foundation/Foundation.h>

@interface CLCoreData : NSObject
-(void) sync;
@end

@interface CLCoreData (ImageAPI)

-(void) addImageWithbaseAddress:(NSNumber *)address name:(NSString *)name
                syncImmidiately:(BOOL)sync;

-(void) removeImageWithName:(NSString *)name syncImmidiately:(BOOL)sync;

-(void) removeAllImagesImmidiately:(BOOL)sync
                    withCompletion:(void (^)(void))completion;

-(void) fetchAllWithBlock:(void (^)(NSArray *images, NSError *err))block;

@end