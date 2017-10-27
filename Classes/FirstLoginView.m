/* FirstLoginViewController.m
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "LinphoneManager.h"
#import "FirstLoginView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils/XMLRPCHelper.h"

#import "LinphoneAppDelegate.h"
#import "LoginManager.h"
#import "LoginResponse.h"
#import "CreateArn.h"
#import "GenericResponse.h"

@implementation FirstLoginView

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
	NSString *siteUrl =
		[[LinphoneManager instance] lpConfigStringForKey:@"first_login_view_url"] ?: @"http://www.linphone.org";
	[_siteButton setTitle:siteUrl forState:UIControlStateNormal];
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
	
#if 1	// Changed Linphone code - Clear username and password fields
	_usernameField.text = @"";
	_passwordField.text = @"";
#endif

	// Update on show
	const MSList *list = linphone_core_get_proxy_config_list([LinphoneManager getLc]);
	if (list != NULL) {
		LinphoneProxyConfig *config = (LinphoneProxyConfig *)list->data;
		if (config) {
			[self registrationUpdate:linphone_proxy_config_get_state(config)];
		}
	}

	if (account_creator) {
		linphone_account_creator_unref(account_creator);
	}
	NSString *siteUrl =
		[[LinphoneManager instance] lpConfigStringForKey:@"first_login_view_url"] ?: @"http://www.linphone.org";
	account_creator = linphone_account_creator_new([LinphoneManager getLc], siteUrl.UTF8String);

	[_usernameField
		showError:[AssistantView
					  errorForLinphoneAccountCreatorUsernameStatus:LinphoneAccountCreatorUsernameStatusInvalid]
			 when:^BOOL(NSString *inputEntry) {
			   LinphoneAccountCreatorUsernameStatus s =
				   linphone_account_creator_set_username(account_creator, inputEntry.UTF8String);
			   _usernameField.errorLabel.text = [AssistantView errorForLinphoneAccountCreatorUsernameStatus:s];
			   return s != LinphoneAccountCreatorUsernameStatusOk;
			 }];

	[_passwordField
		showError:[AssistantView
					  errorForLinphoneAccountCreatorPasswordStatus:LinphoneAccountCreatorPasswordStatusTooShort]
			 when:^BOOL(NSString *inputEntry) {
			   LinphoneAccountCreatorPasswordStatus s =
				   linphone_account_creator_set_password(account_creator, inputEntry.UTF8String);
			   _passwordField.errorLabel.text = [AssistantView errorForLinphoneAccountCreatorPasswordStatus:s];
			   return s != LinphoneAccountCreatorUsernameStatusOk;
			 }];
	
#if 0	// Changed Linphone code - We don't want user to enter the domain name
	 [_domainField
		showError:[AssistantView errorForLinphoneAccountCreatorDomainStatus:LinphoneAccountCreatorDomainInvalid]
	 when:^BOOL(NSString *inputEntry) {
	 LinphoneAccountCreatorDomainStatus s =
	 linphone_account_creator_set_domain(account_creator, inputEntry.UTF8String);
	 _domainField.errorLabel.text = [AssistantView errorForLinphoneAccountCreatorDomainStatus:s];
	 return s != LinphoneAccountCreatorDomainOk;
	 }];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneRegistrationUpdate object:nil];
}

- (void)shouldEnableNextButton {
	BOOL invalidInputs = NO;
	for (UIAssistantTextField *field in @[ _usernameField, _passwordField/*, _domainField*/ ]) {
		invalidInputs |= (field.isInvalid || field.lastText.length == 0);
	}
	_loginButton.enabled = !invalidInputs;
}

#pragma mark - Event Functions

