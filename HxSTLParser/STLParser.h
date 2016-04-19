//
//  STLParser.h
//  HxSTLParser
//
//  Created by Victor Gama on 4/19/16.
//  Copyright © 2016 Victor Gama. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCNNode;

@interface STLParser : NSObject

@property (nonatomic, readonly, getter=getSolidName) NSString *solidName;

- (SCNNode *)loadFromString:(const NSString *)data error:(NSError *__autoreleasing *)_outError;

@end
