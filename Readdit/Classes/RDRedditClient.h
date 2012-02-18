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
#define MAXIMUM_SEEN_CACHE_COUNT 255


@interface RDRedditClient : NSObject 
{
  id<DKCache> methodCache;
  NSMutableDictionary *reads;
}

@property(retain) id<DKCache> methodCache;
@property(retain) NSMutableDictionary *reads;

+ (id)sharedClient;

- (NSArray *)accounts;

/* local data manipulation */
- (NSArray *)seenItemsForSubreddit:(NSString *)reddit username:(NSString *)username;
- (void)recordSeenItem:(NSString *)item subreddit:(NSString *)reddit username:(NSString *)username;
- (void)writeSeenItemCache;

/* account manipulation */
- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password;
- (DKDeferred *)vote:(int)d item:(NSString *)theid subreddit:(NSString *)sub username:(NSString *)un;
- (DKDeferred *)alterSubredditSubscription:(NSString *)subreddit withID:(NSString *)subId action:(NSString *)action username:(NSString *)username;

/* global subreddit enumeration */
- (DKDeferred *)allSubredditsPage:(NSString *)page existing:(NSArray *)existingResults;
- (DKDeferred *)queryAllSubreddits:(NSString *)term page:(NSString *)page existing:(NSArray *)existingResults;

/* account subreddit enumeration */
- (DKDeferred *)subredditsForUsername:(NSString *)username;
- (NSArray *)subscribedSubredditIdsForUsername:(NSString *)username; // requires calling subredditsForUsername first
- (DKDeferred *)cachedSubredditsForUsername:(NSString *)username;

/* account subreddit views */
- (DKDeferred *)subreddit:(NSString *)sub forUsername:(NSString *)username;
- (DKDeferred *)subreddit:(NSString *)sub page:(NSString *)page existing:(NSArray *)existingResults user:(NSString *)username;
- (DKDeferred *)cachedSubreddit:(NSString *)sub forUsername:(NSString *)username;

/* post manupulation */
- (DKDeferred *)postDetail:(NSString *)postId forUsername:(NSString *)username;

@end


@interface RDRestClient : DKRestClient
{
}

@end
