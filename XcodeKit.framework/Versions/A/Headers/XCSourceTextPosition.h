//
//  XCSourceTextPosition.h
//  Xcode
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

#import <XcodeKit/XcodeKitDefines.h>


NS_ASSUME_NONNULL_BEGIN


/** A single text position within a buffer. All coordinates are zero-based. */
typedef struct {
    NSInteger line;
    NSInteger column;
} XCSourceTextPosition;


/** Return a new XCSourceTextPosition. */
NS_INLINE XCSourceTextPosition XCSourceTextPositionMake(const NSInteger line, const NSInteger column) NS_SWIFT_UNAVAILABLE("Use the XCSourceTextPosition constructor instead.")
{
    XCSourceTextPosition position = { .line = line, .column = column };
    return position;
}


NS_ASSUME_NONNULL_END
