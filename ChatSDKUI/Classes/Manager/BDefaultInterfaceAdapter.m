//
//  BDefaultInterfaceAdapter.m
//  Pods
//
//  Created by Benjamin Smiley-andrews on 14/09/2016.
//
//

#import "BDefaultInterfaceAdapter.h"

#import <ChatSDK/ChatCore.h>
#import <ChatSDK/ChatUI.h>
#import <ChatSDK/BChatViewController.h>
#import <ChatSDK/BChatOptionDelegate.h>

#define bControllerKey @"bControllerKey"
#define bControllerNameKey @"bControllerNameKey"

@implementation BDefaultInterfaceAdapter

-(instancetype) init {
    if((self = [super init])) {
        _additionalChatOptions = [NSMutableArray new];
        _additionalTabBarViewControllers = [NSMutableArray new];
        _additionalSearchViewControllers = [NSMutableDictionary new];
        
        // MEM1
        //[[SDWebImageDownloader sharedDownloader] setShouldDecompressImages:NO];
    }
    return self;
}

-(void) addTabBarViewController: (UIViewController *) controller atIndex: (int) index {
    [_additionalTabBarViewControllers addObject:@[controller, @(index)]];
}

-(void) removeTabBarViewControllerAtIndex: (int) index {
    int i = 0;
    BOOL found = false;
    for(NSArray * array in _additionalTabBarViewControllers) {
        if([array[1] intValue] == index) {
            found = true;
            break;
        }
        i++;
    }
    if (found) {
        [_additionalTabBarViewControllers removeObjectAtIndex:i];
    }
}

-(UIViewController *) privateThreadsViewController {
    if (!_privateThreadsViewController) {
        _privateThreadsViewController = [[BPrivateThreadsViewController alloc] init];
    }
    return _privateThreadsViewController;
}

-(UIViewController *) publicThreadsViewController {
    return [[BPublicThreadsViewController alloc] init];
}

-(UIViewController *) flaggedMessagesViewController {
    return [[BFlaggedMessagesViewController alloc] init];
}

-(UIViewController *) contactsViewController {
    return [[BContactsViewController alloc] init];
}

-(BFriendsListViewController *) friendsViewControllerWithUsersToExclude: (NSArray *) usersToExclude {
    return [[BFriendsListViewController alloc] initWithUsersToExclude:usersToExclude];
}

-(UIViewController *) appTabBarViewController {
    return [[BAppTabBarController alloc] initWithNibName:Nil bundle:Nil];
}

-(UIViewController *) profileViewControllerWithUser: (id<PElmUser>) user {
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Profile"
                                                          bundle:[NSBundle chatUIBundle]];
    
    BProfileTableViewController * controller = [storyboard instantiateInitialViewController];
    // TODO: Fix this
    controller.user = user;
    return controller;
}

-(UIViewController *) eulaViewController {
    return [[BEULAViewController alloc] init];
}

-(BChatViewController *) chatViewControllerWithThread: (id<PThread>) thread {
    return [[BChatViewController alloc] initWithThread:thread];
}

-(NSArray *) defaultTabBarViewControllers {
    NSMutableArray * dict = [NSMutableArray arrayWithArray:@[self.privateThreadsViewController,
                                                             self.publicThreadsViewController,
                                                             self.contactsViewController,
                                                             [self profileViewControllerWithUser: Nil]]];
    
    if([BChatSDK config].enableMessageModerationTab) {
        [dict addObject: self.flaggedMessagesViewController];
    }
    
    return dict;
}

-(NSArray *) tabBarViewControllers {
    NSMutableArray * tabs = [NSMutableArray arrayWithArray:[self defaultTabBarViewControllers]];
   
    for(NSArray * tab in _additionalTabBarViewControllers) {
        [tabs insertObject:tab.firstObject atIndex:[tab.lastObject intValue]];
    }
    
    return tabs;
}

-(NSArray *) tabBarNavigationViewControllers {
    NSMutableArray * controllers = [NSMutableArray new];
    for (id vc in self.tabBarViewControllers) {
        [controllers addObject:[[UINavigationController alloc] initWithRootViewController:vc]];
    }
    return controllers;
}

