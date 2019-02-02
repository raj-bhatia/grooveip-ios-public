/*
 *  RegisterApi.h
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

#ifndef RegisterApi_h
#define RegisterApi_h

#import "RegisterApiResponse.h"

@interface RegisterApi : NSObject

- (void) registerApiWithEmail : (NSString *) email
					 password : (NSString *) password
				  deviceToken : (NSString *) deviceToken
				  serviceType : (NSString *) serviceType
			 verificationCode : (NSString *) verificationCode
				 mobileNumber : (NSString *) mobileNumber
					timestamp : (int) timestamp
				   completion : (void (^) (RegisterApiResponse *registerApiResponse, int *status)) completionHandler;

+ (RegisterApi *) instance;

@end

#endif /* RegisterApi_h */
