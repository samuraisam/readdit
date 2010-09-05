//
//  RDRedditClient.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define REDDIT_URL @"http://www.reddit.com/"

@interface RDRedditClient : NSObject 
{
}

+ (id)sharedClient;
- (NSArray *)accounts;
- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password;

@end


@interface RDRestClient : DKRestClient
{
}

@end
