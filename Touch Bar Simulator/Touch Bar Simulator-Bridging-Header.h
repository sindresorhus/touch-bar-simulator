#import <Cocoa/Cocoa.h>

CGDisplayStreamRef SLSDFRDisplayStreamCreate(int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);
CGSize DFRGetScreenSize(void);
void DFRSetStatus(int);
int DFRGetStatus(void);
void DFRFoundationPostEventWithMouseActivity(NSEventType type, CGPoint point);

@interface NSWindow (Private)
	- (void)_setPreventsActivation:(bool)preventsActivation;
@end
