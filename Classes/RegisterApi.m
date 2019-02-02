/*
 *  RegisterApi.m
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
#import "RegisterApi.h"
#import "RegisterApiResponse.h"
#import "Secret.h"

@implementation RegisterApi

static RegisterApi *registerApi = nil;

+ (void) parseResponse : (NSData *) data : (RegisterApiResponse *) registerApiResponse : (NSError *) error
{
	NSDictionary *dictRx = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	LOGD(@"NSDictionary = %@", dictRx);
	
	if (!error) {
		registerApiResponse.userId = [dictRx[@"Id"] intValue];
		registerApiResponse.token = dictRx[@"Token"];
		LOGD(@"User = %d %@", registerApiResponse.userId, registerApiResponse.token);
	} else {
		NSLog(@"Error: %@", error.localizedDescription);
	}
}

- (void) registerApiWithEmail : (NSString *) email
					 password : (NSString *) password
				  deviceToken : (NSString *) deviceToken
				  serviceType : (NSString *) serviceType
			 verificationCode : (NSString *) verificationCode
				 mobileNumber : (NSString *) mobileNumber
					timestamp : (int) timestamp
				   completion : (void (^) (RegisterApiResponse *registerApiResponse, int *status)) completionHandler;
{
	LOGD(@"RegisterApi enter: email %@ password %@ deviceToken %@ serviceType %@ verificationCode %@ mobileNumber %@ timestamp %d", email, password, deviceToken, serviceType, verificationCode, mobileNumber, timestamp);
	
	NSDate *now = [NSDate date];
	long nowEpochSecs = (long) ([now timeIntervalSince1970]);
	int delta = (int) (nowEpochSecs - timestamp);
	
	NSDictionary *dictTx = @{@"DeviceToken" : deviceToken,
							 @"ServiceType" : serviceType,
							 @"VerificationCode" : verificationCode,
							 @"MobileNumber" : mobileNumber,
							 @"Delta" : [NSNumber numberWithInt : delta]};
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
	[request setURL:[NSURL URLWithString:REGISTER_URL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:json];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochSecs] forHTTPHeaderField:@"Date"];
	
	NSData *nsdataPassword = [password dataUsingEncoding:NSUTF8StringEncoding];
	NSString *base64Password = [nsdataPassword base64EncodedStringWithOptions:0];
	NSString *hash = [Secret getHash_Register:email password:password deviceToken:deviceToken serviceType:serviceType verificationCode:verificationCode mobileNumber:mobileNumber delta:delta epochTime:nowEpochSecs];
	NSString *auth = [NSString stringWithFormat:@"HMAC %@:%@:%@", email, base64Password, hash];
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
		
		RegisterApiResponse *registerApiResponse = [[RegisterApiResponse alloc] init];
		error = nil;
		
		[RegisterApi parseResponse : data : registerApiResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (registerApiResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (RegisterApi *) instance {
	@synchronized(self) {
		if (registerApi == nil) {
			registerApi = [[RegisterApi alloc] init];
		}
	}
	return registerApi;
}

@end
