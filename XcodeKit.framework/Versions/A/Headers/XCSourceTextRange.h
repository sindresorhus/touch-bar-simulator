//
//  XCSourceTextRange.h
//  Xcode
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

#import <XcodeKit/XcodeKitDefines.h>

#import <XcodeKit/XCSourceTextPosition.h>


NS_ASSUME_NONNULL_BEGIN


/** A half-open range of text in a buffer. A range with equal start and end positions is used to indicate a point within the buffer, such as an insertion point. Otherwise, the range includes the character at the start position and excludes the character at the end position. The start and end may be improperly ordered transiently, but must be properly ordered before passing an XCSourceTextRange to other API. */
@interface XCSourceTextRange : NSObject <NSCopying>

/** The position representing the start of the range. */
@property XCSourceTextPosition start;

/** The position representing the end of the range; the character at this position is not included within the range. */
@property XCSourceTextPosition end;

/** Returns a range with the given start and end positions. The start and end positions must be properly ordered. */
- (instancetype)initWithStart:(XCSourceTextPosition)start end:(XCSourceTextPosition)end NS_DESIGNATED_INITIALIZER;

@end


NS_ASSUME_NONNULL_END
