//
//  RDRedditClient.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKDeferredSqliteCache.h"

#define REDDIT_URL @"http://www.reddit.com/"

@interface RDRedditClient : NSObject 
{
  id<DKCache> methodCache;
}

@property(retain) id<DKCache> methodCache;

+ (id)sharedClient;

- (NSArray *)accounts;
- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password;
- (DKDeferred *)vote:(int)d item:(NSString *)theid subreddit:(NSString *)sub username:(NSString *)un;

- (DKDeferred *)subredditsForUsername:(NSString *)username;
- (DKDeferred *)cachedSubredditsForUsername:(NSString *)username;

- (DKDeferred *)subreddit:(NSString *)sub forUsername:(NSString *)username;
- (DKDeferred *)cachedSubreddit:(NSString *)sub forUsername:(NSString *)username;

@end


@interface RDRestClient : DKRestClient
{
}

@end
