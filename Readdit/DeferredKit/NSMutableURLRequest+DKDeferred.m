//
//  NSMutableURLRequest+DKDeferred.m
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSMutableURLRequest+DKDeferred.h"
#import "NSData+Base64.h"

@implementation NSMutableURLRequest (MutableURLRequestExtensions)

+ (id)authorizedRequestWithURL:(NSString *)url username:(NSString *)un password:(NSString *)pw
{
  id r = [[[[self class] alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
  [r setAuthorization:un password:pw];
  return r;
}

- (void)setMultipartValues:(NSDictionary *)defs setHeaders:(BOOL)shouldSetHeaders
{
  NSString *boundaryID = _uuid1();
  NSString *boundary = [NSString stringWithFormat:@"--%@\r\n", boundaryID];
  
  id val;
  int attachmentCount = 1;
  NSMutableData *body = [NSMutableData data];
  
  for (NSString *key in [defs allKeys]) {
    [body appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
    val = [defs objectForKey:key];
    if ([val isKindOfClass:[NSString class]]) {
      [body appendData:[[NSString stringWithFormat:
                         @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]
                        dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([val isKindOfClass:[DKMultipartFile class]]) {
      [body appendData:[[NSString stringWithFormat:
                         @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",
                         key, [val filename]] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [val contentType]]
                        dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:val];
      attachmentCount++;
    } else if ([val isKindOfClass:[NSData class]]) {
      [body appendData:[[NSString stringWithFormat:
                         @"Content-Disposition: form-data; name=\"%@\"; filename=\"attachment-%i\"\r\n",
                         key, attachmentCount] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:val];
      attachmentCount++;
    }
    NSLog(@"%@=>%@", key, NSStringFromClass([val class]));
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundaryID]
                    dataUsingEncoding:NSUTF8StringEncoding]];
  
  [self setHTTPBody:body];
  NSLog(@"body: %@ %i", [[NSString alloc] initWithData:[self HTTPBody] encoding:NSISOLatin1StringEncoding], [body length]);
  
  if (shouldSetHeaders) {
    [self setHTTPMethod:@"POST"];    
    [self setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",
                    boundaryID] forHTTPHeaderField:@"Content-Type"];
    [self setValue:[NSString stringWithFormat:@"%i", [body length]] 
     forHTTPHeaderField:@"Content-Length"];
  }
}

- (void)setAcceptsGzip
{
  [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
}

- (void)setAuthorization:(NSString *)un password:(NSString *)pw
{
  NSString *auth = [@"Basic " stringByAppendingString:
                    [[[[NSString stringWithFormat:@"%@:%@", un, pw] 
                      dataUsingEncoding:NSASCIIStringEncoding] base64EncodingWithLineLength:1200] 
                     stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
  [self setValue:auth forHTTPHeaderField:@"Authorization"];
  //[self addValue:auth forHTTPHeaderField:@"Authorization"];
  [self setHTTPShouldHandleCookies:NO];
  NSLog(@"authing %@ %@", auth, [self allHTTPHeaderFields]);
}

@end
