/*
 *  VerifyView.m
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

#import "VerifyView.h"
#import "WelcomeView.h"
#import "AccountCreateView.h"
#import "VerifyManager.h"

@implementation VerifyView

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
	self.phoneNumberField.delegate = self;
	_sendButton.enabled = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_phoneNumberField];
}- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_phoneNumberField.text = @"";
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
	// Enable/disable the "Go" (Verify) button
	unsigned long phoneNumberSize = _phoneNumberField.text.length;
	if (10 <= phoneNumberSize) {
		_sendButton.enabled = YES;
	} else {
		_sendButton.enabled = NO;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[_phoneNumberField endEditing:YES];
}

- (void)displayVerifyManagerError: (int) errorCode {
	NSString *errorMessage = [NSString stringWithFormat:@"Error generating verification code. Please try again later. If the issue continues, please contact us. (Code %i)", errorCode];

	UIAlertController *errView = [UIAlertController
								  alertControllerWithTitle:NSLocalizedString(@"Verification code error", nil)
								  message:NSLocalizedString(errorMessage, nil)
								  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
															style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction *action){
														  }];
	
	[errView addAction:defaultAction];
	[self presentViewController:errView animated:YES completion:nil];
	return;
}

- (IBAction)sendButtonClick:(id)sender {
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
	_sendButton.enabled = NO;
	NSString *phoneNumber = [NSString stringWithFormat:@"+1%@", _phoneNumberField.text];
	
	VerifyManager * verifyManager = [VerifyManager instance];
	[verifyManager verifyWithPhoneNumber:phoneNumber completion:^(GenericResponse *genericResponse, int *status) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[_activityIndicator stopAnimating];
			_backButton.enabled = YES;
			_sendButton.enabled = YES;
		});
		int errorCode = *status;
		if (0 != errorCode) {
			NSLog(@"Error: %d", errorCode);
			dispatch_async(dispatch_get_main_queue(), ^{
				[self displayVerifyManagerError : errorCode];
			});
			return;
		}

		// Received 200 OK
		LOGD(@"Verify Response: Received 200 OK");
		dispatch_async(dispatch_get_main_queue(), ^{
			[PhoneMainView.instance changeCurrentView:AccountCreateView.compositeViewDescription];
		});
	}];
}

- (IBAction)backButtonClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:WelcomeView.compositeViewDescription];
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	if (textField.returnKeyType == UIReturnKeyGo) {
		[_sendButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	return YES;
}

@end
