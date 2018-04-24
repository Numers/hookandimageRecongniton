//
//  hookdylib.mm
//  hookdylib
//
//  Created by 鲍利成 on 2018/4/2.
//  Copyright (c) 2018年 ___ORGANIZATIONNAME___. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()


@interface hookdylib : NSObject

@end

@implementation hookdylib

-(id)init
{
	if ((self = [super init]))
	{
	}

    return self;
}

@end

CHConstructor // code block that runs immediately upon load
{
	@autoreleasepool
	{
		
        
	}
}
