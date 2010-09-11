//
//  RDRedditClient.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDRedditClient.h"
#import "RegexKitLite.h"
#import "DKDeferredSqliteCache.h"
#import "NSObject+UIKitGenericErrorHandling.h"


@implementation RDRedditClient

@synthesize methodCache;

+ (id)sharedClient
{
  static id sharedClient = nil;
  if (!sharedClient) {
    sharedClient = [[[self class] alloc] init];
    // TODO: multi-user support
    if (PREF_KEY(@"username")) {
      [DKDeferred setRestClient:[RDRestClient clientWithURL:REDDIT_URL]];
      [[DKDeferred rest:REDDIT_URL] setUsername:PREF_KEY(@"username")];
    }
    DKDeferredSqliteCache *c = [[[DKDeferredSqliteCache alloc] initWithDbName:
      @"rdmethodcache.db" maxEntries:3000 cullFrequency:3] autorelease];
    c.useMemoryCache = NO;
    [sharedClient setMethodCache:c];
  }
  return sharedClient;
}

- (NSArray *)accounts
{
  // TODO: multi-user support
  if (PREF_KEY(@"modhash")) {
    return array_(PREF_KEY(@"username"), PREF_KEY(@"modhash"), PREF_KEY(@"cookie"));
  }
  return EMPTY_ARRAY;
}

- (DKDeferred *)vote:(int)d item:(NSString *)theid subreddit:(NSString *)sub username:(NSString *)un
{
  return [[[DKDeferred rest:REDDIT_URL] POST:@"api/vote" values:
          dict_(theid, @"id", ([NSString stringWithFormat:@"%d", d]), @"dir", 
                sub, @"r", PREF_KEY(@"modhash"), @"uh")] 
          addCallback:callbackTS(self, _didVote:)];
}

- (id)_didVote:(id)r
{
  id d = nil;
  if ([r isKindOfClass:[NSData class]] && [(d = [[[[NSString alloc] initWithData:r encoding:
      NSUTF8StringEncoding] autorelease] JSONValue]) isKindOfClass:[NSDictionary class]]) {
    return @"success";
  }
  return @"failure";
}

- (DKDeferred *)subreddit:(NSString *)sub forUsername:(NSString *)username
{
  if (!username) username = @"";
  NSString *method = [sub stringByAppendingString:@".json"];
  return [[[[DKDeferred rest:REDDIT_URL] GET:method values:EMPTY_DICT]
           addBoth:curryTS(self, @selector(_gotSubredditUsername:method:results:), username, method)]
          addBoth:curryTS(self, @selector(_cacheMethod:username:results:), method, username)];
}

- (DKDeferred *)cachedSubreddit:(NSString *)sub forUsername:(NSString *)username
{
  if (!username) username = @"";
  NSString *method = [sub stringByAppendingString:@".json"];
  NSString *key = [username stringByAppendingString:method];
  NSLog(@"fetching cache %i %@", [methodCache hasKey:key], key);
  return [methodCache valueForKey:key];
}

- (id)_gotSubredditUsername:(NSString *)username method:(NSString *)method results:(id)r
{
  if ([r handleErrorAndAlert:NO]) return r;
  id ret = EMPTY_ARRAY;
  id d = [[[[NSString alloc] initWithData:r encoding:
            NSUTF8StringEncoding] autorelease] JSONValue];
  if ([d isKindOfClass:[NSDictionary class]]) {
    if (!(ret = [[d objectForKey:@"data"] objectForKey:@"children"]))
      ret = EMPTY_ARRAY;
  }
  return ret;
}

- (DKDeferred *)subredditsForUsername:(NSString *)username
{
  static NSString *m = @"reddits/mine/.json";
  if (!username) username = @"";
  return [[[[DKDeferred rest:REDDIT_URL] GET:m values:EMPTY_DICT] addCallback:
           curryTS(self, @selector(_didGetSubredditsUsername:method:results:), username, m)]
          addCallback:curryTS(self, @selector(_cacheMethod:username:results:), m, username)];
}

- (DKDeferred *)cachedSubredditsForUsername:(NSString *)username
{
  static NSString *m = @"reddits/mine/.json";
  if (!username) username = @"";
  NSString *key = [username stringByAppendingString:m];
  NSLog(@"fetching cache %i %@", [methodCache hasKey:key], key);
  return [methodCache valueForKey:key];
}

