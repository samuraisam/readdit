//
//  DKDeferred+REST.m
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DKDeferred+REST.h"
#import "NSString+DKDeferred.h"
#import "NSMutableURLRequest+DKDeferred.h"
#import "NSDictionary+DKDeferred.h"


NSMutableDictionary *__restClients = nil;

@implementation DKDeferred (RestAdditions)

+ (id)rest:(NSString *)mnt
{
  id r = nil;
  @synchronized(self) {
    if (__restClients == nil) __restClients = [[NSMutableDictionary dictionary] retain];
    r = [__restClients objectForKey:mnt];
    if (r == nil) [__restClients setObject:(r = [DKRestClient clientWithURL:mnt]) forKey:mnt];
  }
  return r;
}

@end



@interface DKRestClient (PrivateParts)

- (DKDeferred *)_do:(NSString *)method :(NSString *)httpMethod :(NSDictionary *)values;

@end



@implementation DKRestClient

@synthesize mountPoint, username, password, decodeJSONResponses, useAuthorizationIfAvailable;

+ (id)clientWithURL:(NSString *)url
{
  DKRestClient *c = [[[self alloc] init] autorelease];
  c.username = nil;
  c.password = nil;
  c.mountPoint = url;
  c.decodeJSONResponses = YES;
  c.useAuthorizationIfAvailable = YES;
  return c;
}

- (void)dealloc
{
  self.mountPoint = nil;
  self.username = nil;
  self.password = nil;
  [super dealloc];
}

- (BOOL)authorized
{
  return (self.password && self.username);
}

- (void)authorizeRequest:(NSMutableURLRequest *)req
{
  if (self.username && self.password)
    [req setAuthorization:self.username password:self.password];
}

- (DKDeferred *)GET:(NSString *)method values:(NSDictionary *)values
{
  return [self _do:method :@"GET" :values];
}

- (DKDeferred *) POST:(NSString *)method values:(NSDictionary *)values
{
  return [self _do:method :@"POST" :values];
}

- (DKDeferred *) PUT:(NSString *)method values:(NSDictionary *)values
{
  return [self _do:method :@"PUT" :values];
}

- (DKDeferred *) DELETE:(NSString *)method values:(NSDictionary *)values
{
  return [self _do:method :@"DELETE" :values];
}

- (DKDeferred *)_do:(NSString *)method :(NSString *)httpMethod :(NSDictionary *)values
{
  BOOL multipart = NO;
  for (id v in [values allValues]) {
    if (![v isKindOfClass:[NSString class]] && ![v isKindOfClass:[NSArray class]]) {
      multipart = YES;
      break;
    }
  }
  
  NSString *params = @"";
  if (!multipart) params = [values parameterString];
  NSLog(@"params %@", params);
  
  NSMutableString *u = [NSMutableString stringWithFormat:@"%@%@",
                        self.mountPoint, method];
  if ([httpMethod isEqualToString:@"GET"]) {
    if (params.length) {
      [u appendString:@"?"];
      [u appendString:params];
    }
  }
    
  NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                               [NSURL URLWithString:u]] autorelease];
  [req setAcceptsGzip];
  
  if (values && [[values allKeys] count]) {
    if ([array_(@"POST", @"PUT", @"DELETE") containsObject:httpMethod]) {
      if (multipart) {
        [req setMultipartValues:values setHeaders:YES];
      } else {
        [req setValue:@"application/x-www-form-urlencoded" 
         forHTTPHeaderField:@"Content-Type"];
        NSData *d = [params dataUsingEncoding:NSUTF8StringEncoding];
        [req setHTTPBody:d];
        [req setValue:[NSString stringWithFormat:@"%d", [d length]] 
         forHTTPHeaderField:@"Content-Length"];
      }
    }
  }
  
  [req setHTTPMethod:httpMethod];
  
  if (self.useAuthorizationIfAvailable)
    [self authorizeRequest:req];
  
  NSLog(@"self.username %@ self.password %@ headers %@", self.username, self.password, [req allHTTPHeaderFields]);
  
  return [[[[DKDeferredURLConnection alloc] initWithRequest:
            req pauseFor:0 decodeFunction:nil] autorelease] 
          addBoth:callbackTS(self, _did:)];
}

- (id)_did:(id)r
{
  if (isDeferred(r)) [r addCallback:callbackTS(self, _did:)];
  
  if (![r isKindOfClass:[NSError class]]) {
    if ([[[[r URLResponse] allHeaderFields] objectForKey:@"Content-Type"]
         isEqualToString:@"application/json"] && self.decodeJSONResponses) {
      NSString *str = [[[NSString alloc] initWithData:r 
                         encoding:NSUTF8StringEncoding] autorelease];
      NSError *err = nil;
      id ret = [[[[SBJSON alloc] init] autorelease] objectWithString:
                str error:&err];
      if (!err) {
        return ret;
      }
    }
  }
  return r;
}

@end


@implementation DKMultipartFile

@synthesize contentType, filename, data;

- (id) initWithBytes:(const void *)bytes length:(NSUInteger)length
{
  if (self = [super init]) {
    data = [[NSData dataWithBytes:bytes length:length] retain];
    self.contentType = nil;
    self.filename = nil;
  }
  return self;
}

- (NSUInteger) length { return [data length]; }

- (const void *)bytes { return [data bytes]; }

- (void)dealloc
{
  [data release];
  self.contentType = nil;
  self.filename = nil;
  [super dealloc];
}

@end
