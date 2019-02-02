/*
 *  MyContact.m
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

#import "MyContact.h"
#import "PhoneMainView.h"

@implementation MyContact

+ (NSString *) findContactName : (NSString *) phoneNumber
{
	Contact *contact = [FastAddressBook getContact : phoneNumber];
	if (contact) {
		NSString *name = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
		LOGD(@"findContact: Found a record with phone number %@, Name %@", phoneNumber, name);
		return name;
	} else {
		LOGD(@"findContact: No record found with phone number = %@", phoneNumber);
		return nil;
	}
}

+ (BOOL) isContactPresent : (NSString *) phoneNumber
{
	Contact *contact = [FastAddressBook getContact : phoneNumber];
	if (nil == contact) {
		LOGD(@"isContactPresent: No record found with phone number = %@", phoneNumber);
		return FALSE;
	} else {
		LOGD(@"isContactPresent: Found a record with phone number = %@, display name %@", phoneNumber, contact.displayName);
		return TRUE;
	}
}

+ (BOOL) createMyNewContact : (NSString *) myNumber showWarning : (BOOL) showWarning
{
	LOGD(@"createMyNewContact - Enter: Phone number = %@", myNumber);
	
	CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
	if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
		if (TRUE == showWarning) {
			UIAlertController *errView = [UIAlertController
									  alertControllerWithTitle:NSLocalizedString(@"Access to Contacts", nil)
									  message:NSLocalizedString(@"To provide a user-friendly experience, this app requires access to your contacts. Please go to Settings and give Contacts permission to ONE-Phone. Then restart ONE-Phone.", nil)
									  preferredStyle:UIAlertControllerStyleAlert];
		
			UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction *action){
															  }];
		
			[errView addAction:defaultAction];
			[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
		}
		return FALSE;
	}

	CNContactStore *store = [[CNContactStore alloc] init];
	CNMutableContact *contact = [[CNMutableContact alloc] init];
	NSString *notes = @"Please don't delete or block this contact! It is used by ONE-Phone for call management.";
	NSString *firstName = @"ONE-Phone";
	NSString *lastName = @"";
	NSString *company = @"via ONE-Phone";
	NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"LauncherIcon_default.png"], 1.0f);

	contact.givenName = firstName;
	contact.familyName = lastName;
	contact.organizationName = company;
	contact.note = notes;
	contact.imageData = imageData;

	CNLabeledValue *phone = [CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberMain value:[CNPhoneNumber phoneNumberWithStringValue:myNumber]];
	contact.phoneNumbers = @[phone];

	@try {
		CNSaveRequest *request = [[CNSaveRequest alloc] init];
		[request addContact:contact toContainerWithIdentifier:nil];

		NSError *error;
		if (![store executeSaveRequest:request error:&error]) {
			LOGD(@"createMyNewContact - Error: Phone number = %@ Error %@", myNumber, error);
			return FALSE;
		} else {
			LOGD(@"createMyNewContact - New contact created for phone number = %@", myNumber);
			return TRUE;
		}
	} @catch (NSException *exception) {
		LOGD(@"createMyNewContact - CNContact addContact or SaveRequest failed: Description = %@", [exception description]);
		return FALSE;
	}
}

+ (BOOL) updateMyContact : (NSString *) myNumber
			 phoneNumber : (NSString *) phoneNumber
{
	NSString *name = [MyContact findContactName : phoneNumber];
	if (nil == name) {
		name = phoneNumber;
	}
	
	LOGD(@"updateMyContact: My number = %@ Phone number = %@ Name = %@", myNumber, phoneNumber, name);
	
	Contact *contact = [FastAddressBook getContact : myNumber];
	if (contact) {
		contact.firstName = name;
		[LinphoneManager.instance.fastAddressBook saveContactWithoutReload:contact];
		LOGD(@"updateMyContact: My record with phone number %@ updated with Name %@", myNumber, name);
		return TRUE;
	} else {
		LOGD(@"updateMyContact: No record found with my phone number = %@", myNumber);
		return FALSE;
	}
}

+ (BOOL) resetMyContact : (NSString *) myNumber
{
	LOGD(@"resetMyContact - Enter: My number = %@", myNumber);

	Contact *contact = [FastAddressBook getContact : myNumber];
	if (contact) {
		contact.firstName = @"ONE-Phone";
		[LinphoneManager.instance.fastAddressBook saveContactWithoutReload:contact];
		LOGD(@"resetMyContact: My record with phone number %@ updated with default name", myNumber);
		return TRUE;
	} else {
		LOGD(@"resetMyContact: No record found with my phone number = %@", myNumber);
		return FALSE;
	}
}

@end
