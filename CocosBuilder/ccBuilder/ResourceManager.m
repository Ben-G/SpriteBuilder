/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "CCBSpriteSheetParser.h"
#import "CCBAnimationParser.h"
#import "CCBGlobals.h"
#import "CocosBuilderAppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"
#import "ProjectSettings.h"
#import "CCBFileUtil.h"
#import <CoreGraphics/CGImage.h>
#import <QTKit/QTKit.h>
#import "CCBPublisher.h"

#pragma mark RMSpriteFrame

@implementation RMSpriteFrame

@synthesize spriteFrameName, spriteSheetFile;

- (void) dealloc
{
    [spriteFrameName release];
    [spriteSheetFile release];
    [super dealloc];
}

- (NSImage*) preview
{
    return [CCBSpriteSheetParser imageNamed:spriteFrameName fromSheet:spriteSheetFile];
}

@end


#pragma mark RMAnimation

@implementation RMAnimation

@synthesize animationFile, animationName;

- (void) dealloc
{
    self.animationFile = NULL;
    self.animationName = NULL;
    [super dealloc];
}

@end


#pragma mark RMResource

@implementation RMResource

@synthesize type, modifiedTime, touched, data, filePath;

- (void) loadData
{
    if (type == kCCBResTypeSpriteSheet)
    {
        NSArray* spriteFrameNames = [CCBSpriteSheetParser listFramesInSheet:filePath];
        NSMutableArray* spriteFrames = [NSMutableArray arrayWithCapacity:[spriteFrameNames count]];
        for (NSString* frameName in spriteFrameNames)
        {
            RMSpriteFrame* frame = [[[RMSpriteFrame alloc] init] autorelease];
            frame.spriteFrameName = frameName;
            frame.spriteSheetFile = self.filePath;
            
            [spriteFrames addObject:frame];
        }
        self.data = spriteFrames;
    }
    else if (type == kCCBResTypeAnimation)
    {
        NSArray* animationNames = [CCBAnimationParser listAnimationsInFile:filePath];
        NSMutableArray* animations = [NSMutableArray arrayWithCapacity:[animationNames count]];
        for (NSString* animationName in animationNames)
        {
            RMAnimation* anim = [[[RMAnimation alloc] init] autorelease];
            anim.animationName = animationName;
            anim.animationFile = self.filePath;
            
            [animations addObject:anim];
        }
        self.data = animations;
    }
    else if (type == kCCBResTypeDirectory)
    {
        // Ignore changed directories
    }
    else
    {
        self.data = NULL;
    }
}

- (NSString*) relativePath
{
    return [ResourceManagerUtil relativePathFromAbsolutePath: self.filePath];
}

- (NSImage*) previewForResolution:(NSString *)res
{
    if (!res) res = @"auto";
    
    if (type == kCCBResTypeImage)
    {
        NSString* fileName = [filePath lastPathComponent];
        NSString* dirPath = [filePath stringByDeletingLastPathComponent];
        NSString* resDirName = [@"resources-" stringByAppendingString:res];
        
        NSString* autoPath = [[dirPath stringByAppendingPathComponent:resDirName] stringByAppendingPathComponent:fileName];
        
        NSImage* img = [[[NSImage alloc] initWithContentsOfFile:autoPath] autorelease];
        //if (!img)
        //{
        //    img = [[[NSImage alloc] initWithContentsOfFile:filePath] autorelease];
        //}
        return img;
    }
    
    return NULL;
}

- (NSComparisonResult) compare:(id) obj
{
    RMResource* res = obj;
    
    if (res.type < self.type)
    {
        return NSOrderedDescending;
    }
    else if (res.type > self.type)
    {
        return NSOrderedAscending;
    }
    else
    {
        return [[self.filePath lastPathComponent] compare:[res.filePath lastPathComponent] options:NSNumericSearch|NSForcedOrderingSearch|NSCaseInsensitiveSearch];
    }
}

// Paste board

- (id) pasteboardPropertyListForType:(NSString *)pbType
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if ([pbType isEqualToString:@"com.cocosbuilder.RMResource"])
    {
        [dict setObject:[NSNumber numberWithInt:type] forKey:@"type"];
        [dict setObject:filePath forKey:@"filePath"];
        return dict;
    }
    else if ([pbType isEqualToString:@"com.cocosbuilder.texture"])
    {
        [dict setObject:self.relativePath forKey:@"spriteFile"];
        return dict;
    }
    else if ([pbType isEqualToString:@"com.cocosbuilder.ccb"])
    {
        [dict setObject:self.relativePath forKey:@"ccbFile"];
        return dict;
    }
    return NULL;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray* pbTypes = [NSMutableArray arrayWithObject: @"com.cocosbuilder.RMResource"];
    if (type == kCCBResTypeImage)
    {
        [pbTypes addObject:@"com.cocosbuilder.texture"];
    }
    else if (type == kCCBResTypeCCBFile)
    {
        [pbTypes addObject:@"com.cocosbuilder.ccb"];
    }
    
    return pbTypes;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)pbType pasteboard:(NSPasteboard *)pasteboard
{
    if ([pbType isEqualToString:@"com.cocosbuilder.RMResource"]) return NSPasteboardWritingPromised;
    if ([pbType isEqualToString:@"com.cocosbuilder.texture"] && type == kCCBResTypeImage) return NSPasteboardWritingPromised;
    if ([pbType isEqualToString:@"com.cocosbuilder.ccb"] && type == kCCBResTypeCCBFile) return NSPasteboardWritingPromised;
    return 0;
}

