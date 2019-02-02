/*
 *  OutgoingCall.m
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
#import "OutgoingCall.h"
#import "GenericResponse.h"
#import "Secret.h"

@implementation OutgoingCall

static OutgoingCall *outgoingCall = nil;

+ (void) parseResponse : (NSData *) data : (GenericResponse *) genericResponse : (NSError *) error
{
	if (!error) {
		NSLog(@"OutgoingCall: Got a good response");
	} else {
		NSLog(@"OutgoingCall error: %@", error.localizedDescription);
	}
}

- (void)outgoingCallWithUserId: (NSString *) userId
						 token: (NSString *) token
				  calledNumber: (NSString *) calledNumber
						  flag: (int) flag
					completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;
{
	NSError *error = nil;
	NSData *json;
	NSString *jsonString;
	int status;
	
	LOGD(@"OutgoingCall enter: userId %@ token %@ calledNumber %@ flag %d", userId, token, calledNumber, flag);
	
	if (nil == calledNumber) {
		status = -10;
		if (completionHandler != nil) completionHandler (nil, &status);
		return;
	}
	
	NSDictionary *dictTx = @{@"CalledNumber" : calledNumber,
							 		 @"Flag" : [NSNumber numberWithInt : flag]};
	
	// Dictionary convertable to JSON ?
	if ([NSJSONSerialization isValidJSONObject:dictTx]) {
		// Serialize the dictionary
		json = [NSJSONSerialization dataWithJSONObject:dictTx options:NSJSONWritingPrettyPrinted error:&error];
		
		if (json != nil && error == nil) {
			jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
			LOGD(@"JSON: %@", jsonString);
		}
		else {
			status = -1;
			if (completionHandler != nil) completionHandler (nil, &status);
			return;
		}
	} else {
		status = -2;
		if (completionHandler != nil) completionHandler (nil, &status);
		return;
	}
	
	unsigned long len = (unsigned long) [jsonString length];
	NSString *postLength = [NSString stringWithFormat:@"%ld", len];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:OUTGOING_CALL_URL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:json];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSString *hash = [Secret getHash_OutgoingCall:userId token:token calledNumber:calledNumber epochTime:nowEpochMSecs];
	NSString *auth = [NSString stringWithFormat:@"HMAC %@:%@:%@", userId, token, hash];
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
		
		[OutgoingCall parseResponse : data : genericResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (genericResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (OutgoingCall *)instance {
	@synchronized(self) {
		if (outgoingCall == nil) {
			outgoingCall = [[OutgoingCall alloc] init];
		}
	}
	return outgoingCall;
}

@end
