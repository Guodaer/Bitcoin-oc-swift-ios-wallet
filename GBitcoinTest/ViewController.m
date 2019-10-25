//
//  ViewController.m
//  GBitcoinTest
//
//  Created by GD on 2019/10/25.
//  Copyright © 2019 GD. All rights reserved.
//

#import "ViewController.h"
#import "BTCMnemonic.h"
#import "BTCKey.h"
#import "BTCAddress.h"
#import "BTCKeychain.h"
#import "BTCNetwork.h"

#import "BTCTransaction.h"
#import "BTCTransactionInput.h"
#import "BTCScriptMachine.h"
#import "BTCTransactionOutput.h"
#import "BTCScript.h"
#import "BTCData.h"
#import "BTCBigNumber.h"
#import "BTCBase58.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //    pod 'OpenSSL', :git => 'https://github.com/bither/OpenSSL.git'
//需要添加openssl依赖库   再把coreBitcoin 加到项目中就可以   下面助记词生成私钥、地址， 生成交易广播需要的参数
    
}


//通过助记词导入
- (void)btc_createWithMnemonics:(NSString *)mnemonics type:(NSString *)type block:(void(^)(NSString *address,NSString *mnemonicPhrase,NSString *privateKey,BOOL success,NSString *ErrorMessage))block {
    NSArray *words = [mnemonics componentsSeparatedByString:@" "];
    
//这里要验证助记词是否正确 验证好之后解析助记词
    
    BTCMnemonic *mn = [[BTCMnemonic alloc]initWithWords:words password:nil wordListType:BTCMnemonicWordListTypeEnglish];
    
    BTCKeychain *accountkeyChain = mn.keychain;
    BTCKey *btckey= [accountkeyChain keyWithPath:@"m/44'/0'/0'/0/0"];//m/44'/195'/x'
    NSString *btcaddress = [btckey compressedPublicKeyAddress].string;
    NSString *privateStr = btckey.WIF;
    block(btcaddress,mnemonics,privateStr,YES,nil);
    
}

//通过私钥创建
- (void)btc_importPrivate:(NSString *)privatekey type:(NSString *)type block:(void(^)(NSString *address,NSString *privateKey,BOOL success,NSString *ErrorMessage))block{

    BTCKey *key = [[BTCKey alloc] initWithWIF:privatekey];
    if (!key) {
        block(@"",@"",NO,(@"输入私钥错误!"));
        return;
    }
    NSString *btcAddress= [key compressedPublicKeyAddress].string;
    
    
    if (!btcAddress) {
        block(@"",@"",NO,(@"输入私钥错误!"));
        return;
    }
    block(btcAddress,privatekey,YES,nil);
}



