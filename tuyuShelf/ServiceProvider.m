//
//  ServiceProvider.m
//  tuyuShelf
//
//  Created by Kevin Bradley on 2/11/17.
//
//

#import "ServiceProvider.h"

@interface ServiceProvider ()


@property (nonatomic, strong) NSMutableArray *menuItems;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *playlists;
@end

@implementation ServiceProvider

+ (NSUserDefaults *)sharedUserDefaults
{
    static dispatch_once_t pred;
    static NSUserDefaults* shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.tuyu"];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //[self testGetYTScience];
        self.menuItems = [NSMutableArray new];
        self.channels = [NSMutableArray new];
        self.playlists = [NSMutableArray new];
        //[self testGetYTScience];
    }
    return self;
}

#pragma mark - TVTopShelfProvider protocol

- (TVTopShelfContentStyle)topShelfStyle {
    // Return desired Top Shelf style.
    return TVTopShelfContentStyleSectioned;
}

- (void)testGetYTScience
{
   // NSLog(@"appCookies: %@", [[ServiceProvider sharedUserDefaults] valueForKey:@"ApplicationCookie"]);
    NSData *cookieData = [[ServiceProvider sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
     //       NSLog(@"cookie: %@", cookie);
        }
    }
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        //DLog(@"searchDeets: %@", searchDetails);
        self.menuItems = searchDetails[@"results"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
        
    } failureBlock:^(NSString *error) {
        
        DLog(@"error: %@", error);
    }];
    
    if ([[KBYourTube sharedInstance] isSignedIn] == YES)
    {
        DLog(@"is signed in, get those sciences too!");
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            
            NSArray <KBYTSearchResult *> *results = outputResults[@"results"];
            NSArray <KBYTSearchResult *> *rChannels = outputResults[@"channels"];
            [results enumerateObjectsUsingBlock:^(KBYTSearchResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                if (obj.resultType == YTSearchResultTypeChannel)
                {
                    [self.channels addObject:obj];
                    
                } else if (obj.resultType == YTSearchResultTypePlaylist)
                {
                    [self.playlists addObject:obj];
                }
                
            }];
            [self.channels addObjectsFromArray:rChannels];
            [[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
            
        } failureBlock:^(NSString *error) {
            //
        }];
    }
    
}

/*

private func urlForIdentifier(identifier: String) -> NSURL {
    let components = NSURLComponents()
    components.scheme = "newsapp"
    components.queryItems = [NSURLQueryItem(name: "identifier",
                                            value: identifier)] return components.URL!
}*/

- (NSURL *)urlForIdentifier:(NSString*)identifier type:(NSString *)type
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"tuyu://%@/%@", type, identifier]];
}


- (NSArray *)topShelfItems {
    // Create an array of TVContentItems.
    
    if (self.menuItems.count == 0)
    {
        [self testGetYTScience];
    }
   // [self testGetYTScience];
   
    __block NSMutableArray *suggestedItems = [NSMutableArray new];
    __block NSMutableArray *channelItems = [NSMutableArray new];
    __block NSMutableArray *playlistItems = [NSMutableArray new];
    __block NSMutableArray *sectionItems = [NSMutableArray new];
    
    if (self.channels.count > 0)
    {
        TVContentIdentifier *csection = [[TVContentIdentifier alloc] initWithIdentifier:@"channels" container:nil];
        TVContentItem * cItem = [[TVContentItem alloc] initWithContentIdentifier:csection];
        cItem.title = @"Channels";
        [self.channels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            KBYTSearchResult *result = (KBYTSearchResult *)obj;
            TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
            TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
            ci.title = result.title;
            ci.imageURL = [NSURL URLWithString:result.imagePath];
            ci.displayURL = [self urlForIdentifier:result.videoId type:result.readableSearchType];
            [channelItems addObject:ci];
            
        }];
        cItem.topShelfItems = channelItems;
        [sectionItems addObject:cItem];
    }
    
    if (self.playlists.count > 0)
    {
        TVContentIdentifier *psection = [[TVContentIdentifier alloc] initWithIdentifier:@"playlists" container:nil];
        TVContentItem * pItem = [[TVContentItem alloc] initWithContentIdentifier:psection];
        pItem.title = @"Playlists";
        [self.playlists enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            KBYTSearchResult *result = (KBYTSearchResult *)obj;
            TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
            TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
            ci.title = result.title;
            ci.imageURL = [NSURL URLWithString:result.imagePath];
            
            NSURLComponents *comp = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"tuyu://%@/%@", result.readableSearchType, result.videoId]];
            comp.query = [NSString stringWithFormat:@"title=%@", result.title];
            DLog(@"url: %@", comp.URL);
            ci.displayURL = comp.URL;
            [playlistItems addObject:ci];
        
        }];
        pItem.topShelfItems = playlistItems;
        [sectionItems addObject:pItem];
    }
    
    TVContentIdentifier *section = [[TVContentIdentifier alloc] initWithIdentifier:@"science" container:nil];
    TVContentItem * sectionItem = [[TVContentItem alloc] initWithContentIdentifier:section];
    sectionItem.title = @"Suggestions";
    
    [self.menuItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        KBYTSearchResult *result = (KBYTSearchResult *)obj;
        TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
        TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
        ci.title = result.title;
        ci.imageURL = [NSURL URLWithString:result.imagePath];
        ci.displayURL = [self urlForIdentifier:result.videoId type:result.readableSearchType];
        [suggestedItems addObject:ci];
        
    }];

    sectionItem.topShelfItems = suggestedItems;
    [sectionItems addObject:sectionItem];
    
    return sectionItems;
}

@end