- (id)_didGetSubredditsUsername:(NSString *)username method:(NSString *)method results:(id)r
{
  id ret = EMPTY_ARRAY;
  id d = [[[[NSString alloc] initWithData:r encoding:
            NSUTF8StringEncoding] autorelease] JSONValue];
  if ([d isKindOfClass:[NSDictionary class]]) {
    id _d = [d objectForKey:@"data"];
    id _e = [_d objectForKey:@"children"];
    if ([_e isKindOfClass:[NSArray class]]) ret = _e;
    if (![[_d objectForKey:@"after"] isEqual:[NSNull null]]) {
      return [[[[DKDeferred rest:REDDIT_URL] GET:
                [method stringByAppendingFormat:@"?after=%@", [_d objectForKey:@"after"]] values:EMPTY_DICT] 
               addBoth:curryTS(self, @selector(_didGetSubredditsUsername:method:results:), username, method)]
              addBoth:curryTS(self, @selector(_appendToPriorResults:newResults:), ret)];
    }
  }
  return ret;
}

- (id)_appendToPriorResults:(NSArray *)existing newResults:(id)r
{
  NSMutableArray *ret = [NSMutableArray arrayWithArray:existing];
  [ret addObjectsFromArray:r];
  return ret;
}

- (id)_cacheMethod:(NSString *)method username:(NSString *)username results:(id)r
{
  if (isDeferred(r)) return [r addCallback:curryTS(self, 
                             @selector(_cacheMethod:username:results:), method, username)];
  
  if ([r handleErrorAndAlert:NO]) return r;
  
  NSString *key = [username stringByAppendingString:method];
  NSLog(@"caching %@", key);
  [methodCache setValue:r forKey:key timeout:INT_MAX];
  return r;
}

- (DKDeferred *)loginUsername:(NSString *)username password:(NSString *)password
{
  NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                               [NSURL URLWithString:REDDIT_URL @"api/login"]] autorelease];
  [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [req setHTTPShouldHandleCookies:NO];
  [req setHTTPMethod:@"POST"];
  [req setHTTPBody:
   [[NSString stringWithFormat:@"rem=on&passwd=%@&user=%@&api_type=json", 
     [password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], 
     [username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] 
    dataUsingEncoding:NSASCIIStringEncoding]];
  DKDeferredURLConnection *c = [[[DKDeferredURLConnection alloc] initWithRequest:
                                 req pauseFor:0 decodeFunction:nil] autorelease];
  [c addBoth:curryTS(self, @selector(_didLoginUsername:results:), username)];
  return c;
}

- (id)_didLoginUsername:(NSString *)username results:(id)r
{
  NSDictionary *headers = [[r URLResponse] allHeaderFields];
  NSLog(@"headers %@", headers);
  if ([r isKindOfClass:[NSData class]]) {
    id d = [[[[NSString alloc] initWithData:r encoding:
              NSUTF8StringEncoding] autorelease] JSONValue];
    if ([d isKindOfClass:[NSDictionary class]] 
        && [[[d objectForKey:@"json"] objectForKey:@"data"] objectForKey:@"modhash"]
        && [headers objectForKey:@"Set-Cookie"]) {
      // TODO: multi-user support
      PREF_SET(@"modhash", [[[d objectForKey:@"json"] objectForKey:@"data"]
                            objectForKey:@"modhash"]); // required for editing
      PREF_SET(@"username", username);
      PREF_SET(@"cookie", [headers objectForKey:@"Set-Cookie"]); // required for personalized pages
      PREF_SYNCHRONIZE;
      [DKDeferred setRestClient:[RDRestClient clientWithURL:REDDIT_URL]];
      [[DKDeferred rest:REDDIT_URL] setUsername:username];
      return @"success";
    }
  }
  return @"failure";
}

- (void)dealloc
{
  [methodCache release];
  [super dealloc];
}

@end


@implementation RDRestClient

- (NSDictionary *)authorizeParams:(NSDictionary *)params
{
  if (PREF_KEY(@"modhash") && [[params allKeys] count]) {
    NSMutableDictionary *d = [[params mutableCopy] autorelease];
    [d setObject:PREF_KEY(@"modhash") forKey:@"mh"];
    return d;
  }
  return params;
}

- (void)authorizeRequest:(NSMutableURLRequest *)req
{
  if (PREF_KEY(@"cookie")) {
    [req setHTTPShouldHandleCookies:NO];
    [req setValue:PREF_KEY(@"cookie") forHTTPHeaderField:@"Cookie"];
  }
}

@end
