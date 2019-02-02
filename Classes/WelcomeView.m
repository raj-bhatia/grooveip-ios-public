/*
 *  WelcomeView.m
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

#import "WelcomeView.h"
#import "VerifyView.h"
#import "LoginView.h"
#import "MyContact.h"
#import "Secret.h"
#import "SafariView.h"

@implementation WelcomeView

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

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(registrationUpdateEvent:)
												 name:kLinphoneRegistrationUpdate
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(configureStateUpdateEvent:)
												 name:kLinphoneConfiguringStateUpdate
											   object:nil];
	
	_signupButton.enabled = YES;
	_loginButton.enabled = YES;
	[_activityIndicator stopAnimating];

	// Update on show
	const MSList *list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
	if (list != NULL) {
		LinphoneProxyConfig *config = (LinphoneProxyConfig *)list->data;
		if (config) {
			[self registrationUpdate:linphone_proxy_config_get_state(config)];
			_signupButton.enabled = NO;
			_loginButton.enabled = NO;
		}
	}

	if ((NO == _signupButton.enabled) || (NO == _loginButton.enabled)) {
		[_activityIndicator startAnimating];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneRegistrationUpdate object:nil];
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

#pragma mark - Event Functions

- (void)configureStateUpdateEvent:(NSNotification *)notif {
	LinphoneConfiguringState state = [[notif.userInfo objectForKey:@"state"] intValue];
	switch (state) {
		case LinphoneConfiguringFailed: {
			[_activityIndicator stopAnimating];
			UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Configuration failed", nil)
																			 message:NSLocalizedString(@"Cannot retrieve your configuration. Please check credentials or try again later", nil)
																	  preferredStyle:UIAlertControllerStyleAlert];
			
			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
																	style:UIAlertActionStyleDefault
																  handler:^(UIAlertAction * action) {}];
			
			[errView addAction:defaultAction];
			[self presentViewController:errView animated:YES completion:nil];
			linphone_core_set_provisioning_uri([LinphoneManager getLc], NULL);
			break;
		}
		default:
			break;
	}
}

- (void)registrationUpdateEvent:(NSNotification *)notif {
	LinphoneRegistrationState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self registrationUpdate : state];
}
	
- (void)registrationUpdate:(LinphoneRegistrationState)state {
	switch (state) {
		case LinphoneRegistrationOk: {
			[[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"enable_first_login_view_preference"];
			[_activityIndicator stopAnimating];
			[PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
			break;
		}
		case LinphoneRegistrationNone:
		case LinphoneRegistrationCleared: {
			[_activityIndicator stopAnimating];
			break;
		}
		case LinphoneRegistrationFailed: {
			[_activityIndicator stopAnimating];
			break;
		}
		case LinphoneRegistrationProgress: {
			[_activityIndicator startAnimating];
			break;
		}
		default:
			break;
	}
}

- (IBAction)signupButtonClick:(id)sender {
	NSString *message = @"You will now be taken to the SNRB Labs portal where you can create a new account and get a phone number. Please note the GrooVe IP App Login Credentials (User ID and Password) corresponding to the phone number you choose. When you return from the portal, LOG IN to the app using these credentials.";
	UIAlertController *errView = [UIAlertController
							alertControllerWithTitle:NSLocalizedString(@"GrooVe IP Sign Up", nil)
							message:NSLocalizedString(message, nil)
							preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Proceed", nil)
							style:UIAlertActionStyleDefault
							handler:^(UIAlertAction *action) {
								SafariView.safariUrl = (PORTAL_URL @"/Register/CustomerInfo");
								[PhoneMainView.instance changeCurrentView:SafariView.compositeViewDescription];
							}];
	[errView addAction:defaultAction];
	[self presentViewController:errView animated:YES completion:nil];
}

- (IBAction)loginButtonClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:LoginView.compositeViewDescription];
}

@end
