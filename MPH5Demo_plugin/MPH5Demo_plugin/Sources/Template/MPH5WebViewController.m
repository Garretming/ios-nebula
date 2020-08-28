//
//  MPH5WebViewController.m
//  MPH5Demo
//
//  Created by shifei.wkp on 2019/2/3.
//  Copyright © 2019 alipay. All rights reserved.
//

#import "MPH5WebViewController.h"
#import <MPNebulaAdapter/MPH5ErrorHelper.h>

@interface MPH5WebViewController () <PSDPluginProtocol>

@end

@implementation MPH5WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[NebulaDemo]: 容器中的一个Scene被打开");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 当前页面的WebView
    UIWebView *webView = (UIWebView *)self.psdContentView;
    NSLog(@"[mpaas] webView: %@", webView);
    
    // 当前页面的启动参数
    NSDictionary *expandParams = self.psdScene.createParam.expandParams;
    NSLog(@"[mpaas] expandParams: %@", expandParams);
    
    if ([expandParams count] > 0) {
        [self customNavigationBarWithParams:expandParams];
    }
}

- (void)customNavigationBarWithParams:(NSDictionary *)expandParams
{
    // 定制导航栏背景
    NSString *titleBarColorString = expandParams[@"titleBarColor"];
    if ([titleBarColorString isKindOfClass:[NSString class]] && [titleBarColorString length] > 0) {
        UIColor *titleBarColor = [UIColor colorFromHexString_au:titleBarColorString];
        [self.navigationController.navigationBar setNavigationBarStyleWithColor:titleBarColor translucent:NO];
        [self.navigationController.navigationBar setNavigationBarBottomLineColor:titleBarColor];
    }
    
    //导航栏是否隐藏，默认不隐藏。设置隐藏后，webview需全屏
    NSString *showTitleBar = expandParams[@"showTitleBar"];
    if (showTitleBar && ![showTitleBar boolValue]) {
        self.options.showTitleBar = NO;
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    //导航栏是否透明，默认不透明。设置透明后，webview需全屏
//    NSString *transparentTitle = expandParams[@"transparentTitle"];
//    if ([transparentTitle isEqualToString:@"always"] || [transparentTitle isEqualToString:@"auto"]) {
//
//        // 导航栏和底部横线变为透明
//        UIColor *clearColor = [UIColor clearColor] ;
//        [self.navigationController.navigationBar setNavigationBarTranslucentStyle];
//        [self.navigationController.navigationBar setNavigationBarStyleWithColor:clearColor translucent:YES];
//
//        // 调整webview的位置
//        self.edgesForExtendedLayout = UIRectEdgeAll;
//        if (@available(iOS 11.0, *)) {
//            UIWebView *wb = (UIWebView *)[self psdContentView];
//            wb.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//        }else{
//            self.automaticallyAdjustsScrollViewInsets = NO;
//        }
//    }
    
    // 修改默认返回按钮文案颜色
    NSString *backButtonColorString = expandParams[@"backButtonColor"];
    if ([backButtonColorString isKindOfClass:[NSString class]] && [backButtonColorString length] > 0) {
        UIColor *backButtonColor = [UIColor colorFromHexString:backButtonColorString];
        
        NSArray *leftBarButtonItems = self.navigationItem.leftBarButtonItems;
        if ([leftBarButtonItems count] == 1) {
            if (leftBarButtonItems[0] && [leftBarButtonItems[0] isKindOfClass:[AUBarButtonItem class]]) {
                AUBarButtonItem *backItem = leftBarButtonItems[0];
                backItem.titleColor = backButtonColor;
                backItem.backButtonColor = backButtonColor;
            }
        }
    }
    
    // 设置标题颜色
    NSString *titleColorString = expandParams[@"titleColor"];
    if ([titleColorString isKindOfClass:[NSString class]] && [titleColorString length] > 0) {
        UIColor *titleColor = [UIColor colorFromHexString_au:titleColorString];
        id<NBNavigationTitleViewProtocol> titleView = self.navigationItem.titleView;
        [[titleView mainTitleLabel] setFont:[UIFont systemFontOfSize:16]];
        [[titleView mainTitleLabel] setTextColor:titleColor];
    }
    
}

- (void)customNavigationBarView
{
    // 自定义导航栏view
    [self.navigationController.navigationBar setHidden:YES];
    UIView *naviBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, AUCommonUIGetScreenWidth(), 200)];
    naviBarView.backgroundColor = [UIColor redColor];
    [self.view addSubview:naviBarView];
    self.customNavigationBar = naviBarView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self.url.absoluteString containsString:@"H52Native"]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"sendEvent" style:UIBarButtonItemStylePlain target:self action:@selector(sendEventToH5)];
    }
}

- (void)sendEventToH5
{
    // native向 H5 发送事件
    [self callHandler:@"nativeEvent" data:@{@"key1":@"value1"} responseCallback:^(id responseData) {
        
    }];
    
}

- (void)runJSFromNative
{
    // native 执行一段 JS
    [self.psdContentView evaluateJavaScript:@"alert(\'run js from native\')" completionHandler:^(id  _Nonnull result, NSError * _Nonnull error) {

    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (NSURL *)url
{
    // 设置当前页面的url
    NSURL *url = [NSURL URLWithString:self.viewControllerProxy.options.url];
    NSLog(@"MTH5WebviewController current url :%@", url);
    return url;
}

#pragma mark - 注册为容器插件
- (void)nbViewControllerInit
{
    [super nbViewControllerInit];
    
    PSDSession *session = [self viewControllerProxy].psdSession;
    [session addEventListener:kEvent_Navigation_All
                 withListener:self
                   useCapture:NO];
    [session addEventListener:kEvent_Page_All
                 withListener:self
                   useCapture:NO];
    
}

- (NSString *)name
{
    return NSStringFromClass([self class]);
}

#pragma mark - 对应UIWebViewDelegate的委托实现

- (void)handleEvent:(PSDEvent *)event
{
    [super handleEvent:event];
    
    if (![[event.context currentViewController] isEqual:self]) {
        return;
    }
    
    if ([kEvent_Navigation_Start isEqualToString:event.eventType]) {
        // 此事件可拦截当前url是否加载
        BOOL shouldStart = [self handleContentViewShouldStartLoad:(id)event ];
        
        if (!shouldStart) {
            [event preventDefault];
        }
    }
    else if ([kEvent_Page_Load_Start isEqualToString:event.eventType]) {
        [self handleContentViewDidStartLoad:(id)event];
    }
    else if ([kEvent_Page_Load_Complete isEqualToString:event.eventType]) {
        [self handleContentViewDidFinishLoad:(id)event];
    }
    else if ([kEvent_Navigation_Error isEqualToString:event.eventType]) {
        [self handleContentViewDidFailLoad:(id)event];
    }
}


- (BOOL)handleContentViewShouldStartLoad:(PSDNavigationEvent *)event
{
    return YES;
}

- (void)handleContentViewDidStartLoad:(PSDPageEvent *)event
{
    
}

- (void)handleContentViewDidFinishLoad:(PSDPageEvent *)event
{
    
}

- (void)handleContentViewDidFailLoad:(PSDNavigationEvent *)event
{
    PSDNavigationEvent *naviEvent = (PSDNavigationEvent *)event;
    NSError *error = naviEvent.error;
    [MPH5ErrorHelper handlErrorWithWebView:(UIWebView *)self.psdContentView error:error];
}

@end
