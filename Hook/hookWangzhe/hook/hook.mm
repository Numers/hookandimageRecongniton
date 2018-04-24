#import <CaptainHook/CaptainHook.h>
#import "SocketManager.h"
CHDeclareClass(UnityWWWConnectionDelegate);

CHOptimizedMethod2(self, id, UnityWWWConnectionDelegate, connection, id, arg1, didReceiveData, id, arg2)
{
    NSLog(@"hook values didReceiveData arg1  %@,  arg2 %@",arg1,arg2);
    NSData *receiveData = [[SocketManager shareManager] uncompressZippedData:arg2];
    NSString *receiveString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
    NSLog(@"receive data %@",receiveString);
    return CHSuper2(UnityWWWConnectionDelegate, connection, arg1, didReceiveData, arg2);
}

CHOptimizedMethod2(self, id, UnityWWWConnectionDelegate, initWithURL, id, arg1, udata, void *, arg2)
{
    NSLog(@"hook values initWithURL arg1  %@",arg1);
    NSData *temp1Udata = [NSData dataWithBytesNoCopy:arg2 length:1024];
    if (temp1Udata) {
        NSLog(@"temp1Udata is %@",temp1Udata);
    }
    id result =  CHSuper2(UnityWWWConnectionDelegate, initWithURL, arg1, udata, arg2);
    NSData *temp2Udata = [NSData dataWithBytesNoCopy:arg2 length:1024];
    if (temp2Udata) {
        NSLog(@"temp2Udata is %@",temp2Udata);
    }
    return result;
}


CHConstructor {
    @autoreleasepool {
        NSLog(@"hook begins");
        CHLoadLateClass(UnityWWWConnectionDelegate);
        CHHook2(UnityWWWConnectionDelegate, connection,didReceiveData);
        
        /*[[SocketManager shareManager] listenSocket:8890];
        [[SocketManager shareManager] setDowithDataCallback:^id(id dic) {
            if(dic){
                NSString *url = [dic objectForKey:@"url"];
                NSString *label = [dic objectForKey:@"label"];
                id state = [dic objectForKey:@"state"];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",label,@"label",state,@"state", nil];
                if([label isEqualToString:@"encrypt"]){
                    NSString *jsonString = nil;
                    id jsonObj = [dic objectForKey:@"data"];
                    if([jsonObj isKindOfClass:[NSDictionary class]]){
                        jsonString = [[SocketManager shareManager] stringFromJsonData:jsonObj];
                    }else if([jsonObj isKindOfClass:[NSString class]]){
                        jsonString = jsonObj;
                    }else{
                        jsonString = @"";
                    }
                    NSData *encryptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"encryptString:stringKey:"),jsonString,@"404ccc36a0e27a28");
                    
                    if(encryptResult){
                        NSString *base64EncryptString = [encryptResult base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                        [resultDic setObject:base64EncryptString forKey:@"data"];
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    [[SocketManager shareManager] writeDataToClient:resultDic];
                    return encryptResult;
                }else{
                    NSData *encrypt = nil;
                    id encryptData = [dic objectForKey:@"data"];
                    if(encryptData && [encryptData isKindOfClass:[NSString class]]){
                        NSLog(@"decrptDataString:%@",encryptData);
                        encrypt = [[NSData alloc] initWithBase64EncodedString:encryptData options:NSDataBase64Encoding64CharacterLineLength];
                    }
                    
                    if(encryptData && [encryptData isKindOfClass:[NSData class]]){
                        encrypt = encryptData;
                    }
                    
                    NSLog(@"decryptData:%@",encrypt);
                    if(encrypt != nil){
                        BOOL gzip = [[dic objectForKey:@"gzip"] boolValue];
                        id decrptResult = nil;
                        if(gzip){
                            id tempDecrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decrypt:stringKey:"),encrypt,@"404ccc36a0e27a28");
                            if(tempDecrptResult){
                                id temp  = [[SocketManager shareManager] uncompressZippedData:tempDecrptResult];
                                if(temp){
                                    decrptResult = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
                                }
                            }
                        }else{
                            decrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decryptToString:stringKey:"),encrypt,@"404ccc36a0e27a28");
                        }
                        
                        if(decrptResult){
                            [resultDic setObject:decrptResult forKey:@"data"];
                        }else{
                            [resultDic setObject:@"" forKey:@"data"];
                        }
                        
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    
                }
                [[SocketManager shareManager] writeDataToClient:resultDic];
                return resultDic;
            }
            return nil;
        }];
        
        [[SocketManager shareManager] setRequestCallback:^(id dic) {
            NSLog(@"hook Test");
            NSString *url = [dic objectForKey:@"url"];
            NSString *params = [dic objectForKey:@"data"];
            if(!url || !params){
                return;
            }
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSData *encryptData = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"encryptString:stringKey:"),params,@"404ccc36a0e27a28");
            [request setValue:@"zh-Hans-CN;q=1, zh-Hant-CN;q=0.9, en-CN;q=0.8" forHTTPHeaderField:@"Accept-Language"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setValue:@"smoba/2.33.502 (iPhone; iOS 10.3.3; Scale/2.00)" forHTTPHeaderField:@"User-Agent"];
            [request setHTTPBody:encryptData];
            NSLog(@"http rest encryptData:%@",encryptData);

            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSLog(@"responseResult:response: %@,data: %@, error:%@",response,data,error.localizedDescription);
                if(!error){
                    NSString *url = [[response URL] absoluteString];
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSDictionary *head = [httpResponse allHeaderFields];
                    BOOL gzip = [[head objectForKey:@"gh-gzip"] boolValue];
                    
                    id tempDecrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decrypt:stringKey:"),data,@"404ccc36a0e27a28");
                    id decrptResult = nil;
                    if(gzip){
                        id temp = [[SocketManager shareManager] uncompressZippedData:tempDecrptResult];
                        decrptResult = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
                        NSLog(@"decript result:%@",decrptResult);
                    }else{
                        decrptResult = [[NSString alloc] initWithData:tempDecrptResult encoding:NSUTF8StringEncoding];
                        NSLog(@"decript result:%@",decrptResult);
                    }
                    
                    id label = [dic objectForKey:@"label"];
                    id state = [dic objectForKey:@"state"];
                    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",label,@"label",state,@"state", nil];
                    if(decrptResult){
                        [resultDic setObject:decrptResult forKey:@"data"];
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    
                    [[SocketManager shareManager] writeDataToClient:resultDic];
                }
            }];

            [task resume];
        }];*/
    }
}
