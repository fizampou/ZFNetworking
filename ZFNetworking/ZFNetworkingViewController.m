//
//  ZFNetworkingViewController.m
//  ZFNetworking
//
//  Created by zaab on 11/20/12.
//  Copyright (c) 2012 Zampounis Filippos. All rights reserved.
//

#import "ZFNetworkingViewController.h"
#import "NSString+MD5.h"
#import "NSData+MD5.h"
#import <CommonCrypto/CommonDigest.h>
#import "Reachability.h"
//for hex colors.
#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

@interface ZFNetworkingViewController ()

@end

@implementation ZFNetworkingViewController
@synthesize productsArray;
@synthesize resourcesArray;
@synthesize progressView;
@synthesize progressLabel;
@synthesize productsArrayCopy;
@synthesize cancelButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //init
    [self ZFInitialiazer];
    if ([self checkConnectionAndUpdateinterface]) {
        //ask for the JSON and parse it only if there is an internet connection
        [self requestArrayMaker];
    }
}

/**
 *it's used to get the link from the plist file and set the background images
 *init the orientations and the orientations notifier.
 */
-(void)ZFInitialiazer{
    // Path to the plist (in the application bundle)
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ServerAndImagesData" ofType:@"plist"];
    NSMutableDictionary *appData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    ZFRemoteHostUrl = [appData objectForKey:@"LINK"];
    self.cancelButtonPressed = NO;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_LANDSCAPE"]]];
    else
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_PORTRAIT"]]];
    //setting an orientation notifier
    UIDevice *device = [UIDevice currentDevice];                        //Get the device object
    [device beginGeneratingDeviceOrientationNotifications];             //Tell it to start monitoring the accelerometer for orientation
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];	//Get the notification centre for the app
    [nc addObserver:self                                                //Add yourself as an observer
           selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:device];
}

/**
 *checks if there is an internet connection available.
 *returns YES or NO accordingly
 */
-(BOOL)checkConnectionAndUpdateinterface{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"There IS NO internet connection");
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Problem!"
                                                          message:@"no internet connection"
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        self.progressLabel.textColor = UIColorFromRGB(0xC70303);
        self.progressLabel.text = @"No internet connection...";
        self.progressView.progressTintColor = UIColorFromRGB(0xC70303);
        return NO;
    } else {
        NSLog(@"There IS internet connection");
        return YES;
    }
}

/**
 *Making the first request to get the JSON in a dictionary and
 *placing the urls in products array.
 */
-(void)requestArrayMaker{
    self.productsArray = [NSMutableArray array];
    self.resourcesArray = [NSMutableArray array];
    //getting the main JSON FILE ON A DICTIONARY
    NSURL *url = [[NSURL alloc]initWithString:ZFRemoteHostUrl];
    
    // Path to the plist (in the application bundle)
    NSString *path = [[NSBundle mainBundle] pathForResource:@"schema" ofType:@"plist"];
    schema = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    NSArray *items = [[NSArray alloc]initWithArray:[schema objectForKey:@"ITEMS"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *jsonDict = (NSDictionary *) JSON;
        
        NSMutableDictionary *productAndHash;
        for (NSString *item in items) {
             NSArray *downloadObject =  [[schema objectForKey:@"LINKS"]objectForKey:item];
             NSArray *products = [jsonDict objectForKey:item];
             for (NSDictionary* obj in products) {
                 for (NSArray *downloads in downloadObject) {
                     if ([obj objectForKey:[downloads objectAtIndex:1]] != [obj objectForKey:[downloads objectAtIndex:0]]) {
                         productAndHash = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [obj objectForKey:[downloads objectAtIndex:1]], @"hash",
                                          [obj objectForKey:[downloads objectAtIndex:0]] , @"url",
                                          nil];
                         [self.productsArray addObject:productAndHash];
                     }
                 }
            }
        }
        self.productsArrayCopy = [NSMutableArray array];
        self.productsArrayCopy = self.productsArray;
        [self checkExistance];
        [self parser];
    }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Problem!"
                                                          message:@"There is a problem with the server..."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        self.progressLabel.textColor = UIColorFromRGB(0xC70303);
        self.progressView.progressTintColor = UIColorFromRGB(0xC70303);
        self.progressLabel.text= @"There is a problem with the server...";

    }];

    [operation start];
}

