//
//  ZelNSDateFormatter+Extras.h
//
//  Created by Dean Smith on 16/03/2011.
//

#import <Foundation/NSDateFormatter.h>

@interface NSDateFormatter (Extras)
+ (NSString *)dateDifferenceStringFromString:(NSString *)dateString
                                  withFormat:(NSString *)dateFormat;



+(NSString*)dateDifferenceStringFromDate:(NSDate*)date;
							  
@end


