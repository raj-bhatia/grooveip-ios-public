/*
 *  PushResponseManager.h
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

#ifndef PushResponseManager_h
#define PushResponseManager_h

#import "GenericResponse.h"

@interface PushResponseManager:NSObject

- (void)pushResponseManagerWithUserId: (NSString *) userId
								token: (NSString *) token
							   callId: (NSString *) callId
								route: (NSString *) route
						   completion: (void (^)(GenericResponse *genericResponse, int *status)) completionHandler;

+ (PushResponseManager *) instance;

#endif /* PushResponseManager_h */

@end