/**
 *Making the folders and the subfolders just like
 *the server's folders and subfolders.
 */
-(NSString*)createPathForAsset:(NSURL*)url{
    NSString *relativePath = [url relativePath];

    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableString *targetFilePath= [[NSMutableString alloc]init];
    for (int i=0; i<[[url pathComponents] count]-1; i++) {
        [targetFilePath appendString:[[url pathComponents] objectAtIndex:i] ];
        [targetFilePath appendString:@"/"];
    }
    
    BOOL isDirectory;
    NSFileManager *manager = [[NSFileManager alloc]init];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:targetFilePath];
    if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [manager createDirectoryAtPath:path
           withIntermediateDirectories:YES
                            attributes:attr
                                 error:&error];
        if (error)
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
    }
    NSString *targetPath = [documentsDirectory stringByAppendingPathComponent:relativePath];
    return targetPath;
}

/**
 *Makes the requests and assignes them on apiClient and then starts them alltogether
 *all the urls for the files that need to be downloaded have to be on productsArray
 *in the end resourcesArray has all the download operations.
 */
-(void)parser{
    apiClient =[[AFHTTPClient alloc]initWithBaseURL: [NSURL URLWithString:ZFRemoteHostUrl]];
    for (NSMutableDictionary *element in self.productsArray) {
            NSURL *url = [NSURL URLWithString:[element objectForKey:@"url"]];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            NSString *targetPath = [self createPathForAsset:url];
        
            op.outputStream = [NSOutputStream outputStreamToFileAtPath:targetPath append:NO];
            [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"ZaaB  File Saved %@", targetPath);
                if ([apiClient.operationQueue.operations count]==0 && !self.cancelButtonPressed) {
                    NSString *label = [NSString stringWithFormat:@"Download completed"];
                    self.progressView.progress = (float)1;
                    self.progressLabel.textColor = UIColorFromRGB(0x00901C);
                    self.progressView.progressTintColor = UIColorFromRGB(0x00901C);
                    self.progressLabel.text= label;
                    [self.cancelButton setEnabled:NO];

                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"BaaZ  File NOT Saved %@", targetPath);
                if (error) {
                    NSLog(@"error dude");
                    //delete the file that has problem
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [fileManager removeItemAtPath:targetPath error:nil];
                }
            }];
            [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                if (totalBytesExpectedToRead > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressView.alpha = 1;
                        self.progressView.progress = (float)([self.resourcesArray count]-[apiClient.operationQueue.operations count]) / (float)[self.resourcesArray count];
                        NSString *label;
                        if ([apiClient.operationQueue.operations count]!=0) {
                             label = [NSString stringWithFormat:@"Downloaded %d of %d", [self.resourcesArray count]-[apiClient.operationQueue.operations count],[self.resourcesArray count]];
                        }else if(!self.cancelButtonPressed){
                            label = [NSString stringWithFormat:@"Download completed"];
                            self.progressLabel.textColor = UIColorFromRGB(0x00901C);
                            self.progressView.progressTintColor = UIColorFromRGB(0x00901C);
                            [self.cancelButton setEnabled:NO];

                        }else{
                            //cancell was pressed
                            label = [NSString stringWithFormat:@"Download was cancelled"];
                            self.progressLabel.textColor = UIColorFromRGB(0xC70303);
                            self.progressView.progressTintColor = UIColorFromRGB(0xC70303);
                        }
                        self.progressLabel.text = label;
                    });
                }
            }];
            [self.resourcesArray addObject:op];
        }
    for (AFHTTPRequestOperation *zaab in self.resourcesArray) {
        [apiClient.operationQueue addOperation:zaab];
    }
}