-(NSMutableArray *) chatOptions {
   
    NSMutableArray * options = [NSMutableArray new];
    
    BOOL videoEnabled = NM.videoMessage != Nil;
    BOOL imageEnabled = NM.imageMessage != Nil && [BChatSDK config].imageMessagesEnabled;
    BOOL locationEnabled = NM.locationMessage != Nil && [BChatSDK config].locationMessagesEnabled;
    
    if (imageEnabled && videoEnabled) {
        [options addObject:[[BMediaChatOption alloc] initWithType:bPictureTypeCameraVideo]];
    }
    else if (imageEnabled)  {
        [options addObject:[[BMediaChatOption alloc] initWithType:bPictureTypeCameraImage]];
    }
    
    if (imageEnabled) {
        [options addObject:[[BMediaChatOption alloc] initWithType:bPictureTypeAlbumImage]];
    }
    if (videoEnabled) {
        [options addObject:[[BMediaChatOption alloc] initWithType:bPictureTypeAlbumVideo]];
    }
    if (locationEnabled) {
        [options addObject:[[BLocationChatOption alloc] init]];
    }
    
    for(BChatOption * option in _additionalChatOptions) {
        [options addObject:option];
    }
    
    return options;
    
}

-(UIViewController *) searchViewControllerWithType: (NSString *) type excludingUsers: (NSArray *) users usersAdded: (void(^)(NSArray * users)) usersAdded {

    UIViewController<PSearchViewController> * vc;
    
    if([type isEqualToString:bSearchTypeNameSearch]) {
        vc = [self searchViewControllerExcludingUsers:users usersAdded:usersAdded];
    }
    else {
        vc = _additionalSearchViewControllers[type][bControllerKey];
        if(vc) {
            [vc setSelectedAction:usersAdded];
            [vc setExcludedUsers:users];
        }
    }
    return [[UINavigationController alloc] initWithRootViewController:vc];
    
}

-(NSDictionary *) additionalSearchControllerNames {
    NSMutableDictionary * nameForType = [NSMutableDictionary new];
    for(NSString * key in [_additionalSearchViewControllers allKeys]) {
        nameForType[key] = _additionalSearchViewControllers[key][bControllerNameKey];
    }
    return nameForType;
}

-(void) addSearchViewController: (UIViewController *) controller withType: (NSString *) type withName: (NSString *) name {
    [_additionalSearchViewControllers setObject:@{bControllerKey: controller, bControllerNameKey: name}
                                         forKey:type];
}

-(void) removeSearchViewControllerWithType: (NSString *) type {
    [_additionalSearchViewControllers removeObjectForKey:type];
}


-(UIViewController<PSearchViewController> *) searchViewControllerExcludingUsers: (NSArray *) users usersAdded: (void(^)(NSArray * users)) usersAdded {
    return [[BSearchViewController alloc] initWithUsersToExclude: users];
}

-(void) setChatOptionsHandler:(id<PChatOptionsHandler>)handler {
    _chatOptionsHandler = handler;
}

-(id<PChatOptionsHandler>) chatOptionsHandlerWithDelegate: (id<BChatOptionDelegate>) delegate {
    if (_chatOptionsHandler) {
        _chatOptionsHandler.delegate = delegate;
        return _chatOptionsHandler;
    }
    return [[BChatOptionsActionSheet alloc] initWithDelegate:delegate];
}

-(UIViewController *) usersViewControllerWithThread: (id<PThread>) thread parentNavigationController: (UINavigationController *) parent {
    BUsersViewController * vc = [[BUsersViewController alloc] initWithThread:thread];
    vc.parentNavigationController = parent;
    return vc;
}

-(void) addChatOption: (BChatOption *) option {
    if(![_additionalChatOptions containsObject:option]) {
        [_additionalChatOptions addObject:option];
    }
}

-(void) removeChatOption: (BChatOption *) option {
    if([_additionalChatOptions containsObject:option]) {
        [_additionalChatOptions removeObject:option];
    }
}

-(UIViewController *) settingsViewController {
    return Nil;
}

-(UIColor *) colorForName: (NSString *) name {
    return Nil;
}

-(UIView<PSendBar> *) sendBarView {
    return [[BTextInputView alloc] initWithFrame:CGRectZero];
}

-(BOOL) showLocalNotification: (id) notification {
    return _showLocalNotifications && [BChatSDK config].showLocalNotifications;
}

-(void) setShowLocalNotifications: (BOOL) show {
    _showLocalNotifications = show;
}



@end
