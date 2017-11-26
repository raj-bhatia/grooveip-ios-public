/*
 *  MmsManager.m
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
#import "MmsManager.h"
#import "SmsResponse.h"
#import "Secret.h"

@implementation MmsManager

static MmsManager *mmsManager = nil;

+ (void) parseResponse : (NSData *) data : (SmsResponse *) smsResponse : (NSError *) error
{
	NSDictionary *dictRx = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	LOGD(@"NSDictionary = %@", dictRx);
	
	if (!error) {
		for ( NSString *key in [dictRx allKeys]) {
			NSObject *value = dictRx[key];
			LOGD(@"Key Value = %@ %@", key, value);
			if ([key isEqualToString:@"FreeCreditsRemaining"]) {
				LOGD(@"FreeCreditsRemaining = %@", (NSString *) value);
			} else if ([key isEqualToString:@"PaidCreditsRemaining"]) {
				LOGD(@"PaidCreditsRemaining = %@", (NSString *) value);
			}
		}
	} else {
		NSLog(@"Error: %@", error.localizedDescription);
	}
}

- (void)mmsWithUserId: (NSString *) userId
				token: (NSString *) token
				   to: (NSString *) to
				 from: (NSString *) from
				 text: (NSString *) text
			 fileName: (NSString *) fileName
		   completion: (void (^)(SmsResponse *smsResponse, int *status)) completionHandler;
{
	if (nil == text) {
		text = @"";
	}
	LOGD(@"MmsManager enter: userId %@ token %@ to %@ from %@ text %@ fileName %@", userId, token, to, from, text, fileName);
	
	NSDictionary *dictTx = @{@"To" : to,
							 @"From" : from,
							 @"Text" : text,
							 @"FileName" : fileName};
	NSError *error = nil;
	NSData *json;
	NSString *jsonString;
	int status;
 
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
	[request setURL:[NSURL URLWithString:MMS_URL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:json];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSString *hash = [Secret getHash_Mms:userId token:token from:from to:to text:text fileName:fileName epochTime:nowEpochMSecs];
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
		
		SmsResponse *smsResponse = [[SmsResponse alloc] init];
		error = nil;
		
		[MmsManager parseResponse : data : smsResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (smsResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (MmsManager*)instance {
	@synchronized(self) {
		if (mmsManager == nil) {
			mmsManager = [[MmsManager alloc] init];
		}
	}
	return mmsManager;
}

@end
