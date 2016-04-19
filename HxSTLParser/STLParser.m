//
//  STLParser.m
//  HxSTLParser
//
//  Created by Victor Gama on 4/19/16.
//  Copyright © 2016 Victor Gama. All rights reserved.
//

#import "STLParser.h"
#import <SceneKit/SceneKit.h>

typedef NS_ENUM(NSUInteger, STLParserState) {
    STLParserStateSolid,
    STLParserStateFacet,
    STLParserStateLoop,
    STLParserStateVertex,
    STLParserStateEndLoop,
    STLParserStateEndFacet,
    STLParserStateEndSolid
};

#define solidExp @"^\\s*solid\\s([^\\n]+)$"
#define facetExp @"^\\s*facet(?:\\s(normal)\\s+([-0-9\\.e\\+]+)\\s*([-0-9\\.e\\+]+)\\s*([-0-9\\.e\\+]+)\\s*)?$"
#define outerExp @"^\\s*(outer loop)$"
#define vertexExp @"^\\s+vertex\\s+([-\\.0-9e\\+]+)\\s+([-\\.0-9e\\+]+)\\s+([-\\.0-9e\\+]+)$"
#define endOuterExp @"^\\s*(endloop)$"
#define endFacetExp @"^\\s*(endfacet)$"
#define endSolidExp @"^\\s*endsolid\\s([^\\n]+)$"

@implementation STLParser {
    STLParserState state;
    NSString *solidName;
    int vertexId;
    int currentLine;
    NSError *__autoreleasing *outError;
    NSMutableArray *components;
    SCNVector3 currentNormal;
    NSMutableData *currentVectors;
    NSMutableData *currentNormals;
    SCNNode *node;
}

#pragma mark Lifecycle

- (instancetype)init {
    if(self = [super init]) {
        solidName = nil;
    }
    return self;
}

- (SCNNode *)loadFromString:(const NSString *)data error:(NSError *__autoreleasing *)_outError {
    outError = _outError;
    state = STLParserStateSolid;
    components = [NSMutableArray arrayWithArray:[[[data componentsSeparatedByString:@"\n"] reverseObjectEnumerator] allObjects]];
    if(![self parse]) {
        return nil;
    }
    return node;
}

#pragma mark FSM

