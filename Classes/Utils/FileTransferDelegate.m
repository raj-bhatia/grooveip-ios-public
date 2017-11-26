//
//  FileTransferDelegate.m
//  linphone
//
//  Created by Gautier Pelloux-Prayer on 10/06/15.
//
//

#import "FileTransferDelegate.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "GetMedia.h"
#import "GetMediaResponse.h"

@interface FileTransferDelegate ()
@property(strong) NSMutableData *data;
@end

@implementation FileTransferDelegate

- (void)dealloc {
	if (_message != nil) {
		[self cancel];
	}
}

+ (FileTransferDelegate *)messageDelegate:(LinphoneChatMessage *)message {
	for (FileTransferDelegate *ftd in [LinphoneManager.instance fileTransferDelegates]) {
		if (ftd.message == message) {
			return ftd;
		}
	}
	return nil;
}

static void linphone_iphone_file_transfer_recv(LinphoneChatMessage *message, const LinphoneContent *content,
											   const LinphoneBuffer *buffer) {
	FileTransferDelegate *thiz = [FileTransferDelegate messageDelegate:message];
	size_t size = linphone_buffer_get_size(buffer);

	if (!thiz.data) {
		thiz.data = [[NSMutableData alloc] initWithCapacity:linphone_content_get_size(content)];
	}

	if (size == 0) {
		LOGI(@"Transfer of %s (%d bytes): download finished", linphone_content_get_name(content), size);
		assert([thiz.data length] == linphone_content_get_size(content));

		// we're finished, save the image and update the message
		UIImage *image = [UIImage imageWithData:thiz.data];
		if (!image) {
			UIAlertController *errView = [UIAlertController
				alertControllerWithTitle:NSLocalizedString(@"File download error", nil)
								 message:NSLocalizedString(@"Error while downloading the file.\n"
														   @"The file is probably encrypted.\n"
														   @"Please retry to download this file after activating LIME.",
														   nil)
						  preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
																	style:UIAlertActionStyleDefault
																  handler:^(UIAlertAction *action){
																  }];

			[errView addAction:defaultAction];
			[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
			return;
		}

		CFBridgingRetain(thiz);
		[[LinphoneManager.instance fileTransferDelegates] removeObject:thiz];

		// until image is properly saved, keep a reminder on it so that the
		// chat bubble is aware of the fact that image is being saved to device
		[LinphoneManager setValueInMessageAppData:@"saving..." forKey:@"localimage" inMessage:message];

		[LinphoneManager.instance.photoLibrary
			writeImageToSavedPhotosAlbum:image.CGImage
							 orientation:(ALAssetOrientation)[image imageOrientation]
						 completionBlock:^(NSURL *assetURL, NSError *error) {
						   if (error) {
							   LOGE(@"Cannot save image data downloaded [%@]", [error localizedDescription]);
							   [LinphoneManager setValueInMessageAppData:nil forKey:@"localimage" inMessage:message];
							   UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Transfer error", nil)
																								message:NSLocalizedString(@"Cannot write image to photo library",
																														  nil)
																						 preferredStyle:UIAlertControllerStyleAlert];
							   
							   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
																					   style:UIAlertActionStyleDefault
																					 handler:^(UIAlertAction * action) {}];
							   
							   [errView addAction:defaultAction];
							   [PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
						   } else {
							   LOGI(@"Image saved to [%@]", [assetURL absoluteString]);
							   [LinphoneManager setValueInMessageAppData:[assetURL absoluteString]
																  forKey:@"localimage"
															   inMessage:message];
						   }
						   thiz.message = NULL;
						   [NSNotificationCenter.defaultCenter
							   postNotificationName:kLinphoneFileTransferRecvUpdate
											 object:thiz
										   userInfo:@{
											   @"state" : @(LinphoneChatMessageStateDelivered), // we dont want to
																								// trigger
																								// FileTransferDone here
											   @"image" : image,
											   @"progress" : @(1.f),
										   }];

						   [thiz stopAndDestroy];
						   CFRelease((__bridge CFTypeRef)thiz);
						 }];
	} else {
		LOGD(@"Transfer of %s (%d bytes): already %ld sent, adding %ld", linphone_content_get_name(content),
			 linphone_content_get_size(content), [thiz.data length], size);
		[thiz.data appendBytes:linphone_buffer_get_string_content(buffer) length:size];
		[NSNotificationCenter.defaultCenter
			postNotificationName:kLinphoneFileTransferRecvUpdate
						  object:thiz
						userInfo:@{
							@"state" : @(linphone_chat_message_get_state(message)),
							@"progress" : @([thiz.data length] * 1.f / linphone_content_get_size(content)),
						}];
	}
}

