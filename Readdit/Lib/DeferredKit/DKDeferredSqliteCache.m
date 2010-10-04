//
//  DKDeferredSqliteCache.m
//  CraigsFish
//
//  Created by Aaron Voisine on 7/23/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "DKDeferredSqliteCache.h"
#import "sqlite3.h"
#import <CommonCrypto/CommonDigest.h>

///
/// The shared cache object
/// 
static DKDeferredSqliteCache *__sqliteCache;

@interface DKDeferredSqliteCache (PrivateParts)

- (void)queueCacheOperation:(DKDeferred *)d op:(DKCallback *)op arg:(id)a;
- (id)_pausedQueueCacheOperation:(id)d :(id)op :(id)val :(id)r; // aint that purdy

@end


@implementation DKDeferredSqliteCache

@synthesize maxEntries, defaultTimeout, useMemoryCache, deferCacheSets;
@synthesize forceImmediateCaching = shouldImmediatelyCache;

/// DKCache Protocol
- (id)setValue:(NSObject *)value forKey:(NSString *)key 
timeout:(NSTimeInterval)timeout 
{
  return [self setValue:value forKey:key timeout:timeout paused:NO];
}

- (id)setValue:(NSObject *)_value forKey:(NSString *)_key 
timeout:(NSTimeInterval)_seconds paused:(BOOL)_paused
{
  if (!_value || !_key) {
    return [DKDeferred fail:[NSError errorWithDomain:DKDeferredErrorDomain 
       code:400 userInfo:
       dict_(@"could not use nil key or value in cache", @"message")]];
  }
  if (deferCacheSets && useMemoryCache) {
    @synchronized(memoryCache) {
      [memoryCache setObject:_value forKey:_key];
    }
    return !_paused ? [DKDeferred succeed:[NSNull null]] 
                    : [[DKDeferred deferred] addCallback:
                       callbackTS(self, _pausedCacheMiss:)];
  }
  DKDeferred *ret;
  DKCallback *op = curryTS(self, @selector(_setValue:forKey:timeout:arg:), 
                           _value, _key, nsni((int)_seconds));
  if (!_paused) {
    ret = [DKDeferred deferred];
    [self queueCacheOperation:ret op:op arg:[NSNull null]];
  } else {
    ret = [[DKDeferred deferred] addCallback:
           curryTS(self, @selector(_pausedQueueCacheOperation::::), 
                   [DKDeferred deferred], op, [NSNull null])];
  }
  return ret;
}

- (id)_didInvalidateMemoryCacheObject:(NSArray *)obj
{
  id k = [obj objectAtIndex:0];
  id o = [obj objectAtIndex:1];
  NSLog(@"invalidating from mem %@", k);
  if (shouldImmediatelyCache) {
    [self _setValue:o forKey:k timeout:nsni((int)self.defaultTimeout) arg:@"dontsetmemory"];
  } else {
    [self queueCacheOperation:[DKDeferred deferred] op:
     curryTS(self, @selector(_setValue:forKey:timeout:arg:), 
             o, k, nsni((int)self.defaultTimeout)) arg:@"dontsetmemory"];
  }
  return nil;
}

- (id)valueForKey:(NSString *)key 
{
  return [self valueForKey:key paused:NO];
}

