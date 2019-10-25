// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "BTCAssetType.h"

NSString* __nonnull const BTCAssetTypeBitcoin = @"bitcoin";
NSString* __nonnull const BTCAssetTypeOpenAssets = @"openassets";

//[GDChiefHomeLiveModel chiefLive_netPage:self.page ud_ub_id:self.theChiefid lvrr_id:self.lvr_id completeSuccess:^(GDChiefHomeLiveModel * _Nonnull mod) {
//    [weakSelf.gdcollection.mj_header endRefreshing];
//    [weakSelf.gdcollection.mj_footer endRefreshing];
//    if (weakSelf.page == 1) {
//        weakSelf.allModel = mod;
//    }else {
//        [weakSelf.allModel.history_list addObjectsFromArray:mod.history_list];
//    }
//    [weakSelf.gdcollection reloadData];
//
//} failed:^{
//    if (weakSelf.page != 1) {
//        weakSelf.page -= 1;
//    }
//    [weakSelf.gdcollection.mj_header endRefreshing];
//    [weakSelf
