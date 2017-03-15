//
//  Copyright (c) 2016 Apple Inc. All rights reserved.
//

#import <XCTest/XCTestDefines.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class XCTestExpectation
 *
 * @discussion
 * Expectations represent specific conditions in asynchronous testing.
 */
@interface XCTestExpectation : NSObject {
#ifndef __OBJC2__
    id _internalImplementation;
#endif
}

/*!
 * @method -fulfill
 *
 * @discussion
 * Call -fulfill to mark an expectation as having been met. It's an error to call
 * -fulfill on an expectation that has already been fulfilled or when the test case
 * that vended the expectation has already completed.
 */
- (void)fulfill;

@end

NS_ASSUME_NONNULL_END
