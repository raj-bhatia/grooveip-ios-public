/*
 *  MyContact.h
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

#ifndef MyContact_h
#define MyContact_h

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "Contact.h"

@interface MyContact : NSObject

+ (NSString *) findContactName : (NSString *) phoneNumber;
+ (BOOL) isContactPresent : (NSString *) phoneNumber;
+ (BOOL) createMyNewContact : (NSString *) myNumber showWarning : (BOOL) showWarning;
+ (BOOL) updateMyContact : (NSString *) myNumber phoneNumber : (NSString *) phoneNumber;
+ (BOOL) resetMyContact : (NSString *) myNumber;

@end

#endif /* MyContact_h */
