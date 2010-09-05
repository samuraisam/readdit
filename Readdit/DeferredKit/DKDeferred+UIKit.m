//
//  DKDeferred+UIKit.m
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import "DKDeferred+UIKit.h"
#import "UIImage+DKDeferred.h"


@implementation DKDeferred (UIKitAdditions)

+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached paused:(BOOL)_paused {
  DKDeferred *d;
  if (cached) {
    d = [[DKDeferred cache] valueForKey:aUrl paused:_paused];
//    if (_paused)
//      d = pauseDeferred(d);
    [d addCallback:curryTS((id)self, 
     @selector(_cachedLoadURLCallback:cacheTimeout:results:), aUrl,
     [NSNumber numberWithInt:INT_MAX])];
  } else {
    d = [self loadURL:aUrl paused:_paused];
  }
  [d addCallback:curryTS((id)self, @selector(_loadImageCallback:results:), aUrl)];
  return d;
}

+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached paused:(BOOL)_paused
{
  DKDeferred *d;
  if (cached) {
    d = [[DKDeferred cache] valueForKey:aUrl paused:_paused];
    [d addCallback:curryTS((id)self, @selector(_uncachedURLLoadCallback:results:), aUrl)];
  } else {
    d = [self loadURL:aUrl paused:_paused];
  }
  [d addCallback:curryTS((id)self, @selector(_loadImageCallback:results:), aUrl)];
  if (cached && ![[DKDeferred cache] hasKey:aUrl]) {
    [d addCallback:curryTS((id)self, @selector(_resizeImageCallbackSize:url:cache:results:), 
                   array_(nsnf(size.width), nsnf(size.height)), aUrl, nsnb(cached))];
  }
  return d;
}

+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached
{
  return [self loadImage:aUrl cached:cached paused:NO];
}

+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached {
  return [self loadImage:aUrl sizeTo:size cached:cached paused:NO];
}

+ (id)_loadImageCallback:(NSString *)url results:(id)_results
{
  if (isDeferred(_results)) {
    return [_results addBoth:curryTS((id)self, @selector(_loadImageCallback:results:), url)];
  } else if ([_results isKindOfClass:[NSData class]]) {
    UIImage *ret = [UIImage imageWithData:_results];
    if (ret == nil) return [NSError errorWithDomain:DKDeferredErrorDomain 
      code:500 userInfo:dict_(@"could not load this image into memory", 
                              @"message", url, @"key")];
    return ret;
  } else if ([_results isKindOfClass:[UIImage class]]) return _results;
  return nil;
}

+ (id)_resizeImageCallbackSize:(NSArray *)size url:(NSString *)url 
                         cache:(id)shouldCache results:(id)_results
{
  if (isDeferred(_results))
    return [_results addBoth:curryTS((id)self, 
           @selector(_resizeImageCallbackSize:url:cache:results:), 
                                     size, url, shouldCache)];
  if ([_results isKindOfClass:[UIImage class]]) {
    UIImage *img = [(UIImage *)_results scaleImageToSize:
                    CGSizeMake([[size objectAtIndex:0] floatValue],
                               [[size objectAtIndex:0] floatValue])];
    if (img == nil) return [NSError errorWithDomain:
                            DKDeferredErrorDomain code:500 userInfo:
                            dict_(@"failed while resizing image", @"message", 
                                  url, @"url")];
    if (boolv(shouldCache)) {
      [[[DKDeferred cache] 
       setValue:img forKey:url timeout:INT_MAX] addErrback:
       callbackTS(self, setCacheError:)];
    }
    return img;
  }
  return nil;
}

+ (id)setCacheError:(NSError *)er
{
  NSLog(@"set cache error %@", er);
  return er;
}

@end
