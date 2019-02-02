/*
 *  CreateArn.h
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

#ifndef CreateArn_h
#define CreateArn_h

#import "GenericResponse.h"

#define SERVICE_TYPE_APPLE @"APN"	// Service type for GrooVe IP on Apple iPhone

@interface CreateArn:NSObject

- (void)createArnWithUserId: (NSString *) userId
					  token: (NSString *) token
				deviceToken: (NSString *) deviceToken
				serviceType: (NSString *) serviceType
		   completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;

+ (CreateArn *) instance;

@end

#endif /* CreateArn_h */
