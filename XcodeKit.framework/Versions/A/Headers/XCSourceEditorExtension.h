//
//  XCSourceEditorExtension.h
//  Xcode
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

#import <XcodeKit/XcodeKitDefines.h>


NS_ASSUME_NONNULL_BEGIN


/** A key in the dictionary that defines one source editor command. Source editor commands are defined via an array of dictionaries under the XCSourceEditorCommandDefinitions key of a Xcode Source Editor Extension's NSExtensionAttributes within its Info.plist. */
typedef NSString * XCSourceEditorCommandDefinitionKey NS_STRING_ENUM;

/** The identifier of the source editor command in its attributes. */
XCODE_EXPORT XCSourceEditorCommandDefinitionKey const XCSourceEditorCommandIdentifierKey;

/** The name of the source editor command in its attributes. */
XCODE_EXPORT XCSourceEditorCommandDefinitionKey const XCSourceEditorCommandNameKey;

/** The class of the source editor command, in its attributes. */
XCODE_EXPORT XCSourceEditorCommandDefinitionKey const XCSourceEditorCommandClassNameKey;


/** An Xcode Source Editor Extension is an instance of a class conforming to this protocol, which is set as the value of the XCSourceEditorExtensionPrincipalClass key in the NSExtensionAttributes dictionary in the extension's Info.plist.
 
 \note Make no assumptions about the thread or queue on which any methods will be invoked or properties will be accessed, including the designated initializer.
*/
@protocol XCSourceEditorExtension <NSObject>

@optional

/** Invoked when the extension has been launched, which may be some time before the extension actually receives a command (if ever).
 
 \note Make no assumptions about the thread or queue on which this method will be invoked.
 */
- (void)extensionDidFinishLaunching;

/** An array of command definitions, just as they appear in the XCSourceEditorCommandDefinitions key of this extension's NSExtensionAttributes in its Info.plist.
 
 \note Make no assumptions about the thread or queue on which this property will be read.
 */
@property (readonly, copy) NSArray <NSDictionary <XCSourceEditorCommandDefinitionKey, id> *> *commandDefinitions;

@end


NS_ASSUME_NONNULL_END