// ImageKit representation

- (NSString *) imageUID
{
    return self.relativePath;
}

- (NSString *) imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id) imageRepresentation
{
    if (self.type == kCCBResTypeImage)
    {
        NSFileManager* fm = [NSFileManager defaultManager];
        
        NSString* dir = [self.filePath stringByDeletingLastPathComponent];
        NSString* file = [self.filePath lastPathComponent];
        NSString* autoPath = [[dir stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:file];
        
        if ([fm fileExistsAtPath:autoPath]) return autoPath;
        else return NULL;
    }
    else
    {
        return NULL;
    }
}

- (NSUInteger) imageVersion
{
    if (self.type == kCCBResTypeImage)
    {
        NSFileManager* fm = [NSFileManager defaultManager];
        
        NSString* dir = [self.filePath stringByDeletingLastPathComponent];
        NSString* file = [self.filePath lastPathComponent];
        NSString* autoPath = [[dir stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:file];
        
        if ([fm fileExistsAtPath:autoPath])
        {
            NSDate* fileDate = [CCBFileUtil modificationDateForFile:autoPath];
            return ((NSUInteger)[fileDate timeIntervalSinceReferenceDate]);
        }
        else return 0;
    }
    else
    {
        return 0;
    }
}

- (NSString *) imageTitle
{
    return [[self.filePath lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL) isSelectable
{
    return NO;
}

// Deallocation

- (void) dealloc
{
    [data release];
    [modifiedTime release];
    [filePath release];
    [super dealloc];
}

@end


#pragma mark RMDirectory

@implementation RMDirectory

//@synthesize isDynamicSpriteSheet;

@synthesize count;
@synthesize dirPath;
@synthesize resources;
@synthesize any;
@synthesize images;
@synthesize animations;
@synthesize bmFonts;
@synthesize ttfFonts;
@synthesize ccbFiles;
@synthesize audioFiles;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    resources = [[NSMutableDictionary alloc] init];
    any = [[NSMutableArray alloc] init];
    images = [[NSMutableArray alloc] init];
    animations = [[NSMutableArray alloc] init];
    bmFonts = [[NSMutableArray alloc] init];
    ttfFonts = [[NSMutableArray alloc] init];
    ccbFiles = [[NSMutableArray alloc] init];
    audioFiles = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSArray*)resourcesForType:(int)type
{
    if (type == kCCBResTypeNone) return any;
    if (type == kCCBResTypeImage) return images;
    if (type == kCCBResTypeBMFont) return bmFonts;
    if (type == kCCBResTypeTTF) return ttfFonts;
    if (type == kCCBResTypeAnimation) return animations;
    if (type == kCCBResTypeCCBFile) return ccbFiles;
    if (type == kCCBResTypeAudio) return audioFiles;
    return NULL;
}

- (BOOL) isDynamicSpriteSheet
{
    if (dirPath)
    {
        ProjectSettings* projectSettings = [CocosBuilderAppDelegate appDelegate].projectSettings;
        
        RMResource* dirRes = [[[RMResource alloc] init] autorelease];
        dirRes.type = kCCBResTypeDirectory;
        dirRes.filePath = dirPath;
        
        if (projectSettings)
        {
            BOOL isSmartSpriteSheet = [[projectSettings valueForResource:dirRes andKey:@"isSmartSpriteSheet"] boolValue];
            return isSmartSpriteSheet;
        }
    }
    return NO;
}

- (void) setDirPath:(NSString *)dp
{
    if (dp != dirPath)
    {
        [dirPath release];
        dirPath = [dp retain];
    }
}

- (void) dealloc
{
    [resources release];
    [any release];
    [images release];
    [animations release];
    [bmFonts release];
    [ttfFonts release];
    [ccbFiles release];
    [audioFiles release];
    [dirPath release];
    [super dealloc];
}

- (NSComparisonResult) compare:(RMDirectory*)dir
{
    return [dirPath compare:dir.dirPath];
}

@end


#pragma mark ResourceManager

@implementation ResourceManager

@synthesize directories;
@synthesize activeDirectories;
@synthesize systemFontList;
@synthesize tooManyDirectoriesAdded;

#define kIgnoredExtensionsKey @"ignoredDirectoryExtensions"

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSArray arrayWithObjects:@"git", @"svn", @"xcodeproj", nil], 
      kIgnoredExtensionsKey,
      nil]];
}

- (BOOL)shouldPrunePath:(NSString *)dirPath {
    // prune directories...
    for (NSString *extension in [[NSUserDefaults standardUserDefaults] objectForKey:kIgnoredExtensionsKey]) {
        if ([dirPath hasSuffix:extension]) {
            return YES;
        }
        else if ([dirPath hasPrefix:@"."]) {
            return YES;
        }
    }
    return NO;
}

+ (ResourceManager*) sharedManager
{
    
    static ResourceManager* rm = NULL;
    if (!rm) rm = [[ResourceManager alloc] init];
    return rm;
}

