//
//  SocketManager.m
//  hook
//
//  Created by 鲍利成 on 2018/3/27.
//

#import "SocketManager.h"
#import "GCDAsyncSocket.h"
#import "zlib.h"
#define READ_TIMEOUT 15.0
@interface SocketManager()<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *listenSocket;
    GCDAsyncSocket *connectedSocket;
    dispatch_queue_t socketQueue;
    RequestCallback requestCallback;
    DowithDataCallback dowithDataCallback;
    
    NSString *token;
    NSString *userId;
}
@end
@implementation SocketManager
+(id)shareManager
{
    static SocketManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SocketManager alloc] init];
    });
    return manager;
}

- (id)objectWithJsonString:(NSString *)jsonString;
{
    if (jsonString == nil) {
        return nil;
    }
    
    if (![jsonString isKindOfClass:[NSString class]]) {
        return jsonString;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return obj;
}

-(NSString *)stringFromJsonData:(id)obj

{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
        return nil;
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}

-(NSData *)uncompressZippedData:(NSData *)compressedData
{
    if ([compressedData length] == 0) return compressedData;
    
    unsigned full_length = [compressedData length];
    
    unsigned half_length = [compressedData length] / 2;
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = [compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        // chadeltu 加了(Bytef *)
        strm.next_out = (Bytef *)[decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
        
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}

-(void)listenSocket:(int)port
{
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    NSError *error = nil;
    BOOL success = [listenSocket acceptOnPort:port error:&error];
    if (!success) {
        NSLog(@"Error starting server:%@",error);
    }else{
        NSLog(@"server started on port %d",port);
    }
}

-(void)setToken:(NSString *)mToken userId:(NSString *)mUserId
{
    token = mToken;
    userId = mUserId;
}

-(void)setDowithDataCallback:(DowithDataCallback)callback
{
    NSLog(@"setDowithDataCallback");
    dowithDataCallback = callback;
}

-(void)setRequestCallback:(RequestCallback)callback
{
    NSLog(@"setRequestCallback");
    requestCallback = callback;
}

-(void)writeDataToClient:(id)head data:(id)data
{
    NSLog(@"writeDataToClient:%@",data);
    if (head) {
        NSString *sendString = [NSString stringWithFormat:@"%@\r\n",[self stringFromJsonData:head]];
        NSData *headData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
        if (connectedSocket && [connectedSocket isConnected]) {
            NSLog(@"sendData: %@",headData);
            [connectedSocket writeData:headData withTimeout:-1 tag:1];
            if (data) {
                [connectedSocket writeData:data withTimeout:-1 tag:1];
                [connectedSocket writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
            }
        }
    }
}

-(void)writeDataToClient:(id)data
{
    NSLog(@"writeDataToClient:%@",data);
    if (data) {
        NSString *sendString = [NSString stringWithFormat:@"%@",[self stringFromJsonData:data]];
        NSData *writeData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
        if (connectedSocket && [connectedSocket isConnected]) {
            NSLog(@"sendData: %@",writeData);
            NSInteger separateLength = 200;
            if(writeData.length > separateLength){
                NSInteger location = 0;
                while (location < writeData.length) {
                    if ((writeData.length  - location) >= separateLength) {
                        NSData *sendData = [writeData subdataWithRange:NSMakeRange(location, separateLength)];
                        [connectedSocket writeData:sendData withTimeout:-1 tag:1];
                    }else{
                        NSData *sendData = [writeData subdataWithRange:NSMakeRange(location, writeData.length - location)];
                        [connectedSocket writeData:sendData withTimeout:-1 tag:1];
                    }
                    [connectedSocket writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
                    
                    location = location + separateLength;
                }
            }else{
                [connectedSocket writeData:writeData withTimeout:-1 tag:1];
                [connectedSocket writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
            }
            [connectedSocket writeData:[@"#EOF\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
        }
    }
}

-(void)reqeustWithDic:(NSDictionary *)dic;
{
    if (dic) {
        if (requestCallback) {
            requestCallback(dic);
        }
    }
}

-(void)requestTest
{
    NSLog(@"begin test Request");
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
//    NSString *paramsString = [NSString stringWithFormat:@"apiVersion=4&cChannelId=0&cClientVersionCode=2018012501&cClientVersionName=2.33.502&cCurrentGameId=20001&cDeviceCPU=ARM&cDeviceId=ab86b648ad6f4082224ef7131505f0f63ed589d5&cDeviceMem=1064304640&cDeviceModel=iPhone&cDeviceNet=WiFi&cDeviceSP=%%E4%%B8%%AD%%E5%%9B%%BD%%E8%%81%%94%%E9%%80%%9A&cDeviceScreenHeight=568&cDeviceScreenWidth=320&cGameId=20001&cGzip=1&cRand=%.0lf&cSystem=ios&cSystemVersionCode=10.3.3&cSystemVersionName=iOS&gameId=20001&myRoleId=1057335100&platType=ios&roleId=1057335100&token=%@&userId=%@&versioncode=2018012501",time,token,userId];
    NSString *paramsString = [NSString stringWithFormat:@"apiVersion=4&cChannelId=0&cClientVersionCode=2018012501&cClientVersionName=2.33.502&cCurrentGameId=20001&cDeviceCPU=ARM&cDeviceId=ab86b648ad6f4082224ef7131505f0f63ed589d5&cDeviceMem=1064304640&cDeviceModel=iPhone&cDeviceNet=WiFi&cDeviceSP=%%E4%%B8%%AD%%E5%%9B%%BD%%E8%%81%%94%%E9%%80%%9A&cDeviceScreenHeight=568&cDeviceScreenWidth=320&cGameId=20001&cGzip=1&cRand=%.0lf&cSystem=ios&cSystemVersionCode=10.3.3&cSystemVersionName=iOS&gameId=20001&lastTime=0&option=0&roleId=1057335100&token=%@&userId=%@",time,token,userId];
    
    NSLog(@"request params: %@",paramsString);
//    NSString *utf8Str = @"中国联通";
//    NSString *unicodeStr = [NSString stringWithCString:[utf8Str UTF8String] encoding:NSUnicodeStringEncoding];
//    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@(4),@"apiVersion",@(0),@"cChannelId",@"2018012501",@"cClientVersionCode",@"2.33.502",@"cClientVersionName",@"20001",@"cCurrentGameId",@"ARM",@"cDeviceCPU",@"ab86b648ad6f4082224ef7131505f0f63ed589d5",@"cDeviceId",@"1064304640",@"cDeviceMem",@"iPhone",@"cDeviceModel",@"WiFi",@"cDeviceNet",unicodeStr,@"cDeviceSP",@(568),@"cDeviceScreenHeight",@(320),@"cDeviceScreenWidth",@"20001",@"cGameId",@(1),@"cGzip",timeStr,@"cRand",@"ios",@"cSystem",@"10.3.3",@"cSystemVersionCode",@"iOS",@"cSystemVersionName",@"20001",@"gameId",@"1057335100",@"myRoleId",@"ios",@"platType",@"1057335100",@"roleId",token,@"token",userId,@"userId",@"2018012501",@"versioncode", nil];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"https://ssl.kohsocialapp.qq.com:10001/play/getmatchlist",@"url",paramsString,@"data",@"http",@"label",@"getmatchlist",@"label", nil];
    if (requestCallback) {
        requestCallback(dic);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    NSLog(@"Accepted client %@:%hu",host, port);
    [newSocket readDataWithTimeout:-1 tag:0];
    connectedSocket = newSocket;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *receiveStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"did received Data: %@",receiveStr);
    NSDictionary *dic = [self objectWithJsonString:receiveStr];
    dowithDataCallback(dic);
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"did write data");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    if(![sock isEqual:listenSocket]){
        connectedSocket = nil;
    }
}
@end
