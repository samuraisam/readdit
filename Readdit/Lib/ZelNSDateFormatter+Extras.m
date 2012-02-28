//
//  ZelNSDateFormatter+Extras.m
//
//  Created by Dean Smith on 16/03/2011.
//

#import "ZelNSDateFormatter+Extras.h"

@implementation NSDateFormatter (Extras)

+ (NSString *)dateDifferenceStringFromString:(NSString *)dateString
                                  withFormat:(NSString *)dateFormat
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:dateFormat];
	NSDate *date = [dateFormatter dateFromString:dateString];
	return [NSDateFormatter dateDifferenceStringFromDate:date];
}
	
	
+(NSString*)dateDifferenceStringFromDate:(NSDate*)date {
	NSDate *now = [NSDate date];
	double time = [date timeIntervalSinceDate:now];
	time *= -1;
	if (time < 60) {
		return @"seconds ago";
	} else if (time < 3600) {
		int diff = round(time / 60);
		if (diff == 1) 
			return [NSString stringWithFormat:@"1 minute ago", diff];
		return [NSString stringWithFormat:@"%d minutes ago", diff];
	} else if (time < 86400) {
		int diff = round(time / 60 / 60);
		if (diff == 1)
			return [NSString stringWithFormat:@"1 hour ago", diff];
		return [NSString stringWithFormat:@"%d hours ago", diff];
	} else if (time < 604800) {
		int diff = round(time / 60 / 60 / 24);
		if (diff == 1) 
			return [NSString stringWithFormat:@"yesterday", diff];
		if (diff == 7) 
			return [NSString stringWithFormat:@"last week", diff];
		return[NSString stringWithFormat:@"%d days ago", diff];
	} else {
		int diff = round(time / 60 / 60 / 24 / 7);
		if (diff == 1)
			return [NSString stringWithFormat:@"last week", diff];
		return [NSString stringWithFormat:@"%d weeks ago", diff];
	}   
}

@end