/*
 *  SmsContactsCreateView.h
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

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "SmsContactsTableView.h"
#import "UIIconButton.h"

typedef enum _SmsContactSelectionMode { SmsContactSelectionModeNone, SmsContactSelectionModeEdit } SmsContactSelectionMode;

@interface SmsContactSelection : NSObject <UISearchBarDelegate> {
}

+ (void)setSelectionMode:(SmsContactSelectionMode)selectionMode;
+ (SmsContactSelectionMode)getSelectionMode;
+ (void)setAddAddress:(NSString *)address;
+ (NSString *)getAddAddress;

/*!
 * Weither always keep contacts with an email address or not.
 * @param enable TRUE if you want to always keep contacts with an email.
 */
+ (void)enableEmailFilter:(BOOL)enable;

/*!
 * Weither always keep contacts with an email address or not.
 * @return TRUE if this behaviour is enabled.
 */
+ (BOOL)emailFilterEnabled;

/*!
 * Filters contacts by name and/or email fuzzy matching pattern.
 * @param fuzzyName fuzzy word to match. Use nil to disable it.
 */
+ (void)setNameOrEmailFilter:(NSString *)fuzzyName;

/*!
 * Weither contacts are filtered by name and/or email.
 * @return the filter used, or nil if none.
 */
+ (NSString *)getNameOrEmailFilter;

@end

@interface SmsContactsCreateView : UIViewController <UICompositeViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>

@property(strong, nonatomic) IBOutlet SmsContactsTableView *tableController;
@property(strong, nonatomic) IBOutlet UIView *topBar;
@property(nonatomic, strong) IBOutlet UIButton *allButton;
@property(nonatomic, strong) IBOutlet UIButton *linphoneButton;
@property(nonatomic, strong) IBOutlet UIButton *addButton;
@property(strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property(weak, nonatomic) IBOutlet UIIconButton *deleteButton;
@property(weak, nonatomic) IBOutlet UIImageView *selectedButtonImage;

@end
