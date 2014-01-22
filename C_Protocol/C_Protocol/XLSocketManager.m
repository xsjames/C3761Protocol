//
//  XLSocketManager.m
//  XLDistributionBoxApp
//
//  Created by JY on 13-7-10.
//  Copyright (c) 2013年 XLDZ. All rights reserved.
//


#import "XLSocketManager.h"
#import "XL3761UnPack.h"
#import "XLParser.h"

@interface XLSocketManager()

@property (nonatomic, retain) NSOperationQueue* operatrionQueue;
@property (nonatomic, retain) NSData *frameData;


@end

@implementation XLSocketManager

SYNTHESIZE_SINGLETON_FOR_CLASS(XLSocketManager)

@synthesize operatrionQueue=_operatrionQueue;
@synthesize socket=_socket;
@synthesize frameData;

- (id)init
{
    if ((self = [super init]) != nil) {   
        self.operatrionQueue = [[NSOperationQueue alloc] init];
        [self.operatrionQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

#pragma mark -Socket delegate Methods
/*－－－－－－－－－－－－－－－－－
  初始化并连接Socket
－－－－－－－－－－－－－－－－－*/
-(void)connection{
    self.socket = nil;
    self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err = nil;
    
    NSString *ipString  = @"10.10.2.1";
    NSInteger port = 2222;
    
    if(![self.socket connectToHost:ipString onPort:port error:&err])    {
        NSLog(@"连接错误");
    }
}

/*－－－－－－－－－－－－－－－－－
 已连接到HOST
－－－－－－－－－－－－－－－－－*/
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"已成功连接到HOST!");

    NSLog(@"发送报文:%@",[self.frameData description]);
    [self.socket writeData:self.frameData withTimeout:-1 tag:0];
    [self.socket readDataWithTimeout:-1 tag:0];
}

/*－－－－－－－－－－－－－－－－－
 收到返回数据
－－－－－－－－－－－－－－－－－*/
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
 
    NSLog(@"返回报文:%@",[data description]);
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        unsigned short type = 0;
        unsigned short inlen = [data length];
        unsigned short outlen = 0;
        Byte *outbuff = NULL;
        int  multiFrameFlag = 0;    //多帧标志
        
        if(UnPackFrame(&type,inlen, (Byte*)[data bytes], &outlen, &outbuff,&multiFrameFlag)){
            
            XLParser *parser = [[XLParser alloc] init];
            NSData *revData = [NSData dataWithBytes:outbuff length:outlen];
            [parser initWithNSData:revData];
        }
    });
    

    [sock readDataWithTimeout:-1 tag:0];
}

/*－－－－－－－－－－－－－－－－－
 SOCKET连接已断开
 －－－－－－－－－－－－－－－－－*/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"SOCKET连接已断开");
}


#pragma mark -methods..
/*－－－－－－－－－－－－－－－－－
 连接SOCKET
－－－－－－－－－－－－－－－－－*/
-(void)packRequestFrame:(NSData*)userData{
 
    self.frameData = userData;
    
    if (self.frameData) {
        [self connection];
    }
    
    
//    if (self.frameData) {
//        if (self.socket.isConnected) {
//            [self.socket writeData:self.frameData withTimeout:-1 tag:0];
//            [self.socket readDataWithTimeout:-1 tag:0];
//        } else{
//            [self connection];
//        }
//    }
}
@end