/* LinphoneAppDelegate.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>
#import <AVFoundation/AVAudioSession.h>

#import "LinphoneCoreSettingsStore.h"
#import "ProviderDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "PhoneMainView.h"

@interface LinphoneAppDelegate : NSObject <UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate> {
    @private
	UIBackgroundTaskIdentifier bgStartId;
    BOOL startedInBackground;
}

- (void)registerForNotifications;

@property (nonatomic, retain) UIAlertController *waitingIndicator;
@property (nonatomic, retain) NSString *configURL;
@property (nonatomic, strong) UIWindow* window;
@property PKPushRegistry* voipRegistry;
@property ProviderDelegate *del;
@property BOOL alreadyRegisteredForNotification;

@property (class) BOOL appInBackground;
@property (class) NSString *newDeviceToken;
@property (class) NSString *pushNotificationCallId;
@property (class) NSString *pushNotificationCallerId;
@property (class) BOOL needToSendPNResponse;
@property (class) NSString *callRoute;
@property (class) long callStartTime;
@property (class) long outgoingCallStartTime;
@property (class) NSString *outgoingPhoneNumber;
@property (class) UICompositeViewDescription *outgoingLastView;
@property (class) NSTimer *outgoingTimer;
@property (class) LinphoneRegistrationState registrationState;

@end

