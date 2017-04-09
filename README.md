# HxSTLParser
![Platform](https://img.shields.io/badge/platform-iOS%208%2B-yellow.svg?style=flat)
![Language](https://img.shields.io/badge/language-ObjC-blue.svg?style=flat)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)

----

`HxSTLParser` is a basic STL parser capable of loading STL files into an `SCNNode`.

## Installing

### Via Carthage
Just add it to your Cartfile
```
github "victorgama/HxSTLParser"
```

Then run:
```
$ carthage update
```

### Via Cocoapods

Just add `HxSTLParser` to your `Podfile`:
```ruby
platform :ios, '8.0'
use_frameworks!

pod 'HxSTLParser', '1.0.0'
```

## Usage

```objc
#import <HxSTLParser/HxSTLParser.h>

- (void)loadStl {
    STLParser *parser = [[STLParser alloc] init];
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"3dObject" ofType:@"stl"] encoding:NSASCIIStringEncoding error:nil];
    SCNNode *node = [parser loadFromString:fileContents error:&error];
    if(error != nil) {
        NSLog(@"Something went wrong: %@", error);
        return;
    }
    SCNScene *scene = [[SCNScene alloc] init];
    // ...configure your scene
    [scene.rootNode addChildNode:node];
}
```

## License

```
The MIT License (MIT)

Copyright (c) 2016 Victor Gama

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```
