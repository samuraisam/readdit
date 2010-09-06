//
//  DKDeferredSqliteCache.h
//  CraigsFish
//
//  Created by Aaron Voisine on 7/23/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKDeferred.h"
#import "DKSimpleMemoryCache.h"
#import "sqlite3.h"

// DKDeferredSqliteCache
//
// Implements the DKCache protocol and uses a sqlite backend
//

enum DKCacheInbox {
  DKCacheInboxHasItems,
  DKCacheInboxIsEmpty
};

@interface DKDeferredSqliteCache : NSObject <DKCache> {
  int maxEntries;
  int cullFrequency;
  BOOL useMemoryCache, deferCacheSets;
  BOOL shouldImmediatelyCache;
  sqlite3 *db;
  NSTimeInterval defaultTimeout;
  NSMutableSet *existingKeys;
  DKSimpleMemoryCache *memoryCache;
  NSConditionLock *conditionLock;
  NSMutableArray *inbox;
  NSThread *callingThread;
}

+ (id)sharedCache;
- (id)initWithDbName:(NSString *)_dbname maxEntries:(int)_maxEntries
       cullFrequency:(int)_cullFrequency;
- (id)_setValue:(NSObject *)value forKey:(NSString *)key 
        timeout:(NSNumber *)timeout arg:(id)arg;
- (id)_getValue:(NSString *)key;
- (id)_getManyValues:(NSArray *)keys;
- (void)_cull;
- (int)_getNumEntries;
- (void)purgeMemoryCache;

@property (assign) int maxEntries;
@property (assign) NSTimeInterval defaultTimeout;
@property (assign) BOOL useMemoryCache, deferCacheSets;

@end
