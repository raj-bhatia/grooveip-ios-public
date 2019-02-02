/*
*  VerifyManager.m
*
*  Copyright (C) 2017 SNRB Labs LLC
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import "VerifyManager.h"
#import "GenericResponse.h"
#import "Secret.h"

@implementation VerifyManager

static VerifyManager *verifyManager = nil;

+ (void) parseResponse : (NSData *) data : (GenericResponse *) genericResponse : (NSError *) error
{
	if (!error) {
		NSLog(@"VerifyManager: Got a good response");
	} else {
		NSLog(@"VerifyManager error: %@", error.localizedDescription);
	}
}

- (void)verifyWithPhoneNumber: (NSString *) phoneNumber
				   completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;
{
	NSString *string1 = @"-1";
	NSString *string2 = @"-1";
	NSString *url = [NSString stringWithFormat : @"%@/%@", VERIFY_URL, phoneNumber];
	
	LOGD(@"VerifyManager enter: phoneNumber %@ URL %@", phoneNumber, url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSString *hash = [Secret getHash_Verify:phoneNumber string1:string1 string2:string2 epochTime:nowEpochMSecs];
	NSString *auth = [NSString stringWithFormat:@"HMAC %@:%@:%@", string1, string2, hash];
	[request setValue:auth forHTTPHeaderField:@"Authorization"];
	
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	[[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		int status;
		LOGD(@"Request reply: %@", requestReply);
		LOGD(@"Response: %@", response);
		
		if (error) {
			NSLog(@"Request reply error: %@", error);
			status = -3;
			if (completionHandler != nil) completionHandler (nil, &status);
			return;
		}
		
		// handle HTTP errors here
		if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
			long statusCode = [(NSHTTPURLResponse *)response statusCode];
			if (200 != statusCode) {
				NSLog(@"Request reply HTTP status code: %ld", statusCode);
				status = (int) statusCode;
				if (completionHandler != nil) completionHandler (nil, &status);
				return;
			}
		}
		
		GenericResponse *genericResponse = [[GenericResponse alloc] init];
		error = nil;
		
		[VerifyManager parseResponse : data : genericResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (genericResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (VerifyManager *)instance {
	@synchronized(self) {
		if (verifyManager == nil) {
			verifyManager = [[VerifyManager alloc] init];
		}
	}
	return verifyManager;
}

@end
