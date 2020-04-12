//
//  NCAutoUpload.m
//  Nextcloud
//
//  Created by Marino Faggiana on 07/06/17.
//  Copyright (c) 2017 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NCAutoUpload.h"
#import "AppDelegate.h"
#import "NCBridgeSwift.h"
#import "NSDate+NCUtil.h"

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@interface NCAutoUpload ()
{
    AppDelegate *appDelegate;
    CCHud *_hud;
}
@end

@implementation NCAutoUpload

+ (NCAutoUpload *)sharedInstance {
    
    static NCAutoUpload *sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            
            sharedInstance = [NCAutoUpload new];
            sharedInstance->appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        }
        return sharedInstance;
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === initStateAutoUpload ===
#pragma --------------------------------------------------------------------------------------------

- (void)initStateAutoUpload
{
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
    
    if (account.autoUpload) {
        
        [self setupAutoUpload];
        
        if (account.autoUploadBackground) {
         
            [self checkIfLocationIsEnabled];
        }
        
    } else {
        
        [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === Camera Upload & Full ===
#pragma --------------------------------------------------------------------------------------------

- (void)setupAutoUpload
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        
        [self performSelectorOnMainThread:@selector(uploadNewAssets) withObject:nil waitUntilDone:NO];
        
    } else {
        
        tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];

        if (account.autoUpload == YES)
            [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUpload" state:NO];
        
        [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        
        [alertController addAction:okAction];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
        return;        
    }
}

- (void)setupAutoUploadFull
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        
        [self performSelectorOnMainThread:@selector(uploadFullAssets) withObject:nil waitUntilDone:NO];
        
    } else {
        
        tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];

        if (account.autoUpload == YES)
            [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUpload" state:NO];
        
        [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        
        [alertController addAction:okAction];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === Location ===
#pragma --------------------------------------------------------------------------------------------

- (BOOL)checkIfLocationIsEnabled
{
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
    
    [CCManageLocation sharedInstance].delegate = self;
    
    if ([CLLocationManager locationServicesEnabled]) {
        
        NSLog(@"[LOG] checkIfLocationIsEnabled : authorizationStatus: %d", [CLLocationManager authorizationStatus]);
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ) {
                
                NSLog(@"[LOG] checkIfLocationIsEnabled : Location services not determined");
                [[CCManageLocation sharedInstance] startSignificantChangeUpdates];
                
            } else {
                
                if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                    
                    if (account.autoUploadBackground == YES)
                        [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_location_not_enabled_", nil) message:NSLocalizedString(@"_location_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    
                    [alertController addAction:okAction];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
                    
                } else {
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    
                    [alertController addAction:okAction];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
                }
            }
            
        } else {
            
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                
                if (account.autoUploadBackground == NO)
                    [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:YES];
                
                [[CCManageLocation sharedInstance] startSignificantChangeUpdates];
                
            } else {
                
                if (account.autoUploadBackground == YES)
                    [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
                
                [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                
                [alertController addAction:okAction];
                [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
            }
        }
        
    } else {
        
        if (account.autoUploadBackground == YES)
            [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
        
        [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
        
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_location_not_enabled_", nil) message:NSLocalizedString(@"_location_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            
            [alertController addAction:okAction];
            [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
            
        } else {
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_location_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_location_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            
            [alertController addAction:okAction];
            [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
        }
    }
    
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountActive];
    return tableAccount.autoUploadBackground;
}

- (void)statusAuthorizationLocationChanged
{
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                
                if ([CCManageLocation sharedInstance].firstChangeAuthorizationDone) {
                    
                    if (account.autoUploadBackground == YES)
                        [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
                    
                    [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
                }
                
            } else {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                
                [alertController addAction:okAction];
                [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
            }
            
        } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
            
            if (account.autoUploadBackground == YES) {
                
                [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
                
                [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
                
                if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_location_not_enabled_", nil) message:NSLocalizedString(@"_location_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    
                    [alertController addAction:okAction];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
                    
                } else {
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_access_photo_location_not_enabled_", nil) message:NSLocalizedString(@"_access_photo_location_not_enabled_msg_", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    
                    [alertController addAction:okAction];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alertController animated:YES completion:nil];
                }
            }
        }
        
        if (![CCManageLocation sharedInstance].firstChangeAuthorizationDone) {
            
            [CCManageLocation sharedInstance].firstChangeAuthorizationDone = YES;
        }
    }
}

- (void)changedLocation
{
    // Only in background
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
    
    if (account.autoUpload && account.autoUploadBackground && [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            
            //check location
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
                
                NSLog(@"[LOG] Changed Location call uploadNewAssets");
                
                [self uploadNewAssets];
            }
            
        } else {
            
            if (account.autoUpload == YES)
                [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUpload" state:NO];
            
            if (account.autoUploadBackground == YES)
                [[NCManageDatabase sharedInstance] setAccountAutoUploadProperty:@"autoUploadBackground" state:NO];
            
            [[CCManageLocation sharedInstance] stopSignificantChangeUpdates];
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Upload Assets : NEW & FULL ====
#pragma --------------------------------------------------------------------------------------------

- (void)uploadNewAssets
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self uploadAssetsNewAndFull:selectorUploadAutoUpload];
    });
}

- (void)uploadFullAssets
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self uploadAssetsNewAndFull:selectorUploadAutoUploadAll];
    });
}