static LinphoneBuffer *linphone_iphone_file_transfer_send(LinphoneChatMessage *message, const LinphoneContent *content,
														  size_t offset, size_t size) {
	FileTransferDelegate *thiz = [FileTransferDelegate messageDelegate:message];
	size_t total = thiz.data.length;
	if (thiz.data) {
		size_t remaining = total - offset;

		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
			@"state" : @(linphone_chat_message_get_state(message)),
			@"progress" : @(offset * 1.f / total),
		}];
		LOGD(@"Transfer of %s (%d bytes): already sent %ld (%f%%), remaining %ld", linphone_content_get_name(content),
			 total, offset, offset * 100.f / total, remaining);
		[NSNotificationCenter.defaultCenter postNotificationName:kLinphoneFileTransferSendUpdate
														  object:thiz
														userInfo:dict];

		LinphoneBuffer *buffer = NULL;
		@try {
			buffer = linphone_buffer_new_from_data([thiz.data subdataWithRange:NSMakeRange(offset, size)].bytes, size);
		} @catch (NSException *exception) {
			LOGE(@"Exception: %@", exception);
		}

		// this is the last time we will be notified, so destroy ourselve
		if (remaining <= size) {
			LOGI(@"Upload ended");
			linphone_chat_message_cbs_set_file_transfer_send(linphone_chat_message_get_callbacks(thiz.message), NULL);
			thiz.message = NULL;
			[thiz stopAndDestroy];
		}
		return buffer;
	} else {
		LOGE(@"Transfer of %s (%d bytes): %d Error - no upload data in progress!", linphone_content_get_name(content),
			 total, offset);
	}

	return NULL;
}

