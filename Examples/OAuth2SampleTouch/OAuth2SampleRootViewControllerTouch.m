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

/* Modifications by Quizlet LLC: July, 2011.
 * 
 * Modifications were to replace all calls to use the Quizlet endpoints
 * and API. 
 *
 * All unused functions, parameters (including google and dailymotion references)
 * were removed.
 */

// OAuth2SampleRootViewControllerTouch.m

#import "OAuth2SampleRootViewControllerTouch.h"
#import "GTMOAuth2ViewControllerTouch.h"

static NSString *const kKeychainItemName = @"Quizlet Example";
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";

static NSString *const kQuizletAppServiceName = @"OAuth Sample: Quizlet";
static NSString *const kQuizletServiceName = @"Quizlet";

static NSString *const kSampleClientIDKey = @"clientID";
static NSString *const kSampleClientSecretKey = @"clientSecret";
static NSString *const kSampleClientURLKey = @"clientURL";

@interface OAuth2SampleRootViewControllerTouch()
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
- (void)incrementNetworkActivity:(NSNotification *)notify;
- (void)decrementNetworkActivity:(NSNotification *)notify;
- (void)signInNetworkLostOrFound:(NSNotification *)notify;
- (GTMOAuth2Authentication *)authForQuizlet;
- (void)doAnAuthenticatedAPIFetch;
- (void)displayAlertWithMessage:(NSString *)str;
- (BOOL)shouldSaveInKeychain;
- (void)saveClientIDValues;
- (void)loadClientIDValues;

@end

@implementation OAuth2SampleRootViewControllerTouch

@synthesize clientIDField = mClientIDField,
            clientSecretField = mClientSecretField,
            clientURLField = mClientURLField,
            userNameField = mUserNameField,
            expirationField = mExpirationField,
            accessTokenField = mAccessTokenField,
            refreshTokenField = mRefreshTokenField,
            fetchButton = mFetchButton,
            shouldSaveInKeychainSwitch = mShouldSaveInKeychainSwitch,
            signInOutButton = mSignInOutButton;

@synthesize auth = mAuth;

// NSUserDefaults keys
static NSString *const kQuizletClientIDKey     = @"QuizletClientID";
static NSString *const kQuizletClientSecretKey = @"QuizletClientSecret";
static NSString *const kQuizletClientURLKey    = @"QuizletClientURL";


- (void)awakeFromNib {
  // Listen for network change notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(incrementNetworkActivity:) name:kGTMOAuth2FetchStarted object:nil];
  [nc addObserver:self selector:@selector(decrementNetworkActivity:) name:kGTMOAuth2FetchStopped object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkLost  object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkFound object:nil];

  // Fill in the Client ID and Client Secret text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  GTMOAuth2Authentication *auth = nil;

    // Try getting authorization from the keychain
    NSString *clientID = [defaults stringForKey:kQuizletClientIDKey];
    NSString *clientSecret = [defaults stringForKey:kQuizletClientSecretKey];
    NSString *clientURL = [defaults stringForKey:kQuizletClientURLKey];
	
    if (clientID && clientSecret) {
      auth = [self authForQuizlet];
      if (auth) {
        auth.clientID = clientID;
        auth.clientSecret = clientSecret;
        auth.redirectURI = clientURL;
      }
    }

  // Save the authentication object, which holds the auth tokens
  self.auth = auth;
	
  // Update the client ID value text fields to match the radio button selection
  [self loadClientIDValues];

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
  [self updateUI];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.clientIDField = nil;
  self.clientSecretField = nil;
  self.clientURLField = nil;
  self.userNameField = nil;
  self.accessTokenField = nil;
  self.expirationField = nil;
  self.refreshTokenField = nil;
  self.fetchButton = nil;

  self.shouldSaveInKeychainSwitch = nil;
  self.signInOutButton = nil;

  self.auth = nil;

  [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
  // Returns non-zero on iPad, but backward compatible to SDKs earlier than 3.2.
  if (UI_USER_INTERFACE_IDIOM()) {
    return YES;
  }
  return [super shouldAutorotateToInterfaceOrientation:orientation];
}

- (BOOL)isSignedIn {
  BOOL isSignedIn = self.auth.canAuthorize;
  return isSignedIn;
}


- (IBAction)signInOutClicked:(id)sender {
  [self saveClientIDValues];

  if (![self isSignedIn]) {
    // Sign in
    [self signInToQuizlet];
  } else {
    // Sign out
    [self signOut];
  }
  [self updateUI];
}

- (IBAction)fetchClicked:(id)sender {
  // Just to prove we're signed in, we'll attempt an authenticated fetch for the
  // signed-in user
  [self doAnAuthenticatedAPIFetch];
}

// UISwitch does the toggling for us. We just need to read the state.
- (IBAction)toggleShouldSaveInKeychain:(UISwitch *)sender {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:sender.isOn forKey:kShouldSaveInKeychainKey];
}