- (void)uploadAssetsNewAndFull:(NSString *)selector
{
     if (!appDelegate.activeAccount || appDelegate.maintenanceMode)
         return;
    
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountActive];
    NSMutableArray *metadataFull = [NSMutableArray new];
    NSString *autoUploadPath = [[NCManageDatabase sharedInstance] getAccountAutoUploadPath:appDelegate.activeUrl];
    NSString *serverUrl;
    
    // Check Asset : NEW or FULL
    PHFetchResult *newAssetToUpload = [self getCameraRollAssets:tableAccount selector:selector alignPhotoLibrary:NO];
    
    // News Assets ? if no verify if blocked Table Auto Upload -> Autostart
    if (newAssetToUpload == nil || [newAssetToUpload count] == 0) {
        
        NSLog(@"[LOG] Auto upload, no new asset found");
        return;
        
    } else {
        
        NSLog(@"[LOG] Auto upload, new %lu asset found", (unsigned long)[newAssetToUpload count]);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([selector isEqualToString:selectorUploadAutoUploadAll]) {
            if (!_hud)
                _hud = [[CCHud alloc] initWithView:[[[UIApplication sharedApplication] delegate] window]];
        
            [_hud visibleHudTitle:NSLocalizedString(@"_create_full_upload_", nil) mode:MBProgressHUDModeIndeterminate color:nil];
        }
    });
    
    // Create the folder for auto upload & if request the subfolders
    if(![[NCAutoUpload sharedInstance] createAutoUploadFolderWithSubFolder:tableAccount.autoUploadCreateSubfolder assets:newAssetToUpload selector:selector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // end loading
            [_hud hideHud];
        });
        return;
    }
    
    for (PHAsset *asset in newAssetToUpload) {
        
        NSDate *assetDate = asset.creationDate;
        PHAssetMediaType assetMediaType = asset.mediaType;
        NSString *session;
        NSString *fileName = [CCUtility createFileName:[asset valueForKey:@"filename"] fileDate:asset.creationDate fileType:asset.mediaType keyFileName:k_keyFileNameAutoUploadMask keyFileNameType:k_keyFileNameAutoUploadType keyFileNameOriginal:k_keyFileNameOriginalAutoUpload];

        // Select type of session
        
        if (assetMediaType == PHAssetMediaTypeImage && tableAccount.autoUploadWWAnPhoto == NO) session = k_upload_session;
        if (assetMediaType == PHAssetMediaTypeVideo && tableAccount.autoUploadWWAnVideo == NO) session = k_upload_session;
        if (assetMediaType == PHAssetMediaTypeImage && tableAccount.autoUploadWWAnPhoto) session = k_upload_session_wwan;
        if (assetMediaType == PHAssetMediaTypeVideo && tableAccount.autoUploadWWAnVideo) session = k_upload_session_wwan;
        
        NSString *yearString = [assetDate NC_stringFromDateWithFormat:@"yyyy"];
        NSString *monthString = [assetDate NC_stringFromDateWithFormat:@"MM"];
        
        if (tableAccount.autoUploadCreateSubfolder)
            serverUrl = [NSString stringWithFormat:@"%@/%@/%@", autoUploadPath, yearString, monthString];
        else
            serverUrl = autoUploadPath;
        
        // Check il file already exists
        tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@ AND fileNameView == %@", appDelegate.activeAccount, serverUrl, fileName]];
        if (!metadata) {
        
            tableMetadata *metadataForUpload = [tableMetadata new];
            
            metadataForUpload.account = appDelegate.activeAccount;
            metadataForUpload.assetLocalIdentifier = asset.localIdentifier;
            metadataForUpload.date = [NSDate new];
            metadataForUpload.ocId = [CCUtility createMetadataIDFromAccount:appDelegate.activeAccount serverUrl:serverUrl fileNameView:fileName directory:false];
            metadataForUpload.fileName = fileName;
            metadataForUpload.fileNameView = fileName;
            metadataForUpload.serverUrl = serverUrl;
            metadataForUpload.session = session;
            metadataForUpload.sessionSelector = selector;
            metadataForUpload.size = [[NCUtility sharedInstance] getFileSizeWithAsset:asset];
            metadataForUpload.status = k_metadataStatusWaitUpload;

            [metadataFull addObject:metadataForUpload];
            
            // Update database Auto Upload
            if ([selector isEqualToString:selectorUploadAutoUpload])
                [self addQueueUploadAndPhotoLibrary:metadataForUpload asset:asset];
        }
    }
    
    // Insert all assets (Full) in tableQueueUpload
    if ([selector isEqualToString:selectorUploadAutoUploadAll] && [metadataFull count] > 0) {
    
        (void)[[NCManageDatabase sharedInstance] addMetadatas:metadataFull];
        
        // Update icon badge number
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate updateApplicationIconBadgeNumber];
        });
    }
    
    // end loadingcand reload
    dispatch_async(dispatch_get_main_queue(), ^{
        [_hud hideHud];
        [[NCMainCommon sharedInstance] reloadDatasourceWithServerUrl:nil ocId:nil action:k_action_NULL];
    });    
}