- (id)valueForKey:(NSString *)_key paused:(BOOL)_paused
{
  if (!_key) return [DKDeferred fail:
                     [NSError errorWithDomain:DKDeferredErrorDomain code:
                     500 userInfo:dict_(@"failed to get nil key", @"message")]];
  
  // if using the memory cache, check that
  if (useMemoryCache) {
    id v = nil;
    @synchronized(memoryCache) {
      v = [[[memoryCache objectForKey:_key] retain] autorelease];
    }
    if (v && _paused) return [[DKDeferred deferred] addCallback:
                              curryTS(self, @selector(_returnFromMemoryCachePaused::), v)];
    if (v) return [DKDeferred succeed:v];
  }
  
  // check the in-memory list of keys first, if it's gone, ignore this request entirely
  BOOL inCache = NO;
  @synchronized(self) {
    inCache = [self hasKey:_key];
  }
  if (!inCache) {
    if (_paused) return [[DKDeferred deferred] 
                         addCallback:callbackTS(self, _pausedCacheMiss:)];
    return [DKDeferred succeed:[NSNull null]];
  }
  
  // if all else fails, finally queue the cache request
  DKDeferred *ret;
  if (!_paused) {
    ret = [DKDeferred deferred];
    [self queueCacheOperation:ret op:callbackTS(self, _getValue:) arg:_key];
  } else {
    ret = [[DKDeferred deferred] addCallback:
           curryTS(self, @selector(_pausedQueueCacheOperation::::), 
                   [DKDeferred deferred], callbackTS(self, _getValue:), _key)];
  }
  return ret;
}

- (id)objectForKeyInMemory:(id)k
{
  id o = nil;
  @synchronized(memoryCache) {
    o = [memoryCache objectForKey:k];
  }
  return o;
}

- (id)_pausedCacheMiss:(id)r
{
  return [NSNull null];
}

- (id)_pausedQueueCacheOperation:(id)d :(id)op :(id)val :(id)r
{
  [self queueCacheOperation:d op:op arg:val];
  return d;
}

- (void)purgeMemoryCache
{
  @synchronized(memoryCache) {
    [memoryCache invalidateAllKeys];
  }
}

- (id)_returnFromMemoryCachePaused:v :r
{
  return v;
}

- (void)deleteValueForKey:(NSString *)key // TODO: Make asynchronous
{
    if (useMemoryCache) {
      @synchronized(memoryCache) {
          [memoryCache invalidateKey:key];
      }
    }

    char s[70];
    sqlite3_snprintf(70, s, "DELETE FROM dkcache WHERE key=%u", key.hash);

    NSLog(@"%s", s);
    @synchronized(self) { sqlite3_exec(db, s, NULL, NULL, NULL); }
    
    [existingKeys removeObject:[NSNumber numberWithUnsignedInteger:key.hash]];
}

- (id)getManyValues:(NSArray *)keys 
{
  return [self getManyValues:keys paused:NO];
}

- (id)getManyValues:(NSArray *)_keys paused:(BOOL)_paused
{
  if (!_keys || [_keys isEqual:[NSNull null]] || ![_keys count])
    return [DKDeferred fail:[NSError errorWithDomain:DKDeferredErrorDomain 
            code:500 userInfo:dict_(@"could not perform an empty multi get", @"message")]];
  
  DKDeferred *ret;
  if (!_paused) {
    ret = [DKDeferred deferred];
    [self queueCacheOperation:ret op:callbackTS(self, _getManyValues:) arg:_keys];
  } else {
    ret = [[DKDeferred deferred] addCallback:
           curryTS(self, @selector(_pausedQueueCacheOperation::::), 
                   [DKDeferred deferred], callbackTS(self, _getManyValues:), _keys)];
  }
  return ret;
}

- (BOOL)hasKey:(NSString *)key 
{
    if ([self hasKeyInMemory:key]) return YES;
    
    return [existingKeys containsObject:[NSNumber 
            numberWithUnsignedInteger:key.hash]];
}

- (BOOL)hasKeyInMemory:(NSString *)key 
{
    if (! useMemoryCache) return NO;

    BOOL h = NO;
    @synchronized(memoryCache) {
        h = [memoryCache hasKey:key];
    }
    return h;
}

// TODO: convert to use NSUserDefaults....
- (id)incr:(NSString *)key delta:(int)delta // synchronous 
{ 
    NSNumber *val = nil;
    if (! [self hasKey:key] || ! (val = [self _getValue:key])) {
        return [NSError errorWithDomain:DKDeferredErrorDomain code:9903 
                userInfo:EMPTY_DICT];
    }
    NSNumber *newVal = [NSNumber numberWithInt:[val intValue] + delta];
    [self _setValue:newVal forKey:key timeout:[NSNumber numberWithInt:0] 
     arg:nil];
    return newVal;
}

