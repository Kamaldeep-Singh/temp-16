//
//  Image.h
//  Crashlytics
//
//  Created by KS on 2/1/15.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 *  A model defining a single record in the sqlite DB 
 *  representing the dynamic library image loaded by dyld.
 *  Multiple images can be combined to form a comprehensive
 *  Log Report.
 *
 */
@interface Image : NSManagedObject

@property (nonatomic, retain) NSNumber * baseAddress;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSDate * created;

@end
