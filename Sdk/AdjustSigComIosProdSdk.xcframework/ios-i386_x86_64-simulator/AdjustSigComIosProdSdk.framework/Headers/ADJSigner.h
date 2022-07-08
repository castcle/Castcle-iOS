//
//  Adjust
//
//  Created by Abdullah Joseph on 17.04.19
//  Copyright © 2019 adjust GmbH. All rights reserved.
//

#ifndef ADJSigner_h
#define ADJSigner_h

#import <Foundation/Foundation.h>

@interface ADJSigner : NSObject

+(void)enableSigning;

+(void)disableSigning;

+(nonnull NSString *)getVersion;

#if defined(EXEC_MODE_STANDALONE)
+ (nonnull NSDictionary *)sign:(nonnull uint8_t *)reqdata withLength:(size_t)len;

#elif defined(EXEC_MODE_ADJUST)
+ (void)sign:(nonnull NSMutableDictionary *)packageDict
 withActivityKind:(nonnull const char *)activityKind
 withSdkVersion:(nonnull const char *)sdkVersion;

#endif

@end

// Trampoline from C to ObjC
void _ADJSigner_sign(size_t argc, void **args);

#endif /* ADJSigner_h */
