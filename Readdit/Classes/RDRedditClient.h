//
//  RDRedditClient.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RDRedditClient : NSObject 
{
}

+ (id)sharedClient;
- (NSArray *)accounts;
- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password;

@end
