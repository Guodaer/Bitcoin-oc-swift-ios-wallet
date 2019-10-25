// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "BTCOutpoint.h"
#import "BTCTransaction.h"
#import "BTCHashID.h"

@implementation BTCOutpoint

- (id) initWithHash:(NSData*)hash index:(uint32_t)index {
    if (hash.length != 32) return nil;
    if (self = [super init]) {
        _txHash = hash;
        _index = index;
    }
    return self;
}

- (id) initWithTxIDs:(NSString*)txid index:(uint32_t)index {
    NSData* hash = BTCHashFromID(txid);
    return [self initWithHash:hash index:index];
}

- (NSString*) txID {
    return BTCIDFromHash(self.txHash);
}

- (void) setTxID:(NSString *)txID {
    self.txHash = BTCHashFromID(txID);
}

- (NSUInteger) hash {
    const NSUInteger* words = _txHash.bytes;
    return words[0] + self.index;
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

- (BOOL) isEqual:(BTCOutpoint*)object {
    return [self.txHash isEqual:object.txHash] && self.index == object.index;
}

- (id) copyWithZone:(NSZone *)zone {
    return [[BTCOutpoint alloc] initWithHash:_txHash index:_index];
}

@end