- (void) loadFontListTTF
{
    NSMutableDictionary* fontInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FontListTTF" ofType:@"plist"]];
    systemFontList = [fontInfo objectForKey:@"supportedFonts"];
    [systemFontList retain];
}

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    directories = [[NSMutableDictionary alloc] init];
    activeDirectories = [[NSMutableArray alloc] init];
    pathWatcher = [[SCEvents alloc] init];
    pathWatcher.ignoreEventsFromSubDirs = YES;
    pathWatcher.delegate = self;
    resourceObserver = [[NSMutableArray alloc] init];
    
    [self loadFontListTTF];
    
    return self;
}

- (void) dealloc
{
    [pathWatcher release];
    [directories release];
    [activeDirectories release];
    [resourceObserver release];
    [systemFontList release];
    self.activeDirectories = NULL;
    [super dealloc];
}

- (NSArray*) getAddedDirs
{
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:[directories count]];
    for (NSString* dirPath in directories)
    {        
        [arr addObject:dirPath];
    }
    return arr;
}



- (void) updatedWatchedPaths
{
    if (pathWatcher.isWatchingPaths)
    {
        [pathWatcher stopWatchingPaths];
    }
    [pathWatcher startWatchingPaths:[self getAddedDirs]];
}

- (void) notifyResourceObserversResourceListUpdated
{
    for (id observer in resourceObserver)
    {
        if ([observer respondsToSelector:@selector(resourceListUpdated)])
        {
            [observer performSelector:@selector(resourceListUpdated)];
        }
    }
}

+ (NSArray*) resIndependentExts
{
    return [NSArray arrayWithObjects:@"@2x",@"-phone",@"-tablet",@"-tablethd", @"-phonehd", @"-html5", @"-auto", nil];
}

+ (NSArray*) resIndependentDirs
{
    return [NSArray arrayWithObjects:@"resources-phone", @"resources-phonehd", @"resources-tablet", @"resources-tablethd", @"resources-html5", @"resources-auto", nil];
}

+ (BOOL) isResolutionDependentFile: (NSString*) file
{
    if ([[file pathExtension] isEqualToString:@"ccb"]) return NO;
    
    NSString* fileNoExt = [file stringByDeletingPathExtension];
    
    NSArray* resIndependentExts = [ResourceManager resIndependentExts];
    
    for (NSString* ext in resIndependentExts)
    {
        if ([fileNoExt hasSuffix:ext]) return YES;
    }
    
    return NO;
}

+ (int) getResourceTypeForFile:(NSString*) file
{
    NSString* ext = [[file pathExtension] lowercaseString];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    BOOL isDirectory;
    [fm fileExistsAtPath:file isDirectory:&isDirectory];
    
    if (isDirectory)
    {
        // Hide resolution directories
        if ([[ResourceManager resIndependentDirs] containsObject:[file lastPathComponent]])
        {
            return kCCBResTypeNone;
        }
        else
        {
            return kCCBResTypeDirectory;
        }
    }
    //else if ([[file stringByDeletingPathExtension] hasSuffix:@"-hd"]
    //         || [[file stringByDeletingPathExtension] hasSuffix:@"@2x"])
    else if ([self isResolutionDependentFile:file])
    {
        // Ignore -hd files
        return kCCBResTypeNone;
    }
    else if ([ext isEqualToString:@"png"]
        || [ext isEqualToString:@"jpg"]
        || [ext isEqualToString:@"jpeg"])
    {
        return kCCBResTypeImage;
    }
    else if ([ext isEqualToString:@"fnt"])
    {
        return kCCBResTypeBMFont;
    }
    else if ([ext isEqualToString:@"ttf"])
    {
        return kCCBResTypeTTF;
    }
    else if ([ext isEqualToString:@"plist"]
             && [CCBSpriteSheetParser isSpriteSheetFile:file])
    {
        return kCCBResTypeSpriteSheet;
    }
    else if ([ext isEqualToString:@"plist"]
             && [CCBAnimationParser isAnimationFile:file])
    {
        return kCCBResTypeAnimation;
    }
    else if ([ext isEqualToString:@"ccb"])
    {
        return kCCBResTypeCCBFile;
    }
    else if ([ext isEqualToString:@"js"])
    {
        return kCCBResTypeJS;
    }
    else if ([ext isEqualToString:@"json"])
    {
        return kCCBResTypeJSON;
    }
    else if ([ext isEqualToString:@"wav"]
             || [ext isEqualToString:@"mp3"]
             || [ext isEqualToString:@"m4a"]
             || [ext isEqualToString:@"caf"])
    {
        return kCCBResTypeAudio;
    }
    else if ([ext isEqualToString:@"ccbspritesheet"])
    {
        return kCCBResTypeGeneratedSpriteSheetDef;
    }
    return kCCBResTypeNone;
}

- (void) clearTouchedForResInDir:(RMDirectory*)dir
{
    NSDictionary* resources = dir.resources;
    for (NSString* file in resources)
    {
        RMResource* res = [resources objectForKey:file];
        res.touched = NO;
    }
}

