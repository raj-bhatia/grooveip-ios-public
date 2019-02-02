/*
 *  OutgoingCallView.m
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

#import "OutgoingCallView.h"
#import "MyContact.h"

@implementation OutgoingCallView

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:nil
																 tabBar:nil
															   sideMenu:nil
															 fullscreen:false
														 isLeftFragment:YES
														   fragmentWith:nil];
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	LOGD(@"OutgoingCallView: viewWillAppear");
	
	LinphoneProxyConfig *config = linphone_core_get_default_proxy_config(LC);
	const LinphoneAddress *addr = linphone_proxy_config_get_identity_address(config);
	NSString *myNumber = [FastAddressBook displayNameForAddress:addr];
	NSString *phoneNumber = LinphoneAppDelegate.outgoingPhoneNumber;
	
	NSString *telUrl = [NSString stringWithFormat:@"tel://%@", myNumber];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString : telUrl]];
	
	NSDate *now = [NSDate date];
	LinphoneAppDelegate.outgoingCallStartTime = (long) ([now timeIntervalSince1970]);
	
	NSString *name = [MyContact findContactName : phoneNumber];
	if (nil == name) {
		name = phoneNumber;
	}
	self.callingText.text = [NSString stringWithFormat:@"Calling:  %@", name];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
	[self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