- (void)signOut {

  // remove the stored Quizlet authentication from the keychain, if any
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kQuizletAppServiceName];

  // Discard our retained authentication object.
  self.auth = nil;

  [self updateUI];
}

- (GTMOAuth2Authentication *)authForQuizlet {
  // http://www.dailymotion.com/doc/api/authentication.html
  NSURL *tokenURL = [NSURL URLWithString:@"https://www.quizlet.com/token"];

  // This redirectURI must be the same domain as the one you registered with. 
  // OAuth 2 (draft 16) stipulates we must check the redirect URI given matches the one we
  // have stored on our authorization server.
	
  // The controller will watch for the server to redirect the web view to this URI,
  // but this URI will not be loaded, so it need not be for any actual web page.
  // NB: You would not normally have this coming in from a user field. Just like your client ID and secret, 
  //     this would be hard-coded in your application.
  NSString *redirectURI = self.clientURLField.text;
  NSString *clientID = self.clientIDField.text;
  NSString *clientSecret = self.clientSecretField.text;


  GTMOAuth2Authentication *auth;
  auth = [GTMOAuth2Authentication authenticationWithServiceProvider:kQuizletServiceName
                                                           tokenURL:tokenURL
                                                        redirectURI:redirectURI
                                                           clientID:clientID
                                                       clientSecret:clientSecret];
  return auth;
}s

- (void)signInToQuizlet {
  [self signOut];

  GTMOAuth2Authentication *auth = [self authForQuizlet];
  auth.scope = @"read"; // Request "read" scope only. See the API2.0 documentation for other scopes you can use.

  if ([auth.clientID length] == 0 || [auth.clientSecret length] == 0 || [auth.redirectURI length] == 0) {
    NSString *msg = @"The example code requires a valid redirect URI, client ID and client secret to sign in.";
    [self displayAlertWithMessage:msg];
    return;
  }

  NSString *keychainItemName = nil;
  if ([self shouldSaveInKeychain]) {
    keychainItemName = kKeychainItemName;
  }

  NSURL *authURL = [NSURL URLWithString:@"https://www.quizlet.com/authorize?mobile=true"];

  // Display the authentication view
  GTMOAuth2ViewControllerTouch *viewController;
  viewController = [[[GTMOAuth2ViewControllerTouch alloc] initWithAuthentication:auth
                                                                authorizationURL:authURL
                                                                keychainItemName:keychainItemName
                                                                        delegate:self
                                                                finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];

  // We can set a URL for deleting the cookies after sign-in so the next time
  // the user signs in, the browser does not assume the user is already signed
  // in
  viewController.browserCookiesURL = [NSURL URLWithString:@"https://www.quizlet.com/"];

  // You can set the title of the navigationItem of the controller here, if you want

  // Now push our sign-in view
  [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
  if (error != nil) {
    // Authentication failed (perhaps the user denied access, or closed the
    // window before granting access)
    NSLog(@"Authentication error: %@", error);
	  NSLog(@"Authentication error: %@", [[error userInfo] objectForKey:@"error"]);
	  NSString *errorType = [[error userInfo] objectForKey:@"error"];
	  if ([errorType isEqualToString:@"access_denied"]) {
		NSString *msg = (@"The user denied you access");
		[self displayAlertWithMessage:msg];
	  }

    NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
    if ([responseData length] > 0) {
      // show the body of the server's authentication failure response
      NSString *str = [[[NSString alloc] initWithData:responseData
                                             encoding:NSUTF8StringEncoding] autorelease];
      NSLog(@"%@", str);
		
    }
	  
    self.auth = nil;
  } else {
    // Authentication succeeded
	  
   NSString *msg = (@"The user granted access!");
   [self displayAlertWithMessage:msg];
	  
    //
    // At this point, we either use the authentication object to explicitly
    // authorize requests, like
    //
    //  [auth authorizeRequest:myNSURLMutableRequest
    //       completionHandler:^(NSError *error) {
    //         if (error == nil) {
    //           // request here has been authorized
    //         }
    //       }];
    //
    // or store the authentication object into a fetcher or a Google API service
    // object like
    //
    //   [fetcher setAuthorizer:auth];

    // save the authentication object
    self.auth = auth;
  }

  [self updateUI];
}

- (void)doAnAuthenticatedAPIFetch {

  // Quizlet : my sets 
  NSString *urlStr = [NSString stringWithFormat:@"https://api.quizlet.com/2.0/user/%@/sets", self.auth.userName];

  NSURL *url = [NSURL URLWithString:urlStr];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [self.auth authorizeRequest:request
            completionHandler:^(NSError *error) {
              NSString *output = nil;
              if (error) {
                output = [error description];
              } else {
                // Synchronous fetches like this are a really bad idea in Cocoa applications
                //
                // For a very easy async alternative, we could use GTMHTTPFetcher
                NSError *error = nil;
                NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
                if (data) {
                  // API fetch succeeded
                  output = [[[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding] autorelease];
                } else {
                  // fetch failed
                  output = [error description];
                }
              }

              [self displayAlertWithMessage:output];

              // the access token may have changed
              [self updateUI];
            }];
}

#pragma mark -

- (void)incrementNetworkActivity:(NSNotification *)notify {
  ++mNetworkActivityCounter;
  if (mNetworkActivityCounter == 1) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:YES];
  }
}

- (void)decrementNetworkActivity:(NSNotification *)notify {
  --mNetworkActivityCounter;
  if (mNetworkActivityCounter == 0) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:NO];
  }
}