- (void) updateResourcesForPath:(NSString*) path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    RMDirectory* dir = [directories objectForKey:path];
    
    NSArray* resolutionDirs = [ResourceManager resIndependentDirs];
    
    // Get files from default directory
    NSMutableSet* files = [NSMutableSet setWithArray:[fm contentsOfDirectoryAtPath:path error:NULL]];
    
    for (NSString* resolutionExt in resolutionDirs)
    {
        NSString* resolutionDir = [path stringByAppendingPathComponent:resolutionExt];
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:resolutionDir isDirectory:&isDir] && isDir) continue;
        
        [files addObjectsFromArray:[fm contentsOfDirectoryAtPath:resolutionDir error:NULL]];
    }
    
    NSMutableDictionary* resources = dir.resources;
    
    if (!resources)
    {
        [self updateResourcesForPath:[path stringByDeletingLastPathComponent]];
        return;
    }
    
    BOOL needsUpdate = NO; // Assets needs to be reloaded in editor
    BOOL resourcesChanged = NO;  // A resource file was modified, added or removed
    
    [self clearTouchedForResInDir:dir];
    
    for (NSString* fileShort in files)
    {
        NSString* file = [path stringByAppendingPathComponent:fileShort];
     
        if ([self shouldPrunePath:file]) continue;
        
        RMResource* res = [resources objectForKey:file];
        NSDictionary* attr = [fm attributesOfItemAtPath:file error:NULL];
        NSDate* modifiedTime = [attr fileModificationDate];
        
        if (res)
        {
            // Update generated sprite sheets
            if (res.type == kCCBResTypeDirectory)
            {
                NSLog(@"CHECK DIR %@", res.filePath);
                
                RMDirectory* dir = res.data;
                BOOL oldValue = dir.isDynamicSpriteSheet;
                //[dir updateIsDynamicSpriteSheet];
                if (oldValue != dir.isDynamicSpriteSheet)
                {
                    resourcesChanged = YES;
                    NSLog(@"RESOURCES CHANGED!");
                }
            }
            
            if ([res.modifiedTime compare:modifiedTime] == NSOrderedSame)
            {
                // Skip files that are not modified
                res.touched = YES;
                continue;
            }
            else if ([[CocosBuilderAppDelegate appDelegate].currentDocument.fileName isEqualToString: file])
            {
                // Skip the current document
                res.touched = YES;
                continue;
            }
            else
            {
                // A resource has been modified, we need to reload assets
                res.modifiedTime = modifiedTime;
                res.type = [ResourceManager getResourceTypeForFile:file];
                
                // Reload its data
                [res loadData];
                
                if (res.type == kCCBResTypeSpriteSheet
                    || res.type == kCCBResTypeAnimation
                    || res.type == kCCBResTypeImage
                    || res.type == kCCBResTypeBMFont
                    || res.type == kCCBResTypeTTF
                    || res.type == kCCBResTypeCCBFile
                    || res.type == kCCBResTypeAudio
                    || res.type == kCCBResTypeGeneratedSpriteSheetDef)
                {
                    needsUpdate = YES;
                }
                resourcesChanged = YES;
            }
        }
        else
        {
            // This is a new resource, add it!
            res = [[RMResource alloc] init];
            res.modifiedTime = modifiedTime;
            res.type = [ResourceManager getResourceTypeForFile:file];
            res.filePath = file;
            
            // Load basic resource data if neccessary
            [res loadData];
            
            // Check if it is a directory
            if (res.type == kCCBResTypeDirectory)
            {
                [self addDirectory:file];
                res.data = [directories objectForKey:file];
            }
            
            [resources setObject:res forKey:file];
            
            if (res.type != kCCBResTypeNone) resourcesChanged = YES;
            [res release];
        }
        
        res.touched = YES;
    }
    
    // Check for deleted files
    NSMutableArray* removedFiles = [NSMutableArray array];
    
    for (NSString* file in resources)
    {
        RMResource* res = [resources objectForKey:file];
        if (!res.touched)
        {
            [removedFiles addObject:file];
            needsUpdate = YES;
            if (res.type != kCCBResTypeNone) resourcesChanged = YES;
        }
    }
    
    // Remove references to files marked for deletion
    for (NSString* file in removedFiles)
    {
        [resources removeObjectForKey:file];
    }
    
    // Update arrays for different resources
    if (resChanged)
    {
        [dir.any removeAllObjects];
        [dir.images removeAllObjects];
        [dir.animations removeAllObjects];
        [dir.bmFonts removeAllObjects];
        [dir.ttfFonts removeAllObjects];
        [dir.ccbFiles removeAllObjects];
        [dir.audioFiles removeAllObjects];
        
        for (NSString* file in resources)
        {
            RMResource* res = [resources objectForKey:file];
            if (res.type == kCCBResTypeImage
                || res.type == kCCBResTypeSpriteSheet
                || res.type == kCCBResTypeDirectory)
            {
                [dir.images addObject:res];
            }
            if (res.type == kCCBResTypeAnimation
                || res.type == kCCBResTypeDirectory)
            {
                [dir.animations addObject:res];
            }
            if (res.type == kCCBResTypeBMFont
                || res.type == kCCBResTypeDirectory)
            {
                [dir.bmFonts addObject:res];
            }
            if (res.type == kCCBResTypeTTF
                || res.type == kCCBResTypeDirectory)
            {
                [dir.ttfFonts addObject:res];
            }
            if (res.type == kCCBResTypeCCBFile
                || res.type == kCCBResTypeDirectory)
            {
                [dir.ccbFiles addObject:res];
                
            }
            if (res.type == kCCBResTypeAudio
                || res.type == kCCBResTypeDirectory)
            {
                [dir.audioFiles addObject:res];
                
            }
            if (res.type == kCCBResTypeImage
                || res.type == kCCBResTypeSpriteSheet
                || res.type == kCCBResTypeAnimation
                || res.type == kCCBResTypeBMFont
                || res.type == kCCBResTypeTTF
                || res.type == kCCBResTypeCCBFile
                || res.type == kCCBResTypeDirectory
                || res.type == kCCBResTypeJS
                || res.type == kCCBResTypeJSON
                || res.type == kCCBResTypeAudio)
            {
                [dir.any addObject:res];
            }
        }
        
        [dir.any sortUsingSelector:@selector(compare:)];
        [dir.images sortUsingSelector:@selector(compare:)];
        [dir.animations sortUsingSelector:@selector(compare:)];
        [dir.bmFonts sortUsingSelector:@selector(compare:)];
        [dir.ttfFonts sortUsingSelector:@selector(compare:)];
        [dir.ccbFiles sortUsingSelector:@selector(compare:)];
        [dir.audioFiles sortUsingSelector:@selector(compare:)];
    }
    
    if (resourcesChanged) [self notifyResourceObserversResourceListUpdated];
    if (needsUpdate)
    {
        [[CocosBuilderAppDelegate appDelegate] reloadResources];
    }
}