/**
 *removes objects from download array if already downloaded
 *it checks also the hash of the already downloaded items
 *if there are files with wrong hash are deleted.
 */
-(void)checkExistance{
    static int counter;
    
    NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:0];
    for (NSMutableDictionary *urlDictionary in self.productsArray) {
        //fixing the url encode thing
        NSString *path = [[[urlDictionary objectForKey:@"url" ] stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        BOOL exists = [self fileExists:path];
        BOOL hash = [self fileHash:path jsonHash:[urlDictionary objectForKey:@"hash"]];
        if (exists && hash) {
            //file already exists and has the some hash with the JSON
            [temp addObject:urlDictionary];
            NSLog(@"object removed from download array");
        }else if (exists && !hash){
            //file exists but has a different hash than the JSON's
            //we have to delete it and download keep it inb downloads array.
            NSLog(@"object is going down");
            NSString *url = [urlDictionary objectForKey:@"url"];
            BOOL SuccessFull = [self deleteItem:url];
            if (SuccessFull) {
                NSLog(@"Ok deleted nicely");
            }else{
                NSLog(@"Problem Dude couldn't delete the item");
            }
        }else if (!exists){
            NSLog(@"file doesn't even exists");
        }
        counter++;
    }
    NSLog(@"counter is %d",counter);
    [self.productsArray removeObjectsInArray:temp];
    if ([self.productsArray count]==0) {
        [self terminator];
    }
}

/**
 *called when no items for download
 */
-(void)terminator{
    self.progressLabel.text = [NSString stringWithFormat:@"All items are already downloaded..."];
    self.progressLabel.textColor = UIColorFromRGB(0x0082fb);
    self.progressView.progressTintColor = UIColorFromRGB(0x0082fb);
    self.progressView.progress = (float)1;
    [cancelButton setEnabled:NO];
    
}

/**
 *checking the hash given with the files in the folder
 *gets the url from the json and the json has
 *we get o bool YES if equal NO if not equal.
 */
-(BOOL)fileHash:(NSString*)urlName jsonHash:(NSString*)jsonHash{
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    NSArray *targetFilenamez = [[NSArray alloc]initWithArray:[urlName pathComponents]];
    //targetFilenamez = [urlName pathComponents];
    
    NSMutableString *targetFileName = [[NSMutableString alloc]init];
    for (int i=2; i<[targetFilenamez count];i++) {
        [targetFileName appendString:[targetFilenamez objectAtIndex:i]];
        [targetFileName appendString:@"/"];
    }
    NSString *targetPath = [documentsDirectory stringByAppendingPathComponent:targetFileName];
	NSData *    nsData = [NSData dataWithContentsOfFile:targetPath];
	if (nsData){
        NSString *md5 = [nsData MD5];
        if ([md5 isEqualToString:jsonHash]) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

/**
 *will send yes or no if file already exists in the folder or not.
 */
-(BOOL)fileExists:(NSString*)urlName{
    BOOL fileExists;
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    NSArray *targetFilenamez = [[NSArray alloc]initWithArray:[urlName pathComponents]];
    //targetFilenamez = [urlName pathComponents];
    
    NSMutableString *targetFileName = [[NSMutableString alloc]init];
    
    for (int i=2; i<[targetFilenamez count];i++) {
        [targetFileName appendString:[targetFilenamez objectAtIndex:i]];
        [targetFileName appendString:@"/"];
    }
    NSString *targetPath = [documentsDirectory stringByAppendingPathComponent:targetFileName];
   if ([targetPath isEqualToString:documentsDirectory]) {
        return NO;
    }else{
        return fileExists = [[NSFileManager defaultManager] fileExistsAtPath:targetPath];

    }
}

/**
 *we loop through the operations and cancel them
 */
-(IBAction)cancelPressed:(id)sender{
    self.cancelButtonPressed=YES;
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    [apiClient.operationQueue cancelAllOperations];
    //getting all the files on documents folder in an array.
    NSError * error;
    NSArray * directoryContents = [self listFileAtPath:documentsDirectory];
    //[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    if (!error) {
        for (NSString *filename in directoryContents) {
            for (NSDictionary *item in self.productsArrayCopy) {
                NSString *url = [item objectForKey:@"url"];
                NSString *name = [[[url lastPathComponent]stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                if ([filename isEqualToString:name]) {
                    NSString *hash = [item objectForKey:@"hash"];
                    BOOL chechBothHashes = [self fileHash:url jsonHash:hash];
                    if (!chechBothHashes) {
                        //delete the item.
                        BOOL SuccessFull = [self deleteItem:url];
                        if (SuccessFull) {
                            NSLog(@"Ok deleted nicely");
                        }else{
                            NSLog(@"Problem Dude couldn't delete the item");
                        }
                    }
                }
            }
        }
    }
}

/**
 *we loop through the operations and cancel them
 */
-(NSArray *)listFileAtPath:(NSString *)path{
    //takes the main path of a folder and returns all files in folder/subfolders not the folders just the files in an array with their names.
    int count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray *itemsArray = [[NSMutableArray alloc]init];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        if ([self directoryExistsAtAbsolutePath:[path stringByAppendingPathComponent:[directoryContent objectAtIndex:count]]]) {
            //it's directory
            [itemsArray addObjectsFromArray:[self listFileAtPath:[NSString stringWithFormat:@"%@/%@",path,[directoryContent objectAtIndex:count]]]];
        }else{
            //it's a file
            [itemsArray addObject:[directoryContent objectAtIndex:count]];
        }
    }
    return itemsArray;
}

/**
 *returns YES if file exists at filepath
 */
-(BOOL)fileExistsAtAbsolutePath:(NSString*)filename {
    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory];
    
    return fileExistsAtPath && !isDirectory;
}

/**
 *returns YES if folser exists in filepath
 */
-(BOOL)directoryExistsAtAbsolutePath:(NSString*)filename {
    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory];
    
    return fileExistsAtPath && isDirectory;
}

/**
 *gets a url of an item and deletes the item
 *The item has to be in the Documents folder
 *returns YES if the item is deleted else NO
 */
-(BOOL)deleteItem:(NSString*)itemUrl{
    NSError *error;
    
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    NSURL *url = [[NSURL alloc]initWithString:itemUrl];
    NSString *targetFilename = [url path];
    NSString *targetPath = [[[documentsDirectory stringByAppendingPathComponent:targetFilename]stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:targetPath error:&error];
    if (error) {
        NSLog(@"Error Dude");
        return NO;
    }else{
        NSLog(@"Item deleted");
        return YES;
    }
}

/**
 *It's called from tha appDelegate when app goes to background.
 */
-(void)willGoBackground{
    [self cancelPressed:nil];
}

/**
 *It's called from the appDelegate when app comes from the background.
 */
-(void)willComeForeground{
    [self requestArrayMaker];
    self.cancelButtonPressed = NO;
    self.progressLabel.textColor = [UIColor scrollViewTexturedBackgroundColor];
    self.progressView.progressTintColor = [UIColor scrollViewTexturedBackgroundColor];
    [self.cancelButton setEnabled:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"just got a memory warning");
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

/**
 *detecting orientation change and setting the background accordingly.
 */
- (void)orientationChanged:(NSNotification *)note{
	NSLog(@"Orientation  has changed: %d", [[note object] orientation]);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ServerAndImagesData" ofType:@"plist"];
    NSMutableDictionary *appData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    if([[note object] orientation] == 1)
    {
        //if portrait
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_PORTRAIT"]]];
    }
    else if([[note object] orientation] == 2)
    {
        //if portrait
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_PORTRAIT"]]];
    }
    else if([[note object] orientation] == 3)
    {
        // if landscape
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_LANDSCAPE"]]];
    }
    else if([[note object] orientation] == 4)
    {
        // if landscape
        [self.backgroundView setImage:[UIImage imageNamed:[appData objectForKey:@"BACKGROUND_LANDSCAPE"]]];
    }
}
@end
