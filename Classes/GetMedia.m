/*
 *  GetMedia.m
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
#import "GetMedia.h"
#import "GetMediaResponse.h"
#import "Secret.h"

@implementation GetMedia

static GetMedia *getMedia = nil;

+ (void) parseResponse : (NSData *) data : (GetMediaResponse *) getMediaResponse : (NSError *) error
{
	if (!error) {
		getMediaResponse.data = data;
		NSLog(@"GetMedia: Got a good response - Size = %lu", (unsigned long)[getMediaResponse.data length]);
	} else {
		NSLog(@"GetMedia error: %@", error.localizedDescription);
	}
}

- (void)getMediaWithUserId: (NSString *) userId
					 token: (NSString *) token
				  fileName: (NSString *) fileName
				completion: (void (^)(GetMediaResponse *getMediaResponse, int *status)) completionHandler;
{
	NSString *url = [NSString stringWithFormat : @"%@/%@", GET_MEDIA_URL, fileName];
	
	LOGD(@"GetMedia enter: userId %@ token %@ fileName %@ URL %@", userId, token, fileName, url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Accept"];
	
	NSDate *now = [NSDate date];
	long nowEpochMSecs = (long) ([now timeIntervalSince1970]);
	[request setValue:[NSString stringWithFormat:@"%ld", nowEpochMSecs] forHTTPHeaderField:@"Date"];
	
	NSString *hash = [Secret getHash_GetMedia:userId token:token fileName:fileName epochTime:nowEpochMSecs];
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
		
		GetMediaResponse *getMediaResponse = [[GetMediaResponse alloc] init];
		error = nil;
		
		[GetMedia parseResponse : data : getMediaResponse : error];
		
		if (!error) {
			status = 0;
			if (completionHandler != nil) completionHandler (getMediaResponse, &status);
		} else {
			status = -4;
			if (completionHandler != nil) completionHandler (nil, &status);
		}
	}] resume];
}

+ (GetMedia *)instance {
	@synchronized(self) {
		if (getMedia == nil) {
			getMedia = [[GetMedia alloc] init];
		}
	}
	return getMedia;
}

@end
