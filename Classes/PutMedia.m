/*
 *  PutMedia.m
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
#import "PutMedia.h"
#import "GenericResponse.h"
#import "Secret.h"

@implementation PutMedia

static PutMedia *putMedia = nil;

+ (void) parseResponse : (NSData *) data : (GenericResponse *) genericResponse : (NSError *) error
{
	if (!error) {
		NSLog(@"PutMedia: Got a good response");
	} else {
		NSLog(@"PutMedia error: %@", error.localizedDescription);
	}
}

- (void)putMediaWithUserId: (NSString *) userId
					 token: (NSString *) token
						to: (NSString *) to
				  fileName: (NSString *) fileName
					  data: (NSMutableData *) data
				completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;
{
	NSString *firstLetter = [to substringToIndex:1];
	if ([firstLetter isEqualToString:@"+"])
	{
		to = [to substringFromIndex:1];
	}
	unsigned long len = (unsigned long) [data length];
	NSString *postLength = [NSString stringWithFormat:@"%ld", len];
	NSString *url = [NSString stringWithFormat : @"%@/%@/file/%@", PUT_MEDIA_URL, to, fileName];

	LOGD(@"PutMedia enter: userId %@ token %@ to %@ fileName %@ Size %@ URL %@", userId, token, to, fileName, postLength, url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:data];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSString *hash = [Secret getHash_PutMedia:userId token:token to:to fileName:fileName epochTime:nowEpochMSecs];
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
		
		[PutMedia parseResponse : data : genericResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (genericResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (PutMedia *)instance {
	@synchronized(self) {
		if (putMedia == nil) {
			putMedia = [[PutMedia alloc] init];
		}
	}
	return putMedia;
}

@end
