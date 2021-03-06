//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"

@implementation MPCGColorRefToNSStringValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (value && CFGetTypeID((__bridge CFTypeRef)value) == CGColorGetTypeID()) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
        return [transformer transformedValue:[[UIColor alloc] initWithCGColor:(__bridge CGColorRef)value]];
    }

    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
    UIColor *uiColor =  [transformer reverseTransformedValue:value];
    return CFBridgingRelease(CGColorCreateCopy([uiColor CGColor]));
}

@end
