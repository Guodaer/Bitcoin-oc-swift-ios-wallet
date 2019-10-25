// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "BTCProcessor.h"
#import "BTCNetwork.h"
#import "BTCBlock.h"
#import "BTCBlockHeader.h"
#import "BTCTransaction.h"
#import "BTCTransactionInput.h"
#import "BTCTransactionOutput.h"

NSString* const BTCProcessorErrorDomain = @"BTCProcessorErrorDomain";

@implementation BTCProcessor

- (id) init {
    if (self = [super init]) {
        self.network = [BTCNetwork mainnet];
    }
    return self;
}


// Macros to prepare NSError object and check with delegate if the error should cause failure or not.

#define REJECT_BLOCK_WITH_ERROR(ERROR_CODE, MESSAGE, ...) { \
    NSError* error = [NSError errorWithDomain:BTCProcessorErrorDomain code:(ERROR_CODE) \
                                     userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:MESSAGE, __VA_ARGS__] }]; \
    if ([self shouldRejectBlock:block withError:error]) { \
        [self notifyDidRejectBlock:block withError:error]; \
        *errorOut = error; \
        return NO; \
    } \
}

#define REJECT_BLOCK_WITH_DOS(ERROR_CODE, DOS_LEVEL, MESSAGE, ...) { \
    NSError* error = [NSError errorWithDomain:BTCProcessorErrorDomain code:ERROR_CODE \
                                     userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:MESSAGE, __VA_ARGS__], @"DoS": @(DOS_LEVEL) }]; \
    if ([self shouldRejectBlock:block withError:error]) { \
        [self notifyDidRejectBlock:block withError:error]; \
        *errorOut = error; \
        return NO; \
    } \
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


// Attempts to process the block. Returns YES on success, NO and error on failure.
- (BOOL) processBlock:(BTCBlock*)block error:(NSError**)errorOut {
    if (!self.dataSource) {
        @throw [NSException exceptionWithName:@"Cannot process block" reason:@"-[BTCProcessor dataSource] is nil." userInfo:nil];
    }
    
    // 1. Check for duplicate blocks
    
    NSData* hash = block.blockHash;
    
    if ([self.dataSource blockExistsWithHash:hash]) {
        REJECT_BLOCK_WITH_ERROR(BTCProcessorErrorDuplicateBlock, NSLocalizedString(@"Already have block %@", @""), hash);
    }
    
    if ([self.dataSource orphanBlockExistsWithHash:hash]) {
        REJECT_BLOCK_WITH_ERROR(BTCProcessorErrorDuplicateOrphanBlock, NSLocalizedString(@"Already have orphan block %@", @""), hash);
    }
    
    
    
    return YES;
}


// Attempts to add transaction to "memory pool" of unconfirmed transactions.
- (BOOL) processTransaction:(BTCTransaction*)transaction error:(NSError**)errorOut {
    
    // TODO: ...
    
    return NO;
}



#pragma mark - Helpers


- (BOOL) shouldRejectBlock:(BTCBlock*)block withError:(NSError*)error {
    return (![self.delegate respondsToSelector:@selector(processor:shouldRejectBlock:withError:)] ||
            [self.delegate processor:self shouldRejectBlock:block withError:error]);
}

- (void) notifyDidRejectBlock:(BTCBlock*)block withError:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(processor:didRejectBlock:withError:)]) {
        [self.delegate processor:self didRejectBlock:block withError:error];
    }
}


@end
