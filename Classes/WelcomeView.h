/*
*  WelcomeView.h
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

#ifndef WelcomeView_h
#define WelcomeView_h

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "PhoneMainView.h"

@interface WelcomeView : TPMultiLayoutViewController <UICompositeViewDelegate>

@property (strong, nonatomic) IBOutlet UIButton *signupButton;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

#endif /* WelcomeView_h */