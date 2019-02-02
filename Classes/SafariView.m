/*
 *  SafariView.m
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

#import "SafariView.h"
#import "Secret.h"
#import "LinphoneAppDelegate.h"
#import "LoginView.h"

@interface SafariView ()
@end

@implementation SafariView

static NSString *_safariUrl = nil;
+ (NSString *) safariUrl { return _safariUrl; }
+ (void) setSafariUrl : (NSString *)safariUrl { _safariUrl = safariUrl; }

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

- (void)viewDidLoad {
	[super viewDidLoad];
	
	WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
	_webView = [[WKWebView alloc] initWithFrame:self.childViewOutlet.frame configuration:theConfiguration];
	_webView.navigationDelegate = self;
	NSURL *url = [NSURL URLWithString:SafariView.safariUrl];
	NSURLRequest *nsrequest=[NSURLRequest requestWithURL:url];
	[_webView setAutoresizingMask: UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	[_webView loadRequest:nsrequest];
	[_webView allowsBackForwardNavigationGestures];
	[self.childViewOutlet addSubview:_webView];
	_urlField.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
	[_activityIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	[_activityIndicator stopAnimating];
	
	if (NO == [_webView canGoBack]) {
		_leftButton.enabled = NO;
	} else {
		_leftButton.enabled = YES;
	}
	
	if (NO == [_webView canGoForward]) {
		_rightButton.enabled = NO;
	} else {
		_rightButton.enabled = YES;
	}
}

- (IBAction)doneButtonClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:LoginView.compositeViewDescription];
}

- (IBAction)leftButtonClick:(id)sender {
	[_webView goBack];
}

- (IBAction)rightButtonClick:(id)sender {
	[_webView goForward];
}

- (IBAction)reloadButtonClick:(id)sender {
	[_webView reload];
}

@end