- (void)addQueueUploadAndPhotoLibrary:(tableMetadata *)metadata asset:(PHAsset *)asset
{
    @synchronized(self) {
        
        (void)[[NCManageDatabase sharedInstance] addMetadata:metadata];
        
        // Add asset in table Photo Library
        if ([metadata.sessionSelector isEqualToString:selectorUploadAutoUpload]) {
            (void)[[NCManageDatabase sharedInstance] addPhotoLibrary:@[asset] account:appDelegate.activeAccount];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update icon badge number
            [appDelegate updateApplicationIconBadgeNumber];
        });
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Create Folder SubFolder Auto Upload Folder Photos/Videos ====
#pragma --------------------------------------------------------------------------------------------

- (BOOL)createAutoUploadFolderWithSubFolder:(BOOL)useSubFolder assets:(PHFetchResult *)assets selector:(NSString *)selector
{
    NSString *ocId;
    NSError *error;
    NSString *autoUploadPath = [[NCManageDatabase sharedInstance] getAccountAutoUploadPath:appDelegate.activeUrl];
    BOOL encrypted = [CCUtility isFolderEncrypted:autoUploadPath account:appDelegate.activeAccount];
  
    [[NCNetworkingEndToEnd sharedManager] createEndToEndFolder:autoUploadPath account:appDelegate.activeAccount user:appDelegate.activeUser userID:appDelegate.activeUserID password:appDelegate.activePassword url:appDelegate.activeUrl encrypted:encrypted ocId:&ocId error:&error];
    
    if (error == nil) {
        
        tableDirectory *tableDirectory = [[NCManageDatabase sharedInstance] getTableDirectoryWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", appDelegate.activeAccount, autoUploadPath]];
        if (!tableDirectory)
            (void)[[NCManageDatabase sharedInstance] addDirectoryWithEncrypted:encrypted favorite:false ocId:ocId permissions:nil serverUrl:autoUploadPath richWorkspace:nil account:appDelegate.activeAccount];
        
    } else {
       
        if ([selector isEqualToString:selectorUploadAutoUploadAll])
            [[NCContentPresenter shared] messageNotification:@"_error_" description:@"_error_createsubfolders_upload_" delay:k_dismissAfterSecond type:messageTypeError errorCode:k_CCErrorInternalError];

        return false;
    }
    
    // Create if request the subfolders
    if (useSubFolder) {
        
        for (NSString *dateSubFolder in [CCUtility createNameSubFolder:assets]) {
            
            NSString *folderPathName = [NSString stringWithFormat:@"%@/%@", autoUploadPath, dateSubFolder];
            
            [[NCNetworkingEndToEnd sharedManager] createEndToEndFolder:folderPathName account:appDelegate.activeAccount user:appDelegate.activeUser userID:appDelegate.activeUserID password:appDelegate.activePassword url:appDelegate.activeUrl encrypted:encrypted ocId:&ocId error:&error];
            
            if ( error == nil) {
                
                (void)[[NCManageDatabase sharedInstance] addDirectoryWithEncrypted:encrypted favorite:false ocId:ocId permissions:nil serverUrl:folderPathName richWorkspace:nil account:appDelegate.activeAccount];
                
            } else {
                
                if ([selector isEqualToString:selectorUploadAutoUploadAll])
                    [[NCContentPresenter shared] messageNotification:@"_error_" description:@"_error_createsubfolders_upload_" delay:k_dismissAfterSecond type:messageTypeError errorCode:k_CCErrorInternalError];

                return false;
            }
        }
    }
    
    return true;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== get Camera Roll new Asset ====
#pragma --------------------------------------------------------------------------------------------

- (PHFetchResult *)getCameraRollAssets:(tableAccount *)account selector:(NSString *)selector alignPhotoLibrary:(BOOL)alignPhotoLibrary
{
    @synchronized(self) {
        
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            
            PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
            if (result.count == 0) {
                return nil;
            }
            
            NSPredicate *predicateImage = [NSPredicate predicateWithFormat:@"mediaType == %i", PHAssetMediaTypeImage];
            NSPredicate *predicateVideo = [NSPredicate predicateWithFormat:@"mediaType == %i", PHAssetMediaTypeVideo];
            NSPredicate *predicate;

            NSMutableArray *newAssets =[NSMutableArray new];
            
            if (alignPhotoLibrary || (account.autoUploadImage && account.autoUploadVideo)) {
                
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicateImage, predicateVideo]];
                
            } else if (account.autoUploadImage) {
                
                predicate = predicateImage;
                
            } else if (account.autoUploadVideo) {
                
                predicate = predicateVideo;
                
            } else {
                
                return nil;
            }
            
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.predicate = predicate;
            
            PHAssetCollection *collection = result[0];
            
            PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
            
            if ([selector isEqualToString:selectorUploadAutoUpload]) {
            
                NSString *creationDate;
                NSString *idAsset;

                NSArray *idsAsset = [[NCManageDatabase sharedInstance] getPhotoLibraryIdAssetWithImage:account.autoUploadImage video:account.autoUploadVideo account:account.account];
                
                for (PHAsset *asset in assets) {
                    
                    (asset.creationDate != nil) ? (creationDate = [NSString stringWithFormat:@"%@", asset.creationDate]) : (creationDate = @"");
                    
                    idAsset = [NSString stringWithFormat:@"%@%@%@", account.account, asset.localIdentifier, creationDate];
                    
                    if (![idsAsset containsObject: idAsset])
                        [newAssets addObject:asset];
                }
                
                return (PHFetchResult *)newAssets;
                
            } else {
            
                return assets;
            }
        }
    }
    
    return nil;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Align Photo Library ====
#pragma --------------------------------------------------------------------------------------------

- (void)alignPhotoLibrary
{
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];

    PHFetchResult *assets = [self getCameraRollAssets:account selector:selectorUploadAutoUploadAll alignPhotoLibrary:YES];
   
    [[NCManageDatabase sharedInstance] clearTable:[tablePhotoLibrary class] account:appDelegate.activeAccount];
    if (assets != nil) {
        (void)[[NCManageDatabase sharedInstance] addPhotoLibrary:(NSArray *)assets account:account.account];

        NSLog(@"[LOG] Align Photo Library %lu", (unsigned long)[assets count]);
    }
}

@end
