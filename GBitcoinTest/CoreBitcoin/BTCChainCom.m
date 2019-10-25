#import "BTCChainCom.h"
#import "BTCAddress.h"
#import "BTCTransactionOutput.h"
#import "BTCScript.h"
#import "BTCData.h"

@interface BTCChainCom()
@property NSString* token;
@end

@implementation BTCChainCom

// Initalizes a BTCChainCom object with a free API Token from http://chain.com
- (id)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

// Builds a request from a list of BTCAddress objects.
- (NSMutableURLRequest*) requestForUnspentOutputsWithAddress:(BTCAddress*)address {
    NSString* pathString = [NSString stringWithFormat:@"addresses/%@/unspents", [address valueForKey:@"base58String"]];
    NSURL* url = [self  chainURLWithV1BitcoinPath:pathString];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    return request;
}

// List of BTCTransactionOutput instances parsed from the response.
- (NSArray*) unspentOutputsForResponseData:(NSData*)responseData error:(NSError**)errorOut {
    if (!responseData) return nil;
    NSArray* array = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:errorOut];
    if (!array || ![array isKindOfClass:[NSArray class]]) return nil;
    
    NSMutableArray* outputs = [NSMutableArray array];

    for (NSDictionary* item in array) {
        BTCTransactionOutput* txout = [[BTCTransactionOutput alloc] init];

        txout.value = [item[@"value"] longLongValue];
        txout.script = [[BTCScript alloc] initWithString:item[@"script"]];
        txout.index = [item[@"output_index"] intValue];
        txout.transactionHash = (BTCReversedData(BTCDataFromHex(item[@"transaction_hash"])));
        [outputs addObject:txout];
    }
    
    return outputs;
}

// Makes sync request for unspent outputs and parses the outputs.
- (NSArray*) unspentOutputsWithAddress:(BTCAddress*)address error:(NSError**)errorOut {
    NSURLRequest* req = [self requestForUnspentOutputsWithAddress:address];
    NSURLResponse* response = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:errorOut];
#pragma clang diagnostic pop

    if (!data) {
        return nil;
    }
    return [self unspentOutputsForResponseData:data error:errorOut];
}


- (NSMutableURLRequest*) requestForTransactionBroadcastWithData:(NSData*)data {
    if (data.length == 0) return nil;
    
    NSString* pathString = @"transactions";
    NSURL* url = [self  chainURLWithV1BitcoinPath:pathString];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSDictionary *requestDictionary = @{@"hex":BTCHexFromData(data)};
    
    NSError *serializationError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&serializationError];
    if (serializationError != nil) {
        return nil;
    }
    
    request.HTTPMethod = @"PUT";
    request.HTTPBody = jsonData;
    return request;
}
//- (GDScrollPageView *)gdPageView {
//    if (!_gdPageView) {
//        CGFloat topHeight = [GDChiefHomeTopView getHeaderSize];
//        CGFloat tabbar_height = Height_TabbarSafeBottom;
//        CGFloat nav_height = Height_StatusBar;
//        UIImageView *scroll_TopView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerView.frame)-LineX(7.5), kScreenWidth, LineX(40))];
//        scroll_TopView.image = BullImage(@"sx_detail_top");
//        [self.view addSubview:scroll_TopView];
//
//        _gdPageView = [[GDScrollPageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerView.frame)-LineX(7.5), kScreenWidth, kScreenHeight - tabbar_height - topHeight+LineX(7.5)-nav_height)];
//        _gdPageView.superVC = self;
//        _gdPageView.titles = self.pagetitleArray;
//GDLog(#”“)辅导老师没法看了对方可能
//        _gdPageView.controllers = self.controllerArray;
//        _gdPageView.title_Color = BullColor(0x333333, 1);
//        _gdPageView.titleSelect_Color = NavbgColor;
//        _gdPageView.bottomLine_color = NavbgColor;
//        _gdPageView.lineWidth = 35;
//        _gdPageView.bottomLineHeight = 3;
//        _gdPageView.headerBarHeight = LineX(40);
//        _gdPageView.title_font = [UIFont boldSystemFontOfSize:LineX(14)];
//        _gdPageView.topBgColor = [UIColor clearColor];
//        [_gdPageView loadScrollView];
//
//    }
//    return _gdPageView;
//}

- (BOOL) broadcastTransactionData:(NSData*)data error:(NSError**)errorOut
{
    NSURLRequest* req = [self requestForTransactionBroadcastWithData:data];
    NSURLResponse* response = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:errorOut];
#pragma clang diagnostic pop

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (NSURL*) chainURLWithV1BitcoinPath:(NSString *)path
{
    NSString *baseURLString = @"https://api.chain.com/v1/bitcoin";
    NSString *URLString = [NSString stringWithFormat:@"%@/%@?key=%@", baseURLString, path, self.token];
    return [NSURL URLWithString:URLString];
}

@end
