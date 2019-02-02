/*
 *  AreaCodeView.h
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

#ifndef AreaCodeView_h
#define AreaCodeView_h

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "PhoneMainView.h"

@interface AreaCodeView : TPMultiLayoutViewController <UITextFieldDelegate, UICompositeViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *areaCodeField;
@property (strong, nonatomic) IBOutlet UIButton *showButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

#endif /* AreaCodeView_h */
