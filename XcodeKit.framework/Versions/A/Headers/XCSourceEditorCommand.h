//
//  XCSourceEditorCommand.h
//  Xcode
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

#import <XcodeKit/XcodeKitDefines.h>


@class XCSourceTextBuffer;


NS_ASSUME_NONNULL_BEGIN


/** Information about the source editor command that the user invoked, such as the identifier of the command, the text buffer on which the command is to operate, and whether the command has been canceled by Xcode or the user. */
@interface XCSourceEditorCommandInvocation : NSObject

/** An XCSourceEditorCommandInvocation is not directly instantiable. */
- (instancetype)init NS_UNAVAILABLE;

/** The identifier of the command the user invoked. */
@property (readonly, copy) NSString *commandIdentifier;

/** The buffer of source text on which the command can operate. */
@property (readonly, strong) XCSourceTextBuffer *buffer;

/** Invoked by Xcode to indicate that the invocation has been canceled by the user. After receiving a cancellation, the command's completionHandler must still be invoked, but no changes will be applied.
 
 \note Make no assumptions about the thread or queue on which the cancellation handler is invoked.
 */
@property (copy) void (^cancellationHandler)(void);

@end


/** A command provided by a source editor extension. There does not need to be a one-to-one mapping between command classes and commands: Multiple commands can be handled by a single class, by checking their invocation's commandIdentifier at runtime. */
@protocol XCSourceEditorCommand <NSObject>

@required

/** Perform the action associated with the command using the information in \a invocation. Xcode will pass the code a completion handler that it must invoke to finish performing the command, passing nil on success or an error on failure.
 
 A canceled command must still call the completion handler, passing nil.
 
 \note Make no assumptions about the thread or queue on which this method will be invoked.
 */
- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler;

@end


NS_ASSUME_NONNULL_END
