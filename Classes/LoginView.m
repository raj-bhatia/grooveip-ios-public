/*
 *  LoginView.m
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

#import "LoginView.h"
#import "WelcomeView.h"
#import "LoginManager.h"
#import "MyContact.h"
#import "CreateArn.h"
#import "LinphoneAppDelegate.h"

@implementation LoginView

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
	self.emailField.delegate = self;
	self.passwordField.delegate = self;
	[_showPasswordSwitch setOn:NO animated:YES];
	_loginButton.enabled = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_emailField];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_passwordField];
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
	
	_emailField.text = @"";
	_passwordField.text = @"";
	_backButton.enabled = YES;
	_loginButton.enabled = NO;
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

-(void) handleTextChange:(NSNotification *)notification {
	// Enable/disable the "Go" (Login) button
	// Minimum email format: x@y.z - Minimum size = 5 with at least one "@" and one "."
	unsigned long emailSize = _emailField.text.length;
	if (5 > emailSize) {
		_loginButton.enabled = NO;
		return;
	}
	
	BOOL invalidInputs = NO;
	for (UITextField *field in @[ _emailField, _passwordField ]) {
		unsigned long length = field.text.length;
		invalidInputs |= (length == 0);
	}
	_loginButton.enabled = !invalidInputs;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[_emailField endEditing:YES];
	[_passwordField endEditing:YES];
}

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
	[_activityIndicator stopAnimating];
	_backButton.enabled = YES;
	_loginButton.enabled = YES;
	return;
}

- (IBAction)showPasswordClick:(id)sender {
	_passwordField.secureTextEntry = !_passwordField.secureTextEntry;
}

- (IBAction)backButtonClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:WelcomeView.compositeViewDescription];
}

- (IBAction)loginButtonClick:(id)sender {
	if (!linphone_core_is_network_reachable(LC)) {
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Network Error", nil)
																		 message:NSLocalizedString(@"There is no network connection available. Please enable "
																								   @"WiFi or cellular data network.",
																								   nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[errView addAction:defaultAction];
		[self presentViewController:errView animated:YES completion:nil];
		return;
	}
	
	[_activityIndicator startAnimating];
	_backButton.enabled = NO;
	_loginButton.enabled = NO;
	LinphoneProxyConfig *config = linphone_core_create_proxy_config(LC);
	NSString *email = _emailField.text;
	
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
		int currency = loginResponse.currency;
		NSString *sipName = loginResponse.sipName;
		NSString *sipPassword = loginResponse.sipPassword;
		NSString *sipServer = loginResponse.sipServer;
		NSString *transport = @"TCP";	// Hard-code for now
		
		LOGD(@"LoginResponse: %d %@ %@ %@ %@ %@ %d", userId, token, phoneNumber, sipName, sipPassword, sipServer, currency);
		
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
		linphone_proxy_config_set_snrblabs_currency(config, currency);
		
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
		
#if 0	// Remove from here and do this in LinphoneAppDelegate for GrooVe IP
		[LinphoneManager.instance initFastAddressbook];
#endif
		
		if (config) {
			[[LinphoneManager instance] configurePushTokenForProxyConfig:config];
			if (linphone_core_add_proxy_config(LC, config) != -1) {
				linphone_core_set_default_proxy_config(LC, config);
				// reload address book to prepend proxy config domain to contacts' phone number
				[LinphoneManager.instance.fastAddressBook fetchContactsInBackGroundThread];
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
		if (textField == _emailField) {
			[_passwordField becomeFirstResponder];
		}
	} else if (textField.returnKeyType == UIReturnKeyGo) {
		[_loginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	return YES;
}

@end