// TODO: convert to use NSUserDefaults....
- (id)decr:(NSString *)key delta:(int)delta // synchronous
{
    return [self incr:key delta:-delta];
}

// should always be executed in a thread
- (id)_getManyValues:(NSArray *)keys 
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[keys count]];
    NSObject *val = nil;
    for (NSString *key in keys) {
        val = [self _getValue:key];
        [ret addObject:((val == nil) ? [NSNull null] : val)];
    }
    return ret;
}

// should always be executed in a thread
- (id)_getValue:(NSString *)key 
{ 
    if (key == (id)[NSNull null]) return key;

    if (! [self hasKey:key]) return nil;
    
    sqlite3_stmt *stmt;
    char s[140];
    sqlite3_snprintf(140, s, "SELECT value,timeout,flags,klass FROM dkcache WHERE "
                     "key=%u AND value!=ZEROBLOB(LENGTH(value))", key.hash);
    //NSLog(@"DKDeferredSqliteCache:_getValue %u", key.hash);
    @synchronized(self) {
        if (sqlite3_prepare_v2(db, s, -1, &stmt, NULL) != SQLITE_OK) return nil;
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            NSUInteger timeout = sqlite3_column_int64(stmt, 1);
            if (timeout < (NSUInteger)[[NSDate date] timeIntervalSince1970]) {
                sqlite3_finalize(stmt);
                NSLog(@"%u < %u - cache timeout", timeout, 
                      (NSUInteger)[[NSDate date] timeIntervalSince1970]); 
                [self deleteValueForKey:key];
                return nil;
            }
            NSData *d = [NSData dataWithBytes:sqlite3_column_blob(stmt, 0) 
                         length:sqlite3_column_bytes(stmt, 0)];
            int f = sqlite3_column_int(stmt, 2);
            id value = (f == 1) ? d : (f == 2) ? d :
                       [NSKeyedUnarchiver unarchiveObjectWithData:d];
            if (f == 2) {
                NSString *klass = [NSString stringWithCString:
                    (const char *)sqlite3_column_text(stmt, 3) encoding:NSUTF8StringEncoding];
                value = [NSClassFromString(klass) performSelector:
                         @selector(fromCacheData:key:) withObject:d withObject:key];
            }
            if (useMemoryCache) {
                @synchronized(memoryCache) {
                    [memoryCache setObject:value forKey:key];
                }
            }

//            NSLog(@"DKDeferredSqliteCache:_getValue %u cache hit", key.hash);
            sqlite3_finalize(stmt);
            return value;
        }

//        NSLog(@"DKDeferredSqliteCache:_getValue %u cache miss", key.hash);
        sqlite3_finalize(stmt);
    }
    
    //[self deleteValueForKey:key];
    return nil;
}

     
// should always be executed in a thread
- (id)_setValue:(id)value forKey:(NSString *)key 
timeout:(NSNumber *)timeout arg:(id)arg 
{
    if (! [[value class] canBeStoredInCache] && 
        ! [value respondsToSelector:@selector(dataForCacheKey:)]) return nil;
    
    if (useMemoryCache && ![arg isEqual:@"dontsetmemory"]) { // lols hax 4 infuhnit lupe
        @synchronized(memoryCache) {
            [memoryCache setObject:value forKey:key];
        }
    }
  
    [self _cull];

    int f = [value isKindOfClass:[NSData class]] ? 1 : 
            [value respondsToSelector:@selector(dataForCacheKey:)] ? 2 : 0;
    NSData *d = (f == 1) ? value : (f == 2) ? 
                [value performSelector:@selector(dataForCacheKey:) withObject:key] : 
                [NSKeyedArchiver archivedDataWithRootObject:value];
    if (! d) {
        NSLog(@"DKDeferredSqliteCache:error setting cache value for %@", key);
        return nil;
    }
    
    NSTimeInterval t = [timeout doubleValue];
    char s[140];

    sqlite3_snprintf(140, s, "INSERT OR REPLACE INTO dkcache (key,value,"
                     "timeout,flags,klass) VALUES(%u,ZEROBLOB(%u),%u,%d,'%s')", key.hash,
                     d.length, (NSUInteger)[[NSDate 
                     dateWithTimeIntervalSinceNow:t > 0 ? t : defaultTimeout] 
                     timeIntervalSince1970], f, [NSStringFromClass([value class]) UTF8String]);
    //NSLog(@"DKDeferredSqliteCache:_setValue %u", key.hash);
    @synchronized(self) {
        if (sqlite3_exec(db, s, NULL, NULL, NULL) != SQLITE_OK) {
            NSLog(@"DKDeferredSqliteCache: _setValue failed %s", sqlite3_errmsg(db));
            return nil;
        }
        sqlite3_blob *blob;
        sqlite3_int64 rowid = sqlite3_last_insert_rowid(db);
        sqlite3_blob_open(db, "main", "dkcache", "value", rowid, 1, &blob);
        if (sqlite3_blob_write(blob, d.bytes, d.length, 0) != SQLITE_OK)
            NSLog(@"DKDeferredSqliteCache:_setValue %u blob write failed", 
                  key.hash);
        //else NSLog(@"DKDeferredSqliteCache:_setValue %u item cached", key.hash);
        sqlite3_blob_close(blob);
    }
        
    [existingKeys addObject:[NSNumber numberWithUnsignedInteger:key.hash]];
    
    return nil;
}