- (void)configureStateUpdateEvent:(NSNotification *)notif {
	LinphoneConfiguringState state = [[notif.userInfo objectForKey:@"state"] intValue];
	switch (state) {
		case LinphoneConfiguringFailed: {
			[_waitView setHidden:true];
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
	if (account_creator) {
		linphone_account_creator_unref(account_creator);
	}
	NSString *siteUrl =
		[[LinphoneManager instance] lpConfigStringForKey:@"first_login_view_url"] ?: @"http://www.linphone.org";
	account_creator = linphone_account_creator_new([LinphoneManager getLc], siteUrl.UTF8String);
}

- (void)registrationUpdateEvent:(NSNotification *)notif {
	[self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue]];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state {
	switch (state) {
		case LinphoneRegistrationOk: {
			[[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"enable_first_login_view_preference"];
			[_waitView setHidden:true];
			[PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
			break;
		}
		case LinphoneRegistrationNone:
		case LinphoneRegistrationCleared: {
			[_waitView setHidden:true];
			break;
		}
		case LinphoneRegistrationFailed: {
			[_waitView setHidden:true];
			break;
		}
		case LinphoneRegistrationProgress: {
			[_waitView setHidden:false];
			break;
		}
		default:
			break;
	}
}

- (void)displayLoginManagerError: (int) errorCode {
	NSString *errorMessage;
	switch (errorCode) {
		case 400:
			errorMessage = [NSString stringWithFormat:@"No account found for the credentials you have entered. (Code %i)", errorCode];
			break;
		case 403:
			errorMessage = [NSString stringWithFormat:@"Authentication failure. Please try again later. If the issue continues, please contact us. (Code %i)", errorCode];
			break;
		case 404:
			errorMessage = [NSString stringWithFormat:@"Resource not found. Please try again later. If the issue continues, please contact us. (Code %i)", errorCode];
			break;
		case 500:
			errorMessage = [NSString stringWithFormat:@"Internal server error. Please try again later. If the issue continues, please contact us. (Code %i)", errorCode];
			break;
		default:
			errorMessage = [NSString stringWithFormat:@"Unknown error. Please try again later. If the issue continues, please contact us. (Code %i)", errorCode];
			break;
	}
	UIAlertController *errView = [UIAlertController
								  alertControllerWithTitle:NSLocalizedString(@"Login error", nil)
								  message:NSLocalizedString(errorMessage, nil)
								  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
															style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction *action){
														  }];
	
	[errView addAction:defaultAction];
	[self presentViewController:errView animated:YES completion:nil];
	_waitView.hidden = YES;
	return;
}

#pragma mark - Action Functions

- (void)onSiteClick:(id)sender {
	NSURL *url = [NSURL URLWithString:_siteButton.titleLabel.text];
	[[UIApplication sharedApplication] openURL:url];
	return;
}

- (void)onLoginClick:(id)sender {
	if (!linphone_core_is_network_reachable(LC)) {
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Network Error", nil)
																		 message:NSLocalizedString(@"There is no network connection available, enable "
																								   @"WIFI or WWAN prior to configure an account",
																								   nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[errView addAction:defaultAction];
		[self presentViewController:errView animated:YES completion:nil];
		return;
	}
	_waitView.hidden = NO;
	LinphoneProxyConfig *config = linphone_core_create_proxy_config(LC);
	NSString *email = _usernameField.text;
	
	LoginManager * loginManager = [LoginManager instance];
	[loginManager loginWithEmail:email password:_passwordField.text completion:^(LoginResponse *loginResponse, int *status) {
		int errorCode = *status;
		if (0 != errorCode) {
			NSLog(@"Error: %d", errorCode);
			dispatch_async(dispatch_get_main_queue(), ^{
				[self displayLoginManagerError : errorCode];
			});
			return;
		}
		
		int userId = loginResponse.userId;
		NSString *token = loginResponse.token;
		NSString *phoneNumber = loginResponse.phoneNumber;
		NSString *sipName = loginResponse.sipName;
		NSString *sipPassword = loginResponse.sipPassword;
		NSString *sipServer = loginResponse.sipServer;
		NSString *transport = @"TCP";	// Hard-code for now
		
		LOGD(@"LoginResponse: %d %@ %@ %@ %@ %@", userId, token, phoneNumber, sipName, sipPassword, sipServer);
		
		// Received 200 OK
		NSString *userIdString = [NSString stringWithFormat:@"%d", userId];
		const char *temp = [userIdString UTF8String];
		linphone_proxy_config_set_snrblabs_userid(config, temp);
		temp = [token UTF8String];
		linphone_proxy_config_set_snrblabs_token(config, temp);
		temp = [email UTF8String];
		linphone_proxy_config_set_snrblabs_email(config, temp);
		LinphoneAddress *addr =
		linphone_address_new([NSString stringWithFormat:@"sip:%@@%@", sipName, sipServer].UTF8String);
		if (phoneNumber && ![phoneNumber isEqualToString:@""]) {
			linphone_address_set_display_name(addr, phoneNumber.UTF8String);
		}
		linphone_proxy_config_set_identity_address(config, addr);
		
		linphone_proxy_config_set_route(
										config,
										[NSString stringWithFormat:@"%s;transport=%s", sipServer.UTF8String, transport.lowercaseString.UTF8String]
										.UTF8String);
		linphone_proxy_config_set_server_addr(
											  config,
											  [NSString stringWithFormat:@"%s;transport=%s", sipServer.UTF8String, transport.lowercaseString.UTF8String]
											  .UTF8String);
		
		linphone_proxy_config_enable_publish(config, FALSE);
		linphone_proxy_config_enable_register(config, TRUE);
		
		LinphoneAuthInfo *info =
		linphone_auth_info_new(linphone_address_get_username(addr), // username
							   NULL,								// user id
							   sipPassword.UTF8String,				// passwd
							   NULL,								// ha1
							   linphone_address_get_domain(addr),   // realm - assumed to be domain
							   linphone_address_get_domain(addr)	// domain
							   );
		linphone_core_add_auth_info(LC, info);
		LOGD(@"onLoginClick - info from config: UserId %s Token %s",
			 linphone_proxy_config_get_snrblabs_userid(config),
			 linphone_proxy_config_get_snrblabs_token(config));
		linphone_address_unref(addr);
		
		if (config) {
			[[LinphoneManager instance] configurePushTokenForProxyConfig:config];
			if (linphone_core_add_proxy_config(LC, config) != -1) {
				linphone_core_set_default_proxy_config(LC, config);
				// reload address book to prepend proxy config domain to contacts' phone number
				// todo: STOP doing that!
				[[LinphoneManager.instance fastAddressBook] reload];
				dispatch_async(dispatch_get_main_queue(), ^{
					[PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
				});
			} else {
				errorCode = -11;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self displayLoginManagerError : errorCode];
				});
				return;
			}
		} else {
			errorCode = -12;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self displayLoginManagerError : errorCode];
			});
			return;
		}
		
		if (LinphoneAppDelegate.newDeviceToken != NULL) {
			CreateArn *createArn = [CreateArn instance];
			[createArn createArnWithUserId:userIdString token:token deviceToken:LinphoneAppDelegate.newDeviceToken serviceType:SERVICE_TYPE_APPLE
								completion:^(GenericResponse *genericResponse, int *status) {
				if (0 != *status) {
					NSLog(@"Create ARN error: %d", *status);
				} else {
					// Received 200 OK
					const char *temp = [LinphoneAppDelegate.newDeviceToken UTF8String];
					LOGD(@"onLoginClick: Save DeviceToken: %s", temp);
					linphone_proxy_config_set_snrblabs_devicetoken(config, temp);
					linphone_proxy_config_done(config);
				}
			}];
		}
	}];
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	if (textField.returnKeyType == UIReturnKeyNext) {
		if (textField == _usernameField) {
			[_domainField becomeFirstResponder];
#if 0	// Changed Linphone code - We don't want user to enter the domain name
		} else if (textField == _domainField) {
			[_passwordField becomeFirstResponder];
#endif
		}
	} else if (textField.returnKeyType == UIReturnKeyDone) {
		[_loginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	}

	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	UIAssistantTextField *atf = (UIAssistantTextField *)textField;
	[atf textFieldDidEndEditing:atf];
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	UIAssistantTextField *atf = (UIAssistantTextField *)textField;
	[atf textField:atf shouldChangeCharactersInRange:range replacementString:string];
	[self shouldEnableNextButton];
	return YES;
}

@end
