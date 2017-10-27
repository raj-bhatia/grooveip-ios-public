/*
 *  UpdateToken.h
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

#ifndef UpdateToken_h
#define UpdateToken_h

#import "GenericResponse.h"

@interface UpdateToken:NSObject

- (void)updateTokenWithUserId: (NSString *) userId
						token: (NSString *) token
			   oldDeviceToken: (NSString *) oldDeviceToken
			   newDeviceToken: (NSString *) newDeviceToken
				  serviceType: (NSString *) serviceType
		   completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;

+ (UpdateToken *) instance;

@end

#endif /* UpdateToken_h */
