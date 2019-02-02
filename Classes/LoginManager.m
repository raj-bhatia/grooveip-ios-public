/*
 *  LoginManager.m
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
#import "LoginManager.h"
#import "LoginResponse.h"
#import "Secret.h"

@implementation LoginManager

static LoginManager *loginManager = nil;

+ (void) parseResponse : (NSData *) data : (LoginResponse *) loginResponse : (NSError *) error
{
	NSDictionary *dictRx = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	LOGD(@"NSDictionary = %@", dictRx);
	
	if (!error) {
		for ( NSString *key in [dictRx allKeys]) {
			NSObject *value = dictRx[key];
			LOGD(@"Key Value = %@ %@", key, value);
			if ([key isEqualToString:@"PhoneNumber"]) {
				loginResponse.phoneNumber = (NSString *) value;
				LOGD(@"PhoneNumber = %@", loginResponse.phoneNumber);
			} else if ([key isEqualToString:@"Currency"]) {
				//
				// Currency (string)	Credits		Dollars		Other/None
				// Currency (int)	  0		  1		  -1
				//
				NSString *currencyString = (NSString *) value;
				if ([currencyString isEqualToString:@"Credits"]) {
					loginResponse.currency = 0;
				} else if ([currencyString isEqualToString:@"Dollars"]) {
					loginResponse.currency = 1;
				} else {
					loginResponse.currency = -1;
				}
				LOGD(@"Currency = %@ / %d", currencyString, loginResponse.currency);
			} else if ([key isEqualToString:@"ExternalSip"]) {
				NSDictionary *dictSip = (NSDictionary *) value;
				loginResponse.sipName = dictSip[@"UserName"];
				loginResponse.sipPassword = dictSip[@"SipPassword"];
				loginResponse.sipServer = dictSip[@"Realm"];
				LOGD(@"SIP = %@ %@ %@", loginResponse.sipName, loginResponse.sipPassword, loginResponse.sipServer);
			} else if ([key isEqualToString:@"User"]) {
				NSDictionary *dictUser = (NSDictionary *) value;
				loginResponse.userId = [dictUser[@"Id"] intValue];
				loginResponse.token = dictUser[@"Token"];
				LOGD(@"User = %d %@", loginResponse.userId, loginResponse.token);
			}
		}
	} else {
		NSLog(@"Error: %@", error.localizedDescription);
	}
}

- (void)loginWithEmail:(NSString *)email
			password: (NSString *) password
			completion: (void (^)(LoginResponse *loginResponse, int *status)) completionHandler
{
	LOGD(@"LoginManager enter: email %@", email);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:LOGIN_URL]];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSData *nsdataPassword = [password dataUsingEncoding:NSUTF8StringEncoding];
	NSString *base64Password = [nsdataPassword base64EncodedStringWithOptions:0];
	NSString *hash = [Secret getHash_Login:email password:password epochTime:nowEpochMSecs];
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
		
		LoginResponse *loginResponse = [[LoginResponse alloc] init];
		error = nil;
		
		[LoginManager parseResponse : data : loginResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (loginResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (LoginManager*)instance {
	@synchronized(self) {
		if (loginManager == nil) {
			loginManager = [[LoginManager alloc] init];
		}
	}
	return loginManager;
}

@end