- (void) addDirectory:(NSString *)dirPath
{
    if ([directories count] > kCCBMaxTrackedDirectories)
    {
        tooManyDirectoriesAdded = YES;
        return;
    }
    
    // Check if directory is already added (then add to its count)
    RMDirectory* dir = [directories objectForKey:dirPath];
    if (dir)
    {
        dir.count++;
    }
    else
    {
        dir = [[[RMDirectory alloc] init] autorelease];
        dir.count = 1;
        dir.dirPath = dirPath;
        [directories setObject:dir forKey:dirPath];
        
        [self updatedWatchedPaths];
    }
    
    [self updateResourcesForPath:dirPath];
}

- (void) removeDirectory:(NSString *)dirPath
{
    RMDirectory* dir = [directories objectForKey:dirPath];
    if (dir)
    {
        // Remove sub directories
        NSDictionary* resources = dir.resources;
        for (NSString* file in resources)
        {
            RMResource* res = [resources objectForKey:file];
            if (res.type == kCCBResTypeDirectory)
            {
                [self removeDirectory:file];
            }
        }
        
        dir.count--;
        if (!dir.count)
        {
            [directories removeObjectForKey:dirPath];
            [self updatedWatchedPaths];
        }
    }
}

- (void) removeAllDirectories
{
    [directories removeAllObjects];
    [activeDirectories removeAllObjects];
    [self updatedWatchedPaths];
    [self notifyResourceObserversResourceListUpdated];
}

- (void) setActiveDirectories:(NSArray *)ad
{
    [activeDirectories removeAllObjects];
    
    for (NSString* dirPath in ad)
    {
        RMDirectory* dir = [directories objectForKey:dirPath];
        if (dir)
        {
            [activeDirectories addObject:dir];
        }
    }
    
    [self notifyResourceObserversResourceListUpdated];
}

- (void) setActiveDirectory:(NSString *)dir
{
    [self setActiveDirectories:[NSArray arrayWithObject:dir]];
}

- (void) addResourceObserver:(id)observer
{
    [resourceObserver addObject:observer];
}

