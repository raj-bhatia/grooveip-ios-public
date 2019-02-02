//
//  FileTransferDelegate.h
//  linphone
//
//  Created by Gautier Pelloux-Prayer on 10/06/15.
//
//

#import <Foundation/Foundation.h>

#import "LinphoneManager.h"

@interface FileTransferDelegate : NSObject

#if 0	// Changed Linphone code - Return error if image is too large, otherwise return how much to compress it
- (void)upload:(UIImage *)image withURL:(NSURL *)url forChatRoom:(LinphoneChatRoom *)chatRoom withQuality:(float)quality;
#else
- (int)upload:(UIImage *)image withURL:(NSURL *)url forChatRoom:(LinphoneChatRoom *)chatRoom;
#endif
- (void)cancel;
#if 0	// Changed Linphone code - MMS
- (BOOL)download:(LinphoneChatMessage *)message;
#else
- (BOOL)download:(LinphoneChatMessage *)message announceCompletion:(BOOL)announce;
#endif
- (void)stopAndDestroy;

@property() LinphoneChatMessage *message;
@end