+ (id)sharedCache 
{
    if (!__sqliteCache)
        __sqliteCache = [[DKDeferredSqliteCache alloc] 
                         initWithDbName:@"dkcache.db" maxEntries:3000
                         cullFrequency:10];
    return __sqliteCache;
}

- (void)processCacheInbox:(id)arg
{
  while (YES) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *items = nil;
    [conditionLock lockWhenCondition:DKCacheInboxHasItems];
    items = [NSArray arrayWithArray:inbox];
    [inbox removeAllObjects];
    [conditionLock unlockWithCondition:DKCacheInboxIsEmpty];
    for (NSArray *cacheOperation in items) {
      DKDeferred *d = [cacheOperation objectAtIndex:0];
      DKCallback *c = [cacheOperation objectAtIndex:1];
      id arg = [cacheOperation objectAtIndex:2];
      
      id r = [[[c :arg] retain] autorelease];
      if (r == nil) r = [NSNull null];
      SEL sel = @selector(callback:);
      if ([r isKindOfClass:[NSError class]]) sel = @selector(errback:);

      [d performSelector:sel onThread:callingThread 
              withObject:r waitUntilDone:NO];
      
      [[NSRunLoop currentRunLoop] runUntilDate:
       [NSDate dateWithTimeIntervalSinceNow:1.0/30.0]];
    }
    [pool drain];
  }
}

- (void)queueCacheOperation:(DKDeferred *)d op:(DKCallback *)op arg:(id)a
{
  [conditionLock lock];
  [inbox addObject:array_(d, op, a)];
  [conditionLock unlockWithCondition:DKCacheInboxHasItems];
}

