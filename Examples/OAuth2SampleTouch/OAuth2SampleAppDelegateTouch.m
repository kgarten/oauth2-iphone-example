/* Copyright (c) 2011 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// OAuth2SampleAppDelegateTouch.m

#import "OAuth2SampleAppDelegateTouch.h"
#import "OAuth2SampleRootViewControllerTouch.h"

@implementation OAuth2SampleAppDelegateTouch

@synthesize window = mWindow;
@synthesize navigationController = mNavigationController;

- (void)dealloc {
  self.navigationController = nil;
  self.window = nil;
  [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [mWindow addSubview:[mNavigationController view]];
  [mWindow makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

