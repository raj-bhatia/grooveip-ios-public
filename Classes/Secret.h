/*
 *  Secret.h
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

#ifndef Secret_h
#define Secret_h

#define LOGIN_URL @"Your Login URL"
#define SMS_URL @"Your Sms URL"
#define CREATE_ARN_URL @"Your CreateArn URL"
#define UPDATE_TOKEN_URL @"Your UpdateToken URL"
#define PUSH_RESPONSE_URL @"Your PushResponse URL"

@interface Secret : NSObject

+ (NSString *) getHash_Login : (NSString *) email
					password : (NSString *) password
				   epochTime : (long) epochTime;

+ (NSString *) getHash_CreateArn : (NSString *) userId
						   token : (NSString *) token
					 serviceType : (NSString *) serviceType
					 deviceToken : (NSString *) deviceToken
					   epochTime : (long) epochTime;

+ (NSString *) getHash_UpdateToken : (NSString *) userId
							 token : (NSString *) token
					   serviceType : (NSString *) serviceType
					oldDeviceToken : (NSString *) oldDeviceToken
					newDeviceToken : (NSString *) newDeviceToken
						 epochTime : (long) epochTime;

+ (NSString *) getHash_Sms : (NSString *) userId
					 token : (NSString *) token
					  from : (NSString *) from
						to : (NSString *) to
					  text : (NSString *) text
				 epochTime : (long) epochTime;

+ (NSString *) getHash_PushResponse : (NSString *) userId
							  token : (NSString *) token
							 callId : (NSString *) callId
						  epochTime : (long) epochTime;

@end

#endif /* Secret_h */