#if 0	// Changed Linphone code - Return error if image is too large, otherwise return how much to compress it
- (void)upload:(UIImage *)image withURL:(NSURL *)url forChatRoom:(LinphoneChatRoom *)chatRoom {
	[LinphoneManager.instance.fileTransferDelegates addObject:self];
	LinphoneContent *content = linphone_core_create_content(linphone_chat_room_get_core(chatRoom));
	_data = [NSMutableData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
	linphone_content_set_type(content, "image");
	linphone_content_set_subtype(content, "jpeg");
	linphone_content_set_name(
		content, [[NSString stringWithFormat:@"%li-%f.jpg", (long)image.hash, [NSDate timeIntervalSinceReferenceDate]]
					 UTF8String]);
	linphone_content_set_size(content, _data.length);

	_message = linphone_chat_room_create_file_transfer_message(chatRoom, content);
	linphone_content_unref(content);

	linphone_chat_message_cbs_set_file_transfer_send(linphone_chat_message_get_callbacks(_message),
													 linphone_iphone_file_transfer_send);

	if (url) {
		// internal url is saved in the appdata for display and later save
		[LinphoneManager setValueInMessageAppData:[url absoluteString] forKey:@"localimage" inMessage:_message];
	}

	LOGI(@"%p Uploading content from message %p", self, _message);
	linphone_chat_room_send_chat_message(chatRoom, _message);

	if (linphone_core_lime_enabled(LC) == LinphoneLimeMandatory && !linphone_chat_room_lime_available(chatRoom)) {
		[LinphoneManager.instance alertLIME:chatRoom];
	}
}
#else
- (int)upload:(UIImage *)image withURL:(NSURL *)url forChatRoom:(LinphoneChatRoom *)chatRoom {
	int i;
	for (i = 10; i >= 0; i--) {
		_data = [NSMutableData dataWithData:UIImageJPEGRepresentation(image, 0.1 * i)];
		NSNumber *size = [NSNumber numberWithInteger:[_data length]];
		long iSize = [size integerValue];
		if (950000 >= iSize) {
			LOGI(@"upload: Image compression successful - Index %d, Size %ld", i, iSize);
			break;
		}
	}
	if (0 > i) {	// Image is too large
		LOGI(@"upload failed: Image cannot be compressed enough to fit in the 950000 byte limit");
		return i;
	}
	
	LinphoneContent *content = linphone_core_create_content(linphone_chat_room_get_core(chatRoom));
	linphone_content_set_type(content, "image");
	linphone_content_set_subtype(content, "jpeg");
	linphone_content_set_name(
							  content, [[NSString stringWithFormat:@"%li-%f.jpg", (long)image.hash, [NSDate timeIntervalSinceReferenceDate]]
										UTF8String]);
	linphone_content_set_size(content, _data.length);
	
	_message = linphone_chat_room_create_file_transfer_message(chatRoom, content);
	linphone_content_unref(content);
	
	if (url) {
		// internal url is saved in the appdata for display and later save
		[LinphoneManager setValueInMessageAppData:[url absoluteString] forKey:@"localimage" inMessage:_message];
	}
	
	LOGI(@"%p Uploading content from message %p", self, _message);
	linphone_chat_room_send_chat_message(chatRoom, _message);
	
	return i;
}
#endif

#if 0	// Changed Linphone code - Download file using API, not SIP
- (BOOL)download:(LinphoneChatMessage *)message {
	[[LinphoneManager.instance fileTransferDelegates] addObject:self];

	_message = message;

	const char *url = linphone_chat_message_get_external_body_url(_message);
	LOGI(@"%p Downloading content in %p from %s", self, message, url);

	if (url == nil)
		return FALSE;

	linphone_chat_message_cbs_set_file_transfer_recv(linphone_chat_message_get_callbacks(_message),
													 linphone_iphone_file_transfer_recv);

	linphone_chat_message_download_file(_message);

	return TRUE;
}
#else
- (BOOL)download:(LinphoneChatMessage *)message {
	_message = message;
	
	const char *url = linphone_chat_message_get_external_body_url(_message);
	if (url == nil) {
		return FALSE;
	}
	
	NSArray *parts = [[NSString stringWithUTF8String : url] componentsSeparatedByString:@"/"];
	unsigned long size = [parts count];
	NSString *name = parts[size - 1];
	LOGI(@"%p Downloading content in %p from %s file %@", self, message, url, name);

	LinphoneProxyConfig *config = linphone_core_get_default_proxy_config(LC);
	const char *uid = linphone_proxy_config_get_snrblabs_userid(config);
	const char *tkn = linphone_proxy_config_get_snrblabs_token(config);
	if (uid && tkn && name) {
		NSString *userId = [[NSString alloc] initWithUTF8String:uid];
		NSString *token = [[NSString alloc] initWithUTF8String:tkn];
		NSLog(@"download: UserId %@ Token %@ Name %@", userId, token, name);
		
		GetMedia * getMedia = [GetMedia instance];
		[getMedia getMediaWithUserId:userId token:token fileName:name completion:^(GetMediaResponse *getMediaResponse, int *status) {
			int errorCode = *status;
			if (0 != errorCode) {
				NSLog(@"Error: %d", errorCode);
				return;
			}
			
			// Received 200 OK with image data
			NSData *data = getMediaResponse.data;
			LOGD(@"GetMediaResponse: Received file");
			
			// Save the image and update the message
			UIImage *image = [UIImage imageWithData:data];
			if (!image) {
				NSLog(@"Image download error");
				return;
			}
			
			// Until image is properly saved, keep a reminder on it so that the
			// chat bubble is aware of the fact that image is being saved to device
			[LinphoneManager setValueInMessageAppData:@"saving..." forKey:@"localimage" inMessage:_message];
			
			[LinphoneManager.instance.photoLibrary
			 writeImageToSavedPhotosAlbum:image.CGImage
			 orientation:(ALAssetOrientation)[image imageOrientation]
			 completionBlock:^(NSURL *assetURL, NSError *error) {
				 if (error) {
					 LOGE(@"Cannot save image data downloaded [%@]", [error localizedDescription]);
					 [LinphoneManager setValueInMessageAppData:nil forKey:@"localimage" inMessage:_message];
				 } else {
					 LOGI(@"Image saved to [%@]", [assetURL absoluteString]);
					 [LinphoneManager setValueInMessageAppData:[assetURL absoluteString] forKey:@"localimage" inMessage:_message];
					 linphone_chat_message_update_state(_message, LinphoneChatMessageStateFileTransferDone);
					 const LinphoneAddress *from = linphone_chat_message_get_from(_message);
					 LinphoneChatRoom *cr = linphone_core_get_chat_room(LC, from);
					 dispatch_async(dispatch_get_main_queue(), ^{
						 snrblabs_received_photo(LC, cr, _message);
					 });
				 }
			 }];
		}];
	}
	
	return TRUE;
}
#endif

- (void)stopAndDestroy {
	[[LinphoneManager.instance fileTransferDelegates] removeObject:self];
	if (_message != NULL) {
		LinphoneChatMessage *msg = _message;
		_message = NULL;
		LOGI(@"%p Cancelling transfer from %p", self, msg);
		linphone_chat_message_cbs_set_file_transfer_send(linphone_chat_message_get_callbacks(msg), NULL);
		linphone_chat_message_cbs_set_file_transfer_recv(linphone_chat_message_get_callbacks(msg), NULL);
#if 0	// Changed Linphone code - We are not transferring the file the Linphone way
		// when we cancel file transfer, this will automatically trigger NotDelivered callback... recalling ourself a
		// second time so we have to unset message BEFORE calling this
		linphone_chat_message_cancel_file_transfer(msg);
#else
		snrblabs_unref_mms(msg);
#endif
	}
	_data = nil;
	LOGD(@"%p Destroying", self);
}

- (void)cancel {
	[self stopAndDestroy];
}

@end
