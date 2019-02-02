/*
 *  SmsContactsTableView.m
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

#import "SmsContactsCreateView.h"
#import "SmsContactsTableView.h"
#import "UIContactCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"

@implementation SmsContactsTableView
NSArray *snrbSortedAddresses;

#pragma mark - Lifecycle Functions

- (void)initContactsTableViewController {
	addressBookMap = [[OrderedDictionary alloc] init];
	snrbSortedAddresses = [[NSArray alloc] init];
        [NSNotificationCenter.defaultCenter
            addObserver:self
               selector:@selector(onAddressBookUpdate:)
                   name:kLinphoneAddressBookUpdate
                 object:nil];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(onAddressBookUpdate:)
                   name:CNContactStoreDidChangeNotification
                 object:nil];
}

- (void)onAddressBookUpdate:(NSNotification *)k {
	if (!_ongoing && (PhoneMainView.instance.currentView == SmsContactsCreateView.compositeViewDescription)) {
		[self loadData];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initContactsTableViewController];
	}
	_ongoing = FALSE;
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initContactsTableViewController];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeAllContacts];
}

- (void)removeAllContacts {
	for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j) {
		for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i) {
			[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] setContact:nil];
		}
	}
}

#pragma mark -

static int ms_strcmpfuz(const char *fuzzy_word, const char *sentence) {
	if (!fuzzy_word || !sentence) {
		return fuzzy_word == sentence;
	}
	const char *c = fuzzy_word;
	const char *within_sentence = sentence;
	for (; c != NULL && *c != '\0' && within_sentence != NULL; ++c) {
		within_sentence = strchr(within_sentence, *c);
		// Could not find c character in sentence. Abort.
		if (within_sentence == NULL) {
			break;
		}
		// since strchr returns the index of the matched char, move forward
		within_sentence++;
	}

	// If the whole fuzzy was found, returns 0. Otherwise returns number of characters left.
	return (int)(within_sentence != NULL ? 0 : fuzzy_word + strlen(fuzzy_word) - c);
}

- (NSString *)displayNameForContact:(Contact *)person {
	NSString *name = person.displayName;
	if (name != nil && [name length] > 0 && ![name isEqualToString:NSLocalizedString(@"Unknown", nil)]) {
		// Add the contact only if it fuzzy match filter too (if any)
		if ([SmsContactSelection getNameOrEmailFilter] == nil ||
			(ms_strcmpfuz([[[SmsContactSelection getNameOrEmailFilter] lowercaseString] UTF8String],
						  [[name lowercaseString] UTF8String]) == 0)) {

			// Sort contacts by first letter. We need to translate the name to ASCII first, because of UTF-8
			// issues. For instance expected order would be:  Alberta(A tilde) before ASylvano.
			NSData *name2ASCIIdata = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			NSString *name2ASCII = [[NSString alloc] initWithData:name2ASCIIdata encoding:NSASCIIStringEncoding];
			return name2ASCII;
		}
	}
	return nil;
}

- (void)loadData {
	_ongoing = TRUE;
	LOGI(@"loadData: Load contact list - Start");
	NSString* previous = [PhoneMainView.instance  getPreviousViewName];
	addressBookMap = [LinphoneManager.instance getLinphoneManagerAddressBookMap];
	BOOL updated = [LinphoneManager.instance getContactsUpdated];
	if(([previous isEqualToString:@"ContactsDetailsView"] && updated) || updated || [addressBookMap count] == 0){
		[LinphoneManager.instance setContactsUpdated:FALSE];
		@synchronized(addressBookMap) {
			NSDictionary *allContacts = [[NSMutableDictionary alloc] initWithDictionary:LinphoneManager.instance.fastAddressBook.addressBookMap];
			snrbSortedAddresses = [[LinphoneManager.instance.fastAddressBook.addressBookMap allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
				Contact* first =  [allContacts objectForKey:a];
				Contact* second =  [allContacts objectForKey:b];
				if([[first.firstName lowercaseString] compare:[second.firstName lowercaseString]] == NSOrderedSame)
					return [[first.lastName lowercaseString] compare:[second.lastName lowercaseString]];
				else
					return [[first.firstName lowercaseString] compare:[second.firstName lowercaseString]];
			}];
			
			//Set all contacts from ContactCell to nil
			for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j){
				for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
				{
					[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] setContact:nil];
				}
			}
			
			// Reset Address book
			[addressBookMap removeAllObjects];
			for (NSString *addr in snrbSortedAddresses) {
				Contact *contact = nil;
				@synchronized(LinphoneManager.instance.fastAddressBook.addressBookMap) {
					contact = [LinphoneManager.instance.fastAddressBook.addressBookMap objectForKey:addr];
				}
				BOOL add = true;
				NSMutableString *name = [self displayNameForContact:contact] ? [[NSMutableString alloc] initWithString: [self displayNameForContact:contact]] : nil;
				if (add && name != nil) {
					NSString *firstChar = [[name substringToIndex:1] uppercaseString];
					// Put in correct subAr
					if ([firstChar characterAtIndex:0] < 'A' || [firstChar characterAtIndex:0] > 'Z') {
						firstChar = @"#";
					}
					NSMutableArray *subAr = [addressBookMap objectForKey:firstChar];
					if (subAr == nil) {
						subAr = [[NSMutableArray alloc] init];
						[addressBookMap insertObject:subAr forKey:firstChar selector:@selector(caseInsensitiveCompare:)];
					}
					NSUInteger idx = [subAr indexOfObject:contact inSortedRange:(NSRange){0, subAr.count} options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult( Contact *_Nonnull obj1, Contact *_Nonnull obj2) {
							return [[self displayNameForContact:obj1] compare:[self displayNameForContact:obj2] options:NSCaseInsensitiveSearch];
					}];
					if (![subAr containsObject:contact]) {
						[subAr insertObject:contact atIndex:idx];
					}
				}
			}
		}
		[LinphoneManager.instance setLinphoneManagerAddressBookMap:addressBookMap];
	}
	[super loadData];
	_ongoing = FALSE;
}

- (void)loadSearchedData {
	@synchronized(addressBookMap) {
		//Set all contacts from ContactCell to nil
		for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j)
		{
			for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
			{
				[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] setContact:nil];
			}
		}
		// Reset Address book
		[addressBookMap removeAllObjects];
		NSString *filter = [SmsContactSelection getNameOrEmailFilter];
		LOGI(@"loadSearchedData: Load filtered contact list - Filter %@", filter);
		NSMutableArray *subAr = [NSMutableArray new];
		NSMutableArray *subArBegin = [NSMutableArray new];
		NSMutableArray *subArContain = [NSMutableArray new];
		[addressBookMap insertObject:subAr forKey:@"" selector:@selector(caseInsensitiveCompare:)];
		for (NSString *addr in snrbSortedAddresses) {
                  @synchronized(
                      LinphoneManager.instance.fastAddressBook.addressBookMap) {
                    Contact *contact =
                        [LinphoneManager.instance.fastAddressBook.addressBookMap
                            objectForKey:addr];

                    NSInteger idx_begin = -1;
                    NSInteger idx_sort = -1;
                    NSMutableString *name =
                        [self displayNameForContact:contact]
                            ? [[NSMutableString alloc]
                                  initWithString:
                                      [self displayNameForContact:contact]]
                            : nil;
                    if (name != nil) {
                      if ([[contact displayName]
                              rangeOfString:filter
                                    options:NSCaseInsensitiveSearch]
                              .location == 0) {
                        if (![subArBegin containsObject:contact]) {
                          idx_begin = idx_begin + 1;
                          [subArBegin insertObject:contact atIndex:idx_begin];
                        }
                      } else if ([[contact displayName]
                              rangeOfString:filter
                                    options:NSCaseInsensitiveSearch]
                              .location != NSNotFound) {
                        if (![subArContain containsObject:contact]) {
                          idx_sort = idx_sort + 1;
                          [subArContain insertObject:contact atIndex:idx_sort];
                        }
                      }
                    }
                    if ([addr rangeOfString:filter options:NSCaseInsensitiveSearch].location == 0) {
                      if (![subArBegin containsObject:contact]) {
                        idx_begin = idx_begin + 1;
                        [subArBegin insertObject:contact atIndex:idx_begin];
                      }
                    }
                    else if ([addr rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
                      if (![subArContain containsObject:contact]) {
                        idx_sort = idx_sort + 1;
                        [subArContain insertObject:contact atIndex:idx_sort];
                      }
                    }
                  }
                }
                if (([filter hasPrefix:@"+"] ||
                    [filter hasPrefix:@"0"] || [filter hasPrefix:@"1"] ||
                    [filter hasPrefix:@"2"] || [filter hasPrefix:@"3"] ||
                    [filter hasPrefix:@"4"] || [filter hasPrefix:@"5"] ||
                    [filter hasPrefix:@"6"] || [filter hasPrefix:@"7"] ||
                    [filter hasPrefix:@"8"] || [filter hasPrefix:@"9"]) ||
                    ((subArBegin.count == 0) && (subArContain.count == 0))) {
                  Contact *contact = [[Contact alloc] init];
                  [contact setPhoneNumber:filter atIndex:0];
                  [contact setFirstName:filter];
                  [subArContain addObject:contact];
                }
                [subArBegin
                    sortUsingComparator:^NSComparisonResult(
                        Contact *_Nonnull obj1, Contact *_Nonnull obj2) {
                      return [[self displayNameForContact:obj1]
                          compare:[self displayNameForContact:obj2]
                          options:NSCaseInsensitiveSearch];
                    }];

                [subArContain
                    sortUsingComparator:^NSComparisonResult(
                        Contact *_Nonnull obj1, Contact *_Nonnull obj2) {
                      return [[self displayNameForContact:obj1]
                          compare:[self displayNameForContact:obj2]
                          options:NSCaseInsensitiveSearch];
                    }];

                [subAr addObjectsFromArray:subArBegin];
                [subAr addObjectsFromArray:subArContain];
                [super loadData];
        }
}


#pragma mark - UITableViewDataSource Functions

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [addressBookMap allKeys];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [addressBookMap count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(OrderedDictionary *)[addressBookMap objectForKey:[addressBookMap keyAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *kCellId = NSStringFromClass(UIContactCell.class);
	UIContactCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIContactCell alloc] initWithIdentifier:kCellId];
	}
	NSMutableArray *subAr = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
	Contact *contact = subAr[indexPath.row];

	// Cached avatar
	UIImage *image = [FastAddressBook imageForContact:contact];
	[cell.avatarImage setImage:image bordered:NO withRoundedRadius:YES];
	[cell setContact:contact];
	[super accessoryForCell:cell atPath:indexPath];

	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, tableView.frame.size.width, tableView.sectionHeaderHeight);
	UIView *tempView = [[UIView alloc] initWithFrame:frame];
	tempView.backgroundColor = [UIColor whiteColor];

	UILabel *tempLabel = [[UILabel alloc] initWithFrame:frame];
	tempLabel.backgroundColor = [UIColor clearColor];
	tempLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"color_A.png"]];
	tempLabel.text = [addressBookMap keyAtIndex:section];
	tempLabel.textAlignment = NSTextAlignmentCenter;
	tempLabel.font = [UIFont boldSystemFontOfSize:17];
	tempLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[tempView addSubview:tempLabel];

	return tempView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	if (![self isEditing]) {
		NSMutableArray *subAr = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
		Contact *contact = subAr[indexPath.row];

		LOGD(@"SmsContactsTableView - didSelectRowAtIndexPath: Phone# count = %d", contact.phones.count);
		// Go to Contact details view
		ContactDetailsView *view = VIEW(ContactDetailsView);
		[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
		if (([SmsContactSelection getSelectionMode] != SmsContactSelectionModeEdit) || !([SmsContactSelection getAddAddress])) {
			[view setContact:contact];
		} else {
			[view editContact:contact address:[SmsContactSelection getAddAddress]];
		}
	}
}

- (void)tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	 forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[NSNotificationCenter.defaultCenter removeObserver:self];
		[tableView beginUpdates];

		NSString *firstChar = [addressBookMap keyAtIndex:[indexPath section]];
		NSMutableArray *subAr = [addressBookMap objectForKey:firstChar];
		Contact *contact = subAr[indexPath.row];
		[subAr removeObjectAtIndex:indexPath.row];
		if (subAr.count == 0) {
			[addressBookMap removeObjectForKey:firstChar];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
					 withRowAnimation:UITableViewRowAnimationFade];
		}
		UIContactCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
		[cell setContact:NULL];
		[[LinphoneManager.instance fastAddressBook] deleteContact:contact];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];

		[NSNotificationCenter.defaultCenter	addObserver:self selector:@selector(onAddressBookUpdate:)
                           name:kLinphoneAddressBookUpdate
                         object:nil];
	   	[self loadData];
	}
}

- (void)removeSelectionUsing:(void (^)(NSIndexPath *))remover {
	[super removeSelectionUsing:^(NSIndexPath *indexPath) {
	  [NSNotificationCenter.defaultCenter removeObserver:self];

	  NSString *firstChar = [addressBookMap keyAtIndex:[indexPath section]];
	  NSMutableArray *subAr = [addressBookMap objectForKey:firstChar];
	  Contact *contact = subAr[indexPath.row];
	  [subAr removeObjectAtIndex:indexPath.row];
	  if (subAr.count == 0) {
		  [addressBookMap removeObjectForKey:firstChar];
	  }
	  UIContactCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	  [cell setContact:NULL];
	  [[LinphoneManager.instance fastAddressBook] deleteContact:contact];

	  [NSNotificationCenter.defaultCenter addObserver:self
                 selector:@selector(onAddressBookUpdate:)
                     name:kLinphoneAddressBookUpdate
                   object:nil];
	}];
}

- (IBAction)onBackClick:(id)sender {
	[PhoneMainView.instance popToView:ChatsListView.compositeViewDescription];
}

@end
