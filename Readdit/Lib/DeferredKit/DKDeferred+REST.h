//
//  DKDeferred+REST.h
//  CraigsFish
//
//  Created by Samuel Sutch on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKDeferred.h"


@interface DKRestClient : NSObject
{
  NSString *mountPoint;
  NSString *username;
  NSString *password;
  BOOL decodeJSONResponses;
  BOOL useAuthorizationIfAvailable;
}

@property (retain) NSString *username, *password, *mountPoint;
@property (assign) BOOL decodeJSONResponses, useAuthorizationIfAvailable;
@property (readonly) BOOL authorized;

- (DKDeferred *)POST:(NSString *)method values:(NSDictionary *)values;
- (DKDeferred *)GET:(NSString *)method values:(NSDictionary *)values;
- (DKDeferred *)PUT:(NSString *)method values:(NSDictionary *)values;
- (DKDeferred *)DELETE:(NSString *)method values:(NSDictionary *)values;

- (void)authorizeRequest:(NSMutableURLRequest *)req;
- (NSDictionary *)authorizeParams:(NSDictionary *)params;

+ (id)clientWithURL:(NSString *)url;

@end


@interface DKMultipartFile : NSData
{
  NSString *contentType;
  NSString *filename;
  NSData *data;
}

- (NSUInteger)length;
- (const void *)bytes;

@property(nonatomic, copy) NSString *contentType, *filename;
@property(nonatomic, readonly) NSData *data;

@end



@interface DKDeferred (RestAdditions)

/**
 Returns a DKRestClient configured for the service URL `mnt`
 */
+ (DKRestClient *)rest:(NSString *)mnt;
+ (void)setRestClient:(DKRestClient *)client;

@end