- (BOOL)parse {
    NSArray *matches;
    while(components.count > 0) {
        currentLine++;
        NSString *currentComponent = [components lastObject];
        [components removeLastObject];
        switch (state) {
            case STLParserStateSolid:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:solidExp])) {
                    solidName = matches[0];
                    node = [SCNNode node];
                    state = STLParserStateFacet;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateSolid");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateSolid, got invalid input: %@", currentComponent] andCode:1];
                    return NO;
                }
                break;
            case STLParserStateFacet:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:facetExp])) {
                    currentNormals = [[NSMutableData alloc] init];
                    currentVectors = [[NSMutableData alloc] init];
                    if(![matches[0] isEqualToString:@"normal"]) {
                        NSLog(@"[STLParser] Failed: STLParserStateFacet. Missing normal declaration.");
                        [self reportErrorWithMessage:[NSString stringWithFormat:@"During STLParserStateFacet, normal vector data could not be acquired."] andCode:10];
                        return NO;
                    }
                    currentNormal = (SCNVector3){[matches[1] floatValue], [matches[2] floatValue], [matches[3] floatValue]};
                    state = STLParserStateLoop;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateFacet");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateFacet, got invalid input: %@", currentComponent] andCode:2];
                    return NO;
                }
                break;
            case STLParserStateLoop:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:outerExp])) {
                    state = STLParserStateVertex;
                    vertexId = 0;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateLoop");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateLoop, got invalid input: %@", currentComponent] andCode:3];
                    return NO;
                }
                break;
            case STLParserStateVertex:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:vertexExp])) {
                    SCNVector3 v = [self vector3FromComponents:matches];
                    [currentVectors appendBytes:&v length:sizeof(v)];
                    [currentNormals appendBytes:&currentNormal length:sizeof(currentNormal)];
                    if(vertexId == 2) {
                        state = STLParserStateEndLoop;
                    }
                    vertexId++;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateVertex (vertexId: %i)", vertexId);
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateVertex, got invalid input: %@ (scanning vertex group #%i)", currentComponent, vertexId] andCode:4];
                    return NO;
                }
                break;
            case STLParserStateEndLoop:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:endOuterExp])) {
                    // TODO: Handle more than one outer loop?
                    state = STLParserStateEndFacet;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateEndLoop");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateEndLoop, got invalid input: %@", currentComponent] andCode:5];
                    return NO;
                }
                break;
            case STLParserStateEndFacet:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:endFacetExp])) {
                    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithData:currentVectors
                                                                                       semantic:SCNGeometrySourceSemanticVertex
                                                                                    vectorCount:3
                                                                                floatComponents:YES
                                                                            componentsPerVector:3
                                                                              bytesPerComponent:sizeof(float)
                                                                                     dataOffset:0
                                                                                     dataStride:sizeof(SCNVector3)];
                    SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithData:currentNormals
                                                                                       semantic:SCNGeometrySourceSemanticNormal
                                                                                    vectorCount:3
                                                                                floatComponents:YES
                                                                            componentsPerVector:3
                                                                              bytesPerComponent:sizeof(float)
                                                                                     dataOffset:0
                                                                                     dataStride:sizeof(SCNVector3)];
                    int indexes[3] = { 0, 1, 2 };

                    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:&indexes[0] length:sizeof(indexes)]
                                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                                               primitiveCount:1
                                                                                bytesPerIndex:sizeof(int)];
                    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource]
                                                                    elements:@[element]];
                    SCNNode *gn = [SCNNode nodeWithGeometry:geometry];
                    [node addChildNode:gn];

                    // From this point onwards, there are two options: Finish the whole solid, or begin a
                    // new facet. In this case, we peek and cheat.
                    NSArray *dummy;
                    if((dummy = [self matchDataFromComponent:[components lastObject] usingExpression:endSolidExp supressingWarnings:YES])) {
                        state = STLParserStateEndSolid;
                    } else {
                        state = STLParserStateFacet;
                    }
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateEndFacet");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateEndFacet, got invalid input: %@", currentComponent] andCode:6];
                    return NO;
                }
                break;
            case STLParserStateEndSolid:
                if((matches = [self matchDataFromComponent:currentComponent usingExpression:endSolidExp])) {
                    return YES;
                } else {
                    NSLog(@"[STLParser] Failed: STLParserStateEndLoop");
                    [self reportErrorWithMessage:[NSString stringWithFormat:@"Expecting state STLParserStateEndSolid, got invalid input: %@", currentComponent] andCode:7];
                    return NO;
                }
                break;
        }
    }
    NSLog(@"[STLParser] Failed: Premature EOF");
    [self reportErrorWithMessage:[NSString stringWithFormat:@"Premature end of File"] andCode:8];
    return NO;
}

#pragma mark Utility methods

- (void)reportErrorWithMessage:(NSString *)message andCode:(int)code {
    NSString *msg = [NSString stringWithFormat:@"%@ (at line %i)", message, currentLine];
    *outError = [NSError errorWithDomain:@"io.vito.HxSTLParser" code:code userInfo:@{
                                                                                   NSLocalizedDescriptionKey: msg
                                                                                   }];
}

- (NSArray *)matchDataFromComponent:(NSString *)component usingExpression:(NSString *)exp supressingWarnings:(BOOL)supress {
    NSError *err;
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:exp options:NSRegularExpressionCaseInsensitive error:&err];
    if(err != nil) {
        NSLog(@"[STLParser:matchDataFromComponent] Error: %@", err);
        return nil;
    }

    NSArray *matches = [reg matchesInString:component options:0 range:NSMakeRange(0, component.length)];
    if(matches.count < 1) {
        if(!supress) {
            NSLog(@"[STLParser:matchDataFromComponent] No matches for input component at line %i: %@\n\
                  input expression: %@", currentLine, component, exp);
        }
        return nil;
    }

    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(NSTextCheckingResult *r in matches) {
        for(int i = 1; i < r.numberOfRanges; i++) {
            [result addObject:[component substringWithRange:[r rangeAtIndex:i]]];
        }
    }

    return result;
}

- (NSArray *)matchDataFromComponent:(NSString *)component usingExpression:(NSString *)exp {
    return [self matchDataFromComponent:component usingExpression:exp supressingWarnings:NO];
}

- (SCNVector3)vector3FromComponents:(NSArray *)_components {
    return (SCNVector3) {[_components[0] floatValue], [_components[1] floatValue], [_components[2] floatValue]};
}



#pragma mark Property Getters

- (NSString *)getSolidName {
    return solidName;
}
@end
