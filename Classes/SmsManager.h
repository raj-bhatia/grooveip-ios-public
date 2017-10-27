/*
 *  SmsManager.h
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

#ifndef SmsManager_h
#define SmsManager_h

#import "SmsResponse.h"

@interface SmsManager:NSObject

- (void)smsWithUserId: (NSString *) userId
				token: (NSString *) token
				   to: (NSString *) to
				 from: (NSString *) from
				 text: (NSString *) text
		   completion: (void (^)(SmsResponse *smsResponse, int *status)) completionHandler;

+ (SmsManager *) instance;
@end

#endif /* SmsManager_h */
