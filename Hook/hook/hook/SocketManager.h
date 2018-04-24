//
//  SocketManager.h
//  hook
//
//  Created by 鲍利成 on 2018/3/27.
//

#import <Foundation/Foundation.h>
typedef void (^RequestCallback)(id dic);
typedef id  (^DowithDataCallback)(id dic);
@interface SocketManager : NSObject
+(id)shareManager;

-(void)listenSocket:(int)port;

-(void)setRequestCallback:(RequestCallback)callback;
-(void)setDowithDataCallback:(DowithDataCallback)callback;
-(NSData *)uncompressZippedData:(NSData *)compressedData;
-(void)setToken:(NSString *)mToken userId:(NSString *)mUserId;
-(NSString *)stringFromJsonData:(id)obj;
-(void)writeDataToClient:(id)data;
-(void)writeDataToClient:(id)head data:(id)data;
-(void)requestTest;
@end
