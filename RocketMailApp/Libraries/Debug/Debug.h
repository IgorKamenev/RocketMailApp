//
//  Debug.h
//  AngelCo
//
//  Created by Igor Kamenev on 1/23/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#ifndef AngelCo_Debug_h
#define AngelCo_Debug_h

#define TESTING

#ifdef TESTING

#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#else

#define DLog(fmt, ...) {}

#endif

#endif
