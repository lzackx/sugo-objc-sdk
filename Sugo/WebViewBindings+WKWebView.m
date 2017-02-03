//
//  WebViewBindings+WKWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+WKWebView.h"
#import "WebViewBindings+WebView.h"
#import "Sugo.h"
#import "MPSwizzler.h"
#import "SugoPrivate.h"


@implementation WebViewBindings (WKWebView)

- (void)startWKWebViewBindings:(WKWebView **)webView
{
    if (!self.wkWebViewJavaScriptInjected) {
        self.wkWebViewCurrentJSTrack = [self wkJavaScriptTrack];
        self.wkWebViewCurrentJSSource = [self wkJavaScriptSource];
        self.wkWebViewCurrentJSExcute = [self wkJavaScriptExcute];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSTrack];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSExcute];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewBindingsTrack"];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewBindingsTime"];
        self.wkWebViewJavaScriptInjected = YES;
        NSLog(@"WKWebView Injected");
    }
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindingsTrack"];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindingsTime"];
        self.wkWebViewJavaScriptInjected = NO;
        self.wkWebView = nil;
    }
}

- (void)updateWKWebViewBindings:(WKWebView **)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        NSMutableArray<WKUserScript *> *userScripts = [[NSMutableArray<WKUserScript *> alloc]
                                                       initWithArray:(*webView).configuration.userContentController.userScripts];
        if ([userScripts containsObject:self.wkWebViewCurrentJSSource]) {
            [userScripts removeObject:self.wkWebViewCurrentJSSource];
        }
        if ([userScripts containsObject:self.wkWebViewCurrentJSExcute]) {
            [userScripts removeObject:self.wkWebViewCurrentJSExcute];
        }
        [(*webView).configuration.userContentController removeAllUserScripts];
        for (WKUserScript *userScript in userScripts) {
            [(*webView).configuration.userContentController addUserScript:userScript];
        }
        self.wkWebViewCurrentJSSource = [self wkJavaScriptSource];
        self.wkWebViewCurrentJSExcute = [self wkWebViewCurrentJSExcute];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSExcute];
        NSLog(@"WKWebView Updated");
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        if ([message.name isEqualToString:@"WKWebViewBindingsTrack"]) {
            NSDictionary *body = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)message.body];
            WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
            storage.eventID = (NSString *)body[@"eventID"];
            storage.eventName = (NSString *)body[@"eventName"];
            storage.properties = (NSString *)body[@"properties"];
            NSData *pData = [storage.properties dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *pJSON = [NSJSONSerialization JSONObjectWithData:pData
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil];
            if (pJSON != nil)
            {
                [[Sugo sharedInstance] track:storage.eventID
                                   eventName:storage.eventName
                                  properties:pJSON];
            }
            else
            {
                [[Sugo sharedInstance] track:storage.eventID
                                   eventName:storage.eventName];
            }
            NSLog(@"HTML Event: id = %@, name = %@", storage.eventID, storage.eventName);
        } else if ([message.name isEqualToString:@"WKWebViewBindingsTime"]) {
            NSDictionary *body = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)message.body];
            NSString *eventName = [[NSString alloc] initWithString:(NSString *)body[@"eventName"]];
            if (eventName) {
                [[Sugo sharedInstance] timeEvent:eventName];
            }
        }
    } else {
        NSLog(@"Wrong message body type: name = %@, body = %@", message.name, message.body);
    }
}

- (WKUserScript *)wkJavaScriptTrack
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewTrack
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptSource
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsSource
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptExcute
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsExcute
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (NSString *)jsWKWebViewTrack
{
    NSString *track = [self jsSourceOfFileName:@"WebViewTrack"];
    
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.wkWebView.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacement = [Sugo loadConfigurationPropertyListWithName:@"SugoResourcesPathReplacement"];
    if (replacement) {
        for (NSString *key in replacement.allKeys) {
            relativePath = [NSMutableString stringWithFormat:@"%@.replace(/%@/g, %@)",
                            relativePath,
                            key.length>0?key:@" ",
                            ((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@"''"];
            
            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key.length>0?key:@""]
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
            nativePath = [re stringByReplacingMatchesInString:nativePath
                                                      options:0
                                                        range:NSMakeRange(0, nativePath.length)
                                                 withTemplate:((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@""];
            
        }
    }
    relativePath = [NSMutableString stringWithFormat:@"%@;", relativePath];
    
    NSMutableString *pn = [[NSMutableString alloc] init];
    NSMutableString *ic = [[NSMutableString alloc] init];
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:nativePath]) {
                pn = info[@"page"];
                ic = info[@"code"];
                break;
            }
        }
    }
    NSMutableString *pageName = [NSMutableString stringWithFormat:@"sugo.page_name = %@;", pn.length>0?pn:@"''"];
    NSMutableString *initCode = [NSMutableString stringWithFormat:@"sugo.init_code = %@;", ic.length>0?ic:@"''"];

    NSString *wk = [self jsSourceOfFileName:@"WebViewTrack.WK"];
    
    return [[[[track stringByAppendingString:relativePath]
              stringByAppendingString:pageName]
             stringByAppendingString:initCode]
            stringByAppendingString:wk];
    
    
}

- (NSString *)jsWKWebViewBindingsSource
{
    
    NSString *part1 = [self jsSourceOfFileName:@"WebViewBindings.1"];
    NSString *vcPath = [NSString stringWithFormat:@"sugo_bindings.current_page = '%@::' + window.location.pathname;\n", self.wkVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo_bindings.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *part2 = [self jsSourceOfFileName:@"WebViewBindings.2"];
    
    return [[[part1 stringByAppendingString:vcPath]
             stringByAppendingString:bindings]
            stringByAppendingString:part2];
}

- (NSString *)jsWKWebViewBindingsExcute
{
    return [self jsSourceOfFileName:@"WebViewBindings.excute"];
}

@end