- (void)signInNetworkLostOrFound:(NSNotification *)notify {
  if ([[notify name] isEqual:kGTMOAuth2NetworkLost]) {
    // network connection was lost; alert the user, or dismiss
    // the sign-in view with
    //   [[[notify object] delegate] cancelSigningIn];
  } else {
    // network connection was found again
  }
}

#pragma mark -

- (void)updateUI {
  // update the text showing the signed-in state and the button title
  // A real program would use NSLocalizedString() for strings shown to the user.
	
	if ([self isSignedIn] && [self.auth.accessToken length] > 0) {
		self.accessTokenField.text = self.auth.accessToken;
	} else {
		self.accessTokenField.text = @"-No access token-";
	}
	if ([self isSignedIn] && [self.auth.refreshToken length] > 0) {
		self.refreshTokenField.text = self.auth.refreshToken;
	} else {
		self.refreshTokenField.text = @"-No refresh token-";
	}
	if ([self isSignedIn] && [[self.auth.expirationDate description] length] > 0) {
		self.expirationField.text = [self.auth.expirationDate description];
	} else {
		self.expirationField.text = @"-No expiry date-";
	}
	
	
  if ([self isSignedIn]) {

    // signed in
    self.userNameField.text = self.auth.userName;
    self.signInOutButton.title = @"Sign Out";
    self.fetchButton.enabled = YES;
  } else {
    // signed out
    self.userNameField.text = @"-Not signed in-";
    self.signInOutButton.title = @"Sign In";
    self.fetchButton.enabled = NO;
  }

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
}

- (void)displayAlertWithMessage:(NSString *)message {
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Quizlet API 2.0 Example"
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil] autorelease];
  [alert show];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self saveClientIDValues];
}

- (BOOL)shouldSaveInKeychain {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL flag = [defaults boolForKey:kShouldSaveInKeychainKey];
  return flag;
}

#pragma mark Client ID and Secret

//
// Normally an application will hardwire the client ID and client secret
// strings in the source code.  This sample app has to allow them to be
// entered by the developer, so we'll save them across runs into preferences.
//

- (void)saveClientIDValues {
  // Save the client ID and secret from the text fields into the prefs
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *clientID = self.clientIDField.text;
  NSString *clientSecret = self.clientSecretField.text;
  NSString *clientURL = self.clientURLField.text;

  [defaults setObject:clientID forKey:kQuizletClientIDKey];
  [defaults setObject:clientSecret forKey:kQuizletClientSecretKey];
  [defaults setObject:clientURL forKey:kQuizletClientURLKey];
}

- (void)loadClientIDValues {
  // Load the client ID and secret from the prefs into the text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  self.clientIDField.text = [defaults stringForKey:kQuizletClientIDKey];
  self.clientSecretField.text = [defaults stringForKey:kQuizletClientSecretKey];
  self.clientURLField.text = [defaults stringForKey:kQuizletClientURLKey];
	
}

@end
