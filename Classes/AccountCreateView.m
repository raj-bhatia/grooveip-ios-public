/*
 *  AccountCreateView.m
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

#import "AccountCreateView.h"
#import "VerifyView.h"
#import "AreaCodeView.h"

@implementation AccountCreateView

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
	self.password1Field.delegate = self;
	self.password2Field.delegate = self;
	self.codeField.delegate = self;
	[_showPasswordSwitch setOn:NO animated:YES];
	_createButton.enabled = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_emailField];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_password1Field];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_password2Field];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTextChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:_codeField];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_emailField.text = @"";
	_password1Field.text = @"";
	_password2Field.text = @"";
	_codeField.text = @"";
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
	// Enable/disable the "Go" (Create) button
	// Minimum email format: x@y.z - Minimum size = 5 with at least one "@" and one "."
	unsigned long emailSize = _emailField.text.length;
	NSRange rangeAt = [_emailField.text rangeOfString:@"@"];
	NSRange rangeDot = [_emailField.text rangeOfString:@"."];
	if ((5 > emailSize) || (NSNotFound == rangeAt.location) || (NSNotFound == rangeDot.location)) {
		_createButton.enabled = NO;
		return;
	}
	
	if ((0 >= _password1Field.text.length) || (0 >= _password2Field.text.length) || (0 >= _codeField.text.length)) {
		_createButton.enabled = NO;
		return;
	}
	
	_createButton.enabled = YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[_emailField endEditing:YES];
	[_password1Field endEditing:YES];
	[_password2Field endEditing:YES];
	[_codeField endEditing:YES];
}

- (void)displayAccountCreateError: (int) errorCode {
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
								  alertControllerWithTitle:NSLocalizedString(@"Account creation error", nil)
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
	_createButton.enabled = YES;
	return;
}

- (IBAction)showPasswordClick:(id)sender {
	_password1Field.secureTextEntry = !_password1Field.secureTextEntry;
	_password2Field.secureTextEntry = !_password2Field.secureTextEntry;
}

- (IBAction)backButtonClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:VerifyView.compositeViewDescription];
}

- (IBAction)createButtonClick:(id)sender {
	NSString *password1 = _password1Field.text;
	NSString *password2 = _password2Field.text;
	if (![password1 isEqualToString:password2]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"The two passwords do not match"
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	NSString *message = @"\nI certify that I am 13 years old, or older.\n\nI understand that emergency calling is handled through my native phone app.\n\nI have read, and accept, ONE-Phone’s Terms & Conditions at snrblabs.com/eula";
	UIAlertController *alertController = [UIAlertController
										  alertControllerWithTitle:@"Important Information"
										  message:message
										  preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *declineAction = [UIAlertAction
									actionWithTitle:NSLocalizedString(@"Decline", @"Decline action")
									style:UIAlertActionStyleDefault
									handler:^(UIAlertAction *action)
									{
									}];
	
	UIAlertAction *acceptAction = [UIAlertAction
								   actionWithTitle:NSLocalizedString(@"Accept", @"Accept action")
								   style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction *action)
								   {
									   [PhoneMainView.instance changeCurrentView:AreaCodeView.compositeViewDescription];
								   }];
	
	[alertController addAction:declineAction];
	[alertController addAction:acceptAction];
	
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	if (textField.returnKeyType == UIReturnKeyNext) {
		if (textField == _emailField) {
			[_password1Field becomeFirstResponder];
		} else if (textField == _password1Field) {
			[_password2Field becomeFirstResponder];
		} else if (textField == _password2Field) {
			[_codeField becomeFirstResponder];
		}
	} else if (textField.returnKeyType == UIReturnKeyGo) {
		[_createButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	return YES;
}

@end
