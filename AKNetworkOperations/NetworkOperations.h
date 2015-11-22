//
//  AKNetworkOperations.h
//  MyCompleteLib
//
//  Created by Anand A. Kore on 17/9/15.
//  Copyright © 2015 Anand Kore. All rights reserved.
//


//***************************************** //
//---- Network Operation Constants ------ //
#define DATA_TASK @"DATA_TASK"
#define DATA_UPLOAD_TASK @"DATA_UPLOAD_TASK"
#define DATA_DOWNLOAD_TASK @"DATA_DOWNLOAD_TASK"

#define GET_METHOD @"GET"
#define POST_METHOD @"POST"

#define PARA_TYPE_SOAP @"SOAP"
#define PARA_TYPE_JSON @"JSON"
#define PARA_TYPE_STRING @"STRING"

#define AK_Response_Bytes @"AK_Response_Bytes"
#define AK_Response_Error @"AK_Response_Error"
#define AK_Response_String @"AK_Response_String"
#define AK_Response_JSON @"AK_Response_JSON"
#define AK_Response_UserInfo @"AK_Response_UserInfo"
#define AK_Request_URL @"AK_Request_URL"
//***************************************** //

#import <Foundation/Foundation.h>

@protocol NetworkOperationDelegate <NSObject>
-(void)akNetworkOperationDidFinishRequestWithResponse:(NSMutableDictionary*)response error:(NSError*)error;
@end

@interface NetworkOperations : NSObject<NSURLSessionDataDelegate,NSURLSessionDelegate,NSURLSessionDownloadDelegate,NSURLSessionStreamDelegate,NSURLSessionTaskDelegate>

@property(weak,nonatomic)id<NetworkOperationDelegate> delegate;

+(id)sharedInstance;

#pragma mark- Network Operation Methods Declarations
-(void)sendRequestWithURL:(NSURL *)URL parameters:(NSMutableDictionary *)parameters parameterType:(NSString*)parameterType HttpMethod:(NSString *)method taskType:(NSString*)taskType uploadData:(NSData*)uploadData inBackground:(BOOL)inBackground userInfo:(id)userInfo delegate:(id)delegate;


#pragma mark- Utility Methods Declarations
-(NSString*)convertDictionaryToSOAPKindString:(NSMutableDictionary*)dictionary;
-(NSString*)convertDictionaryToGETkindString:(NSMutableDictionary*)dictionary;
-(NSString*)convertDictionaryToJSONkindString:(NSMutableDictionary*)dictionary;

#pragma mark- XMLParser
-(NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)errorPointer;

#pragma mark- Validator
-(BOOL)isValidJSONData:(NSData*)data;


@end