+ (void)transferTest {
    //输入金额
    NSString *coin = @"输入金额";
    NSString *floatCoin = [NSString stringWithFormat:@"%lf",[coin doubleValue]*100000000];
    BTCAmount value = [floatCoin integerValue];
    NSString *toAddress = @"接收地址";

    NSString *private = @"私钥";
    BTCKey *privateKey = [[BTCKey alloc] initWithWIF:private];

    float feeRate = 1 ;//@"费率  sat"
    NSError *error;

    BTCTransaction* transaction = [self transactionSpendingFromPrivateKey:privateKey
                                                               to:[BTCPublicKeyAddress addressWithString:toAddress]
                                                           change:privateKey.address // send change to the same address
                                                           amount:value
                                                          feeRate:feeRate
                                                            error:&error
                                                            utxos:@[]];
    
    
    
//后面拿着  [transaction hex] 去广播就OK
    
}
//btc转账    usdt转账跟btc基本上一样，节点相关接口也都可以提供  如有咨询请加qq：1023251767有偿咨询
+ (BTCTransaction*) transactionSpendingFromPrivateKey:(BTCKey*)key
                                                   to:(BTCPublicKeyAddress*)destinationAddress
                                               change:(BTCPublicKeyAddress*)changeAddress
                                               amount:(BTCAmount)amount
                                              feeRate:(float)feeRate
                                                error:(NSError**)errorOut
                                                utxos:(NSArray*)utxos{
    
    NSError* error = nil;
    
    if (!utxos) {
        *errorOut = error;
//        余额不足
        return nil;
    }
    
    //判断找零地址是否是同一个
    BTCAmount fee = 222*feeRate;
    // Find enough outputs to spend the total amount.
    BTCAmount totalAmount = amount + fee;
    BTCAmount dustThreshold = 0;
    
    utxos = [utxos sortedArrayUsingComparator:^(BTCTransactionOutput* obj1, BTCTransactionOutput* obj2) {
        if ((obj1.value - obj2.value) < 0) return NSOrderedAscending;
        else return NSOrderedDescending;
    }];
    NSArray* txouts = nil;
    for (BTCTransactionOutput* txout in utxos) {//筛选一下有没有一个unspent够支付此次的
        if (txout.value > (totalAmount + dustThreshold) && txout.script.isPayToPublicKeyHashScript) {
            txouts = @[ txout ];
            break;
        }
    }
    
    BTCAmount allCoins = 0;
    NSMutableArray *array = [NSMutableArray array];
    if (!txouts) {//如果没有，那input 一个就不够了
        for (BTCTransactionOutput *txout in utxos) {
            
            if (allCoins > (totalAmount + dustThreshold)) {
                break;
            }else{
                if (txout.script.isPayToPublicKeyHashScript) {
                    allCoins += txout.value;
                    [array addObject:txout];
                }
            }
        }
    }else{
        array = [NSMutableArray arrayWithArray:txouts];
    }
    
    BTCTransaction* tx = [[BTCTransaction alloc] init];
    BTCAmount spentCoins = 0;
    
    // Add all outputs as inputs
    for (BTCTransactionOutput* txout in array) {
        BTCTransactionInput* txin = [[BTCTransactionInput alloc] init];
        txin.previousHash = txout.transactionHash;
        txin.previousIndex = txout.index;
        [tx addInput:txin];
        NSLog(@"txhash: http://blockchain.info/rawtx/%@", BTCHexFromData(txout.transactionHash));
        NSLog(@"txhash: http://blockchain.info/rawtx/%@ (reversed)", BTCHexFromData(BTCReversedData(txout.transactionHash)));
        
        spentCoins += txout.value;
        //如果txouts的金额足够了就不再添加txouts了
        if(spentCoins - (totalAmount + dustThreshold)>=0){
            break;
        }
    }
    //如果txouts的金额小于转账金额+交易费时不能创建交易
    if(spentCoins - (totalAmount + dustThreshold)<0){
//        余额不足
        return nil;
    }
    
//    创建out
    BTCTransactionOutput* paymentOutput = [[BTCTransactionOutput alloc] initWithValue:amount address:destinationAddress];
    BTCTransactionOutput* changeOutput = [[BTCTransactionOutput alloc] initWithValue:(spentCoins - (amount + fee)) address:key.address];//找零
    [tx addOutput:paymentOutput];
    [tx addOutput:changeOutput];
    
//    构建交易 并签名
    for (int i = 0; i < array.count; i++) {
        
        BTCTransactionOutput* txout = array[i];
        BTCTransactionInput* txin = tx.inputs[i];
        
        BTCScript* sigScript = [[BTCScript alloc] init];
        
        NSData* d1 = tx.data;
        
        BTCSignatureHashType hashtype = BTCSignatureHashTypeAll;
        
        NSData* hash = [tx signatureHashForScript:txout.script inputIndex:i hashType:hashtype error:errorOut];
        
        NSData* d2 = tx.data;
        
        NSAssert([d1 isEqual:d2], @"Transaction must not change within signatureHashForScript!");
        
        // 134675e153a5df1b8e0e0f0c45db0822f8f681a2eb83a0f3492ea8f220d4d3e4
        NSLog(@"Hash for input %d: %@", i, BTCHexFromData(hash));
        if (!hash) {
//            交易构建失败
            return nil;
        }
        NSData* signatureForScript = [key signatureForHash:hash hashType:hashtype];
        [sigScript appendData:signatureForScript];
        
        [sigScript appendData:key.publicKey];
        
        NSData* sig = [signatureForScript subdataWithRange:NSMakeRange(0, signatureForScript.length - 1)]; // trim hashtype byte to check the signature.
        NSAssert([key isValidSignature:sig hash:hash], @"Signature must be valid");
        
        txin.signatureScript = sigScript;
    }
    {
        BTCScriptMachine* sm = [[BTCScriptMachine alloc] initWithTransaction:tx inputIndex:0];
        NSError* error = nil;
        BOOL r = [sm verifyWithOutputScript:[[(BTCTransactionOutput*)array[0] script] copy] error:&error];
        if(!r){
            NSLog(@"Error: %@", error);//GDText(@"交易签名失败")
            
//            交易签名失败   error.description
            return nil;
        }
        
    }
    
    return tx;
}
@end
