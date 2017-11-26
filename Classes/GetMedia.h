/*
 *  GetMedia.h
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

#ifndef GetMedia_h
#define GetMedia_h

#import "GetMediaResponse.h"

@interface GetMedia:NSObject

- (void)getMediaWithUserId: (NSString *) userId
					 token: (NSString *) token
				  fileName: (NSString *) fileName
				completion: (void (^)(GetMediaResponse *getMediaResponse, int *status)) completionHandler;

+ (GetMedia *) instance;
@end

#endif /* GetMedia_h */
