#import "FlutterXmppPlugin.h"

@implementation FlutterXmppPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_xmpp/methodOne"
            binaryMessenger:[registrar messenger]];
  FlutterXmppPlugin* instance = [[FlutterXmppPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    NSLog(@"cell: %@ | result: %@", call.method, result);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
