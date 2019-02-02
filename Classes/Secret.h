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
#define MMS_URL @"Your Mms URL"
#define PUT_MEDIA_URL @"Your PutMedia URL"
#define GET_MEDIA_URL @"Your GetMedia URL"
#define OUTGOING_CALL_URL @"Your OutgoingCall URL"
#define VERIFY_URL @"Your Verify URL"
#define REGISTER_URL @"Your Register URL"

#define PORTAL_URL @"Your Portal URL"
#define PAYPAL_URL @"Your PayPal URL (to purchase credits)"

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

+ (NSString *) getHash_Mms : (NSString *) userId
					 token : (NSString *) token
					  from : (NSString *) from
						to : (NSString *) to
					  text : (NSString *) text
				  fileName : (NSString *) fileName
				 epochTime : (long) epochTime;

+ (NSString *) getHash_PutMedia : (NSString *) userId
						  token : (NSString *) token
							 to : (NSString *) to
					   fileName : (NSString *) fileName
					  epochTime : (long) epochTime;

+ (NSString *) getHash_GetMedia : (NSString *) userId
						  token : (NSString *) token
					   fileName : (NSString *) fileName
					  epochTime : (long) epochTime;

+ (NSString *) getHash_OutgoingCall : (NSString *) userId
							  token : (NSString *) token
					   calledNumber : (NSString *) calledNumber
						  epochTime : (long) epochTime;

+ (NSString *) getHash_Verify : (NSString *) phoneNumber
					  string1 : (NSString *) string1
					  string2 : (NSString *) string2
					epochTime : (long) epochTime;

+ (NSString *) getHash_Register : (NSString *) email
					   password : (NSString *) password
					deviceToken : (NSString *) deviceToken
					serviceType : (NSString *) serviceType
			   verificationCode : (NSString *) verificationCode
				   mobileNumber : (NSString *) mobileNumber
						  delta : (int) delta
					  epochTime : (long) epochTime;

@end

#endif /* Secret_h */
