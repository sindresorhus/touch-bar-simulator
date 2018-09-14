//
//  XCSourceTextBuffer.h
//  Xcode
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

#import <XcodeKit/XcodeKitDefines.h>


@class XCSourceTextRange;


NS_ASSUME_NONNULL_BEGIN


/** A buffer representing some editor text. Mutations to the buffer are tracked and committed when a command returns YES and has not been canceled by the user. */
@interface XCSourceTextBuffer : NSObject

/** An XCSourceTextBuffer is not directly instantiable. */
- (instancetype)init NS_UNAVAILABLE;

/** The UTI of the content in the buffer. */
@property (readonly, copy) NSString *contentUTI;

/** The number of space characters represented by a tab character in the buffer. */
@property (readonly) NSInteger tabWidth;

/** The number of space characters used for indentation of the text in the buffer. */
@property (readonly) NSInteger indentationWidth;

/** Whether tabs are used for indentation, or just spaces. When tabs are used for indentation, indented text is effectively padded to the indentation width using space characters, and then every tab width space characters is replaced with a tab character.
 
 For example, say an XCSourceTextBuffer instance has a tabWith of 8, an indentationWidth of 4, and its usesTabsForIndentation is true. The first indentation level will be represented by four space characters, the second by a tab character, the third by a tab followed by four space characters, the fourth by two tab characters, and so on.
 */
@property (readonly) BOOL usesTabsForIndentation;

/** The lines of text in the buffer, including line endings. Line breaks within a single buffer are expected to be consistent. Adding a "line" that itself contains line breaks will actually modify the array as well, changing its count, such that each line added is a separate element. */
@property (readonly, strong) NSMutableArray <NSString *> *lines;

/** The text selections in the buffer; an empty range represents an insertion point. Modifying the lines of text in the buffer will automatically update the selections to match. */
@property (readonly, strong) NSMutableArray <XCSourceTextRange *> *selections;

/** The complete buffer's string representation, as a convenience. Changes to `lines` are immediately reflected in this property, and vice versa. */
@property (copy) NSString *completeBuffer;

@end


NS_ASSUME_NONNULL_END
