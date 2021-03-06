//
//  ObjectSelector.h
//  HelloSugo
//
//  Created by Alex Hofsteede on 5/5/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPObjectSelector : NSObject

@property (nonatomic, strong, readonly) NSString *string;

+ (MPObjectSelector *)objectSelectorWithString:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;

- (NSArray *)selectFromRoot:(id)root;
- (NSArray *)fuzzySelectFromRoot:(id)root;

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root;
- (BOOL)fuzzyIsLeafSelected:(id)leaf fromRoot:(id)root;

- (Class)selectedClass;
- (BOOL)pathContainsObjectOfClass:(Class)klass;
- (NSString *)description;

@end
