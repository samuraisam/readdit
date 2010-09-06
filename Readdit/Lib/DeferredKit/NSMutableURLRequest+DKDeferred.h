//
//  NSMutableURLRequest+DKDeferred.h
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DKMultipartFile;

@interface NSMutableURLRequest (MutableURLRequestExtensions)

- (void)setMultipartValues:(NSDictionary *)filesOrFields setHeaders:(BOOL)shouldSetHeaders;
- (void)setAcceptsGzip;
- (void)setAuthorization:(NSString *)username password:(NSString *)password;
+ (id)authorizedRequestWithURL:(NSString *)url username:(NSString *)username password:(NSString *)password;

@end