- (id)initWithDbName:(NSString *)_dbname maxEntries:(int)_maxEntries
cullFrequency:(int)_cullFrequency 
{
    if (! (self = [super init])) return self;
    
    memoryCache = [[DKSimpleMemoryCache alloc] initWithCapacity:300];
    shouldImmediatelyCache = NO;
    self.useMemoryCache = YES;
    self.deferCacheSets = YES;
    maxEntries = (_maxEntries < 1) ? 3000 : _maxEntries;
    cullFrequency = (_cullFrequency < 1) ? 10 : _cullFrequency;
    defaultTimeout = 7200;
    conditionLock = [[NSConditionLock alloc] initWithCondition:DKCacheInboxIsEmpty];
    inbox = [[NSMutableArray alloc] init];
    callingThread = [NSThread currentThread];
    [NSThread detachNewThreadSelector:@selector(processCacheInbox:) 
                             toTarget:self withObject:nil];

    if (sqlite3_open([[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
                     NSUserDirectory, YES) objectAtIndex:0] 
                     stringByAppendingPathComponent:_dbname] UTF8String], &db)
        != SQLITE_OK) {
        sqlite3_close(db); // open failed, clean up anyway
        NSAssert1(0, @"Failed to open database: %s", sqlite3_errmsg(db));
    }
    
    sqlite3_exec(db, "PRAGMA synchronous=OFF", NULL, NULL, NULL);
    sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS dkcache (key UNSIGNED INTEGER "
                 "PRIMARY KEY, timeout DATETIME, value BLOB, flags INTEGER "
                 "DEFAULT 0, stamp DATETIME DEFAULT CURRENT_TIMESTAMP, "
                 "klass VARCHAR(70))", NULL, NULL, NULL);

    existingKeys = [[NSMutableSet alloc] initWithCapacity:_maxEntries];
    
    sqlite3_stmt *stmt;
    char s[70];
    if (sqlite3_prepare_v2(db, sqlite3_snprintf(70, s, "SELECT key FROM "
        "dkcache WHERE timeout>%u", (NSUInteger)[[NSDate date] 
        timeIntervalSince1970]), -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSUInteger k = (NSUInteger)sqlite3_column_int64(stmt, 0);
            if (k) 
                [existingKeys addObject:[NSNumber numberWithUnsignedInteger:k]];
        }
        sqlite3_finalize(stmt);
    }
    
    NSLog(@"DKDeferredSqliteCache:initWithDbName %@ found %d existing entries", _dbname,
          [existingKeys count]);
    
    return self;
}

- (void)setDeferCacheSets:(BOOL)v
{
  @synchronized(self) {
    deferCacheSets = v;
  }
  if (deferCacheSets && useMemoryCache) 
    memoryCache.onInvalidate = callbackTS(self, _didInvalidateMemoryCacheObject:);
  else
    memoryCache.onInvalidate = nil;
}

- (void)setMemoryCacheMaximum:(int)count
{
  [memoryCache setCapacity:count];
}

- (void)dealloc 
{ 
  [inbox release];
  [conditionLock release];
  [memoryCache release];
  [existingKeys release];
  sqlite3_close(db);
  [super dealloc];
}


- (void)_cull 
{
    if ([self _getNumEntries] <= maxEntries) return;

    NSLog(@"DKDeferredSqliteCache:_cull deleting %d entries", 
          maxEntries/cullFrequency);
    
    char s[140];
    sqlite3_snprintf(140, s, "DELETE FROM dkcache WHERE stamp<(SELECT stamp "
                     "FROM dkcache ORDER BY stamp DESC LIMIT %d OFFSET %d)",
                     maxEntries - (maxEntries/cullFrequency), 
                     maxEntries - (maxEntries/cullFrequency) - 1);
    NSLog(@"%s", s);
    
    @synchronized(self) {
        if (sqlite3_exec(db, s, NULL, NULL, NULL) != SQLITE_OK) {
            NSLog(@"DKDeferredSqliteCache:_cull delete failed: %s", 
                  sqlite3_errmsg(db));
            return;
        }

        [existingKeys removeAllObjects];

        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, sqlite3_snprintf(70, s, "SELECT key FROM "
            "dkcache WHERE timeout>%u", (NSUInteger)[[NSDate date] 
            timeIntervalSince1970]), -1, &stmt, NULL) != SQLITE_OK) return;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSUInteger k = (NSUInteger)sqlite3_column_int64(stmt, 0);
            if (k) 
                [existingKeys addObject:[NSNumber numberWithUnsignedInteger:k]];
        }
        sqlite3_finalize(stmt);
    }
    
    NSLog(@"DKDeferredSqliteCache:_cull %d entries remain", 
          [existingKeys count]);
}

- (int)_getNumEntries 
{
    return [existingKeys count];
}

@end

