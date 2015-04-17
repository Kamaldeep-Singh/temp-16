//
//  CLLibraryTracker.h
//  Crashlytics
//
//  Created by KS on 1/29/15.
//  Copyright (c) 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLLibraryTracker : NSObject

/**
 *  Creates and returns a singleton instance
 *
 *  @return an singleton instance of CLLibraryTracker
 */
+ sharedTracker;

@end