- (void) removeResourceObserver:(id)observer
{
    [resourceObserver removeObject:observer];
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event
{
    [[[CCDirector sharedDirector] view] lockOpenGLContext];
    [self updateResourcesForPath:event.eventPath];
    [[[CCDirector sharedDirector] view] unlockOpenGLContext];
}

- (void) reloadAllResources
{
    [[[CCDirector sharedDirector] view] lockOpenGLContext];
    
    for (id obj in activeDirectories)
    {
        RMDirectory* dir = obj;
        NSString* dirPath = dir.dirPath;
        
        [self updateResourcesForPath:dirPath];
    }
    
    [[[CCDirector sharedDirector] view] unlockOpenGLContext];
}


- (NSString*) mainActiveDirectoryPath
{
    if ([activeDirectories count] == 0) return NULL;
    RMDirectory* dir = [activeDirectories objectAtIndex:0];
    return dir.dirPath;
}

- (void) createCachedImageFromAuto:(NSString*)autoFile saveAs:(NSString*)dstFile forResolution:(NSString*)res
{
    // Find settings for the file
    NSString* fileName = [autoFile lastPathComponent];
    RMResource* resource = [[[RMResource alloc] init] autorelease];
    resource.filePath = [[[autoFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    resource.type = [ResourceManager getResourceTypeForFile:resource.filePath];
    int tabletScale = [[[CocosBuilderAppDelegate appDelegate].projectSettings valueForResource:resource andKey:@"tabletScale"] intValue];
    if (!tabletScale) tabletScale = 2;
    
    int srcScaleSetting = [[[CocosBuilderAppDelegate appDelegate].projectSettings valueForResource:resource andKey:@"scaleFrom"] intValue];
    
    // Calculate the dst scale factor
    float dstScale = 1;
    if ([res isEqualToString:@"phone"]) dstScale = 1;
    if ([res isEqualToString:@"phonehd"]) dstScale = 2;
    else if ([res isEqualToString:@"tablet"]) dstScale = 1 * tabletScale;
    else if ([res isEqualToString:@"tablethd"]) dstScale = 2 * tabletScale;
    else if ([res isEqualToString:@"html5"])
    {
        dstScale = [CocosBuilderAppDelegate appDelegate].projectSettings.publishResolutionHTML5_scale;
    }
    
    // Calculate src scale factor
    float srcScale = 1;
    if (srcScaleSetting)
    {
        // Use the manual override
        srcScale = srcScaleSetting;
    }
    else
    {
        // Use project default
        srcScale = [CocosBuilderAppDelegate appDelegate].projectSettings.resourceAutoScaleFactor;
    }
    
    // Calculate the actual factor
    float scaleFactor = dstScale/srcScale;
    
    // Load src image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([autoFile UTF8String]);
    
    CGImageRef imageSrc;
    BOOL isPng = [[autoFile lowercaseString] hasSuffix:@"png"];
    //If it'a png file, use png dataprovider, or use jpg dataprovider
    if (isPng) {
        imageSrc= CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
    }else{
        imageSrc = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
    }
    
    int wSrc = CGImageGetWidth(imageSrc);
    int hSrc = CGImageGetHeight(imageSrc);
    
    int wDst = wSrc * scaleFactor;
    int hDst = hSrc * scaleFactor;
    
    BOOL save8BitPNG = NO;
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageSrc);
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        save8BitPNG = YES;
    }
    
    // Create new, scaled image
    CGContextRef newContext = CGBitmapContextCreate(NULL, wDst, hDst, 8, wDst*32, colorSpace, kCGImageAlphaPremultipliedLast);
    
    // Enable anti-aliasing
    CGContextSetInterpolationQuality(newContext, kCGInterpolationHigh);
    CGContextSetShouldAntialias(newContext, TRUE);
    
    CGContextDrawImage(newContext, CGContextGetClipBoundingBox(newContext), imageSrc);
    
    CGImageRef imageDst = CGBitmapContextCreateImage(newContext);
    
    // Create destination directory
    [[NSFileManager defaultManager] createDirectoryAtPath:[dstFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    // Save the image
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:dstFile];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, isPng ? kUTTypePNG : kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(destination, imageDst, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", dstFile);
    }
    
    // Release created objects
    CFRelease(destination);
    CGImageRelease(imageSrc);
    CFRelease(dataProvider);
    CFRelease(newContext);
    
    // Convert file to 8 bit if original uses indexed colors
    if (save8BitPNG)
    {
        CFRelease(colorSpace);
        
        NSTask* pngTask = [[NSTask alloc] init];
        [pngTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pngquant"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"--force", @"--ext", @".png", dstFile, nil];
        [pngTask setArguments:args];
        [pngTask launch];
        [pngTask waitUntilExit];
        [pngTask release];
    }
    
    // Update modification time to match original file
    NSDate* autoFileDate = [CCBFileUtil modificationDateForFile:autoFile];
    [CCBFileUtil setModificationDate:autoFileDate forFile:dstFile];
}

- (NSString*) toAbsolutePath:(NSString*)path
{
    if ([activeDirectories count] == 0) return NULL;
    NSFileManager* fm = [NSFileManager defaultManager];
    CocosBuilderAppDelegate* ad = [CocosBuilderAppDelegate appDelegate];
    
    if (!ad.currentDocument)
    {
        // No document is currently open, grab a reference to any of the resolution files
        for (RMDirectory* dir in activeDirectories)
        {
            // First try the default
            NSString* p = [NSString stringWithFormat:@"%@/%@",dir.dirPath,path];
            if ([fm fileExistsAtPath:p]) return p;
            
            // Then try all resolution dependent directories
            NSString* fileName = [p lastPathComponent];
            NSString* dirName = [p stringByDeletingLastPathComponent];
            
            for (NSString* resDir in [ResourceManager resIndependentDirs])
            {
                NSString* p2 = [[dirName stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:fileName];
                if ([fm fileExistsAtPath:p2]) return p2;
            }
        }
    }
    else
    {
        // Select by resolution definied by open document
        NSArray* resolutions = ad.currentDocument.resolutions;
        if (!resolutions) return NULL;
        
        ResolutionSetting* res = [resolutions objectAtIndex:ad.currentDocument.currentResolution];
        
        for (RMDirectory* dir in activeDirectories)
        {
            // Get the name of the default file
            NSString* defaultFile = [NSString stringWithFormat:@"%@/%@",dir.dirPath,path];
            
            NSString* defaultFileName = [defaultFile lastPathComponent];
            NSString* defaultDirName = [defaultFile stringByDeletingLastPathComponent];
            
            // Select by resolution
            for (NSString* ext in res.exts)
            {
                if ([ext isEqualToString:@""]) continue;
                ext = [@"resources-" stringByAppendingString:ext];
                
                NSString* pathForRes = [[defaultDirName stringByAppendingPathComponent:ext] stringByAppendingPathComponent:defaultFileName];
                
                if ([fm fileExistsAtPath:pathForRes]) return pathForRes;
            }
            
            // Auto convert!
            NSString* autoFile = [[defaultDirName stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:defaultFileName];
            if ([fm fileExistsAtPath:autoFile])
            {
                // Check if the file exists in cache
                NSString* ext = @"";
                if ([res.exts count] > 0) ext = [res.exts objectAtIndex:0];
                
                NSString* cachedFile = [ad.projectSettings.displayCacheDirectory stringByAppendingPathComponent:path];
                if (![ext isEqualToString:@""])
                {
                    NSString* cachedFileName = [cachedFile lastPathComponent];
                    NSString* cachedDirName = [cachedFile stringByDeletingLastPathComponent];
                    cachedFile = [[cachedDirName stringByAppendingPathComponent:ext] stringByAppendingPathComponent:cachedFileName];
                }
                
                BOOL cachedFileExists = [fm fileExistsAtPath:cachedFile];
                BOOL datesMatch = NO;
                
                if (cachedFileExists)
                {
                    NSDate* autoFileDate = [CCBFileUtil modificationDateForFile:autoFile];
                    NSDate* cachedFileDate = [CCBFileUtil modificationDateForFile:cachedFile];
                    if ([autoFileDate isEqualToDate:cachedFileDate]) datesMatch = YES;
                }
                
                if (!cachedFileExists || !datesMatch)
                {
                    // Not yet cached, create file
                    [self createCachedImageFromAuto:autoFile saveAs:cachedFile forResolution:ext];
                }
                return cachedFile;
            }
            
            // Fall back on default file
            if ([fm fileExistsAtPath:defaultFile]) return defaultFile;
        }
    }
    return NULL;
}

+ (NSString*) toResolutionIndependentFile:(NSString*)file
{
    CocosBuilderAppDelegate* ad = [CocosBuilderAppDelegate appDelegate];
    
    if (!ad.currentDocument)
    {
        NSLog(@"No document!");
        return file;
    }
    
    NSArray* resolutions = ad.currentDocument.resolutions;
    if (!resolutions)
    {
        NSLog(@"No resolutions!");
        return file;
    }
    
    NSString* fileType = [file pathExtension];
    NSString* fileNoExt = [file stringByDeletingPathExtension];
    
    ResolutionSetting* res = [resolutions objectAtIndex:ad.currentDocument.currentResolution];
    
    for (NSString* ext in res.exts)
    {
        if ([ext isEqualToString:@""]) continue;
        
        NSString* resFile = [NSString stringWithFormat:@"%@-%@.%@",fileNoExt,ext,fileType];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:resFile])
        {
            return resFile;
        }
    }
    return file;
}

#pragma mark File transformations

+ (BOOL) importFile:(NSString*) file intoDir:(NSString*) dstDir
{
    BOOL importedFile = NO;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:file isDirectory:&isDir] && isDir)
    {
        // Handle directory
        NSString* dirName = [file lastPathComponent];
        NSString* dstDirNew = [dstDir stringByAppendingPathComponent:dirName];
        
        // Create if not created
        [fm createDirectoryAtPath:dstDirNew withIntermediateDirectories:YES attributes:NULL error:NULL];
        
        NSArray* dirFiles = [fm contentsOfDirectoryAtPath:file error:NULL];
        for (NSString* fileName in dirFiles)
        {
            importedFile |= [ResourceManager importFile:[file stringByAppendingPathComponent:fileName] intoDir:dstDirNew];
        }
    }
    else
    {
        // Handle regular file
        NSString* ext = [[file pathExtension] lowercaseString];
        if ([ext isEqualToString:@"png"])
        {
            // Handle image import
            
            // Copy to resources-auto folder
            NSString* autoDir = [dstDir stringByAppendingPathComponent:@"resources-auto"];
            
            [fm createDirectoryAtPath:autoDir withIntermediateDirectories:YES attributes:NULL error:NULL];
            
            NSString* imgFileName = [autoDir stringByAppendingPathComponent:[file lastPathComponent]];
            
            [fm copyItemAtPath:file toPath:imgFileName error:NULL];
            importedFile = YES;
        }
        else if ([ext isEqualToString:@"wav"])
        {
            // Handle sound import
            
            QTMovie* movie = [QTMovie movieWithFile:file error:NULL];
            if (movie)
            {
                QTTime duration = movie.duration;
                float durationSeconds = ((float)duration.timeValue) / ((float)duration.timeScale);
                
                // Copy the sound
                NSString* dstPath = [dstDir stringByAppendingPathComponent:[file lastPathComponent]];
                [fm copyItemAtPath:file toPath:dstPath error:NULL];
                
                if (durationSeconds > 15)
                {
                    // Set iOS format to mp4 for long sounds
                    ProjectSettings* settings = [CocosBuilderAppDelegate appDelegate].projectSettings;
                    NSString* relPath = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
                    [settings setValue:[NSNumber numberWithInt:kCCBPublishFormatSound_ios_mp4] forRelPath:relPath andKey:@"format_ios_sound"];
                }
                importedFile = YES;
            }
        }
    }
    
    return importedFile;
}

+ (BOOL) importResources:(NSArray*) resources intoDir:(NSString*) dstDir
{
    BOOL importedFile = NO;
    
    for (NSString* srcFile in resources)
    {
        importedFile |= [ResourceManager importFile:srcFile intoDir:dstDir];
    }
    
    return importedFile;
}

+ (BOOL) moveResourceFile:(NSString*)srcPath ofType:(int) type toDirectory:(NSString*) dstDir
{
    if (!dstDir) return NO;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* fileName = [srcPath lastPathComponent];
    
    NSString* dstPath = [dstDir stringByAppendingPathComponent:fileName];
    
    if (type == kCCBResTypeImage)
    {
        // Move all resoultions
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* srcDir = [srcPath stringByDeletingLastPathComponent];
            NSString* srcResDir = [srcDir stringByAppendingPathComponent:resDir];
            NSString* srcResFile = [srcResDir stringByAppendingPathComponent:fileName];
            
            if ([fm fileExistsAtPath:srcResFile])
            {
                // Create dir if it's not existing already
                NSString* dstResDir = [dstDir stringByAppendingPathComponent:resDir];
                [fm createDirectoryAtPath:dstResDir withIntermediateDirectories:YES attributes:NULL error:NULL];
                
                // Move the file
                NSString* dstResFile = [dstResDir stringByAppendingPathComponent:fileName];
                [fm moveItemAtPath:srcResFile toPath:dstResFile error:NULL];
            }
        }
    }
    else
    {
        // Move regular resources
        [fm moveItemAtPath:srcPath toPath:dstPath error:NULL];
    }
    
    // Make sure the project is updated
    NSString* srcRel = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    NSString* dstRel = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
    
    [[CocosBuilderAppDelegate appDelegate].projectSettings movedResourceFrom:srcRel to:dstRel];
    [[CocosBuilderAppDelegate appDelegate] renamedDocumentPathFrom:srcPath to:dstPath];
    
    // Update resources
    [[CocosBuilderAppDelegate appDelegate].resManager reloadAllResources];
    
    return YES;
}

+ (void) renameResourceFile:(NSString*)srcPath toNewName:(NSString*) newName
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* dstPath = [[srcPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
    int type = [ResourceManager getResourceTypeForFile:srcPath];
    
    if (type == kCCBResTypeImage)
    {
        // Rename all resolutions
        NSString* srcDir = [srcPath stringByDeletingLastPathComponent];
        NSString* oldName = [srcPath lastPathComponent];
        
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* srcResPath = [[srcDir stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:oldName];
            NSString* dstResPath = [[srcDir stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:newName];
            
            // Move the file
            [fm moveItemAtPath:srcResPath toPath:dstResPath error:NULL];
        }
    }
    else
    {
        [fm moveItemAtPath:srcPath toPath:dstPath error:NULL];
    }
    
    // Make sure the project is updated
    NSString* srcRel = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    NSString* dstRel = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
    
    [[CocosBuilderAppDelegate appDelegate].projectSettings movedResourceFrom:srcRel to:dstRel];
    [[CocosBuilderAppDelegate appDelegate] renamedDocumentPathFrom:srcPath to:dstPath];
    
    // Update resources
    [[CocosBuilderAppDelegate appDelegate].resManager reloadAllResources];
}

+ (void) removeResource:(RMResource*) res
{
    NSLog(@"Remove: %@", res.filePath);
    NSFileManager* fm = [NSFileManager defaultManager];
    
    
    NSString* dirPath = [res.filePath stringByDeletingLastPathComponent];
    NSString* fileName = [res.filePath lastPathComponent];
    
    if (res.type == kCCBResTypeImage)
    {
        // Remove all resolutions
        NSArray* resolutions = [ResourceManager resIndependentDirs];
        for (NSString* resolution in resolutions)
        {
            NSString* filePath = [[dirPath stringByAppendingPathComponent:resolution] stringByAppendingPathComponent:fileName];
            [fm removeItemAtPath:filePath error:NULL];
        }
    }
    else
    {
        // Just remove the file
        [fm removeItemAtPath:res.filePath error:NULL];
    }
    
    // Make sure it is removed from the current project
    [[CocosBuilderAppDelegate appDelegate].projectSettings removedResourceAt:res.relativePath];
    [[CocosBuilderAppDelegate appDelegate] removedDocumentWithPath:res.filePath];
}

+ (void) touchResource:(RMResource*) res
{
    if (res.type == kCCBResTypeImage)
    {
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* fileName = [res.filePath lastPathComponent];
            NSString* resPath = [[[res.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:resDir ] stringByAppendingPathComponent:fileName];
            
            [CCBFileUtil setModificationDate:[NSDate date] forFile:resPath];
        }
    }
    else
    {
        [CCBFileUtil setModificationDate:[NSDate date] forFile:res.filePath];
    }
}

- (RMResource*) resourceForPath:(NSString*) path inDir:(RMDirectory*) dir
{
    for (RMResource* res in dir.any)
    {
        if ([res.filePath isEqualToString:path]) return res;
        if (res.type == kCCBResTypeDirectory)
        {
            RMDirectory* subDir = res.data;
            RMResource* found = [self resourceForPath:path inDir:subDir];
            if (found) return found;
        }
    }
    return NULL;
}

- (RMResource*) resourceForPath:(NSString*) path
{
    // Find resource for path
    for (RMDirectory* dir in activeDirectories)
    {
        RMResource* res = [self resourceForPath:path inDir:dir];
        if (res) return res;
    }
    return NULL;
}

#pragma mark Debug

- (void) debugPrintDirectories
{
    NSLog(@"directories: %@", directories);
    NSLog(@"activeDirectories: %@", activeDirectories);
}

@end
