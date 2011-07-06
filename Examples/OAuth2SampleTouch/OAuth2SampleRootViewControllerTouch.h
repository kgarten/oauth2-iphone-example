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

 /* Modification by Quizlet LLC, July, 2011:
  * Added username key.
  */

// OAuth2SampleRootViewControllerTouch.h

@class GTMOAuth2Authentication;

@interface OAuth2SampleRootViewControllerTouch : UIViewController <UINavigationControllerDelegate, UITextFieldDelegate> {
  UISegmentedControl *mServiceSegments;
  UITextField *mClientIDField;
  UITextField *mClientSecretField;
  UITextField *mClientURLField;

  UILabel *mServiceNameField;
  UILabel *mUserNameField;
  UILabel *mAccessTokenField;
  UILabel *mExpirationField;
  UILabel *mRefreshTokenField;

  UIButton *mFetchButton;

  UISwitch *mShouldSaveInKeychainSwitch;

  UIBarButtonItem *mSignInOutButton;

  int mNetworkActivityCounter;
  GTMOAuth2Authentication *mAuth;
}

@property (nonatomic, retain) IBOutlet UITextField *clientIDField;
@property (nonatomic, retain) IBOutlet UITextField *clientSecretField;
@property (nonatomic, retain) IBOutlet UITextField *clientURLField;
@property (nonatomic, retain) IBOutlet UILabel *userNameField;
@property (nonatomic, retain) IBOutlet UILabel *accessTokenField;
@property (nonatomic, retain) IBOutlet UILabel *expirationField;
@property (nonatomic, retain) IBOutlet UILabel *refreshTokenField;
@property (nonatomic, retain) IBOutlet UIButton *fetchButton;
@property (nonatomic, retain) IBOutlet UISwitch *shouldSaveInKeychainSwitch;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *signInOutButton;

@property (nonatomic, retain) GTMOAuth2Authentication *auth;

- (IBAction)signInOutClicked:(id)sender;
- (IBAction)fetchClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToQuizlet;
- (void)signOut;
- (BOOL)isSignedIn;

- (void)updateUI;

@end
