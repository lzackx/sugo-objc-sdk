//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <Foundation/Foundation.h>
#import "MPAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerChangeResponseMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end
