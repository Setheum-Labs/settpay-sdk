import 'dart:convert';

import 'package:settpay_sdk/api/apiAccount.dart';
import 'package:settpay_sdk/api/apiGov.dart';
import 'package:settpay_sdk/api/apiKeyring.dart';
import 'package:settpay_sdk/api/apiRecovery.dart';
import 'package:settpay_sdk/api/apiSetting.dart';
import 'package:settpay_sdk/api/apiStaking.dart';
import 'package:settpay_sdk/api/apiTx.dart';
import 'package:settpay_sdk/api/apiUOS.dart';
import 'package:settpay_sdk/api/apiWalletConnect.dart';
import 'package:settpay_sdk/api/subscan.dart';
import 'package:settpay_sdk/api/types/networkParams.dart';
import 'package:settpay_sdk/service/index.dart';
import 'package:settpay_sdk/storage/keyring.dart';

/// The [SettPayApi] instance is the wrapper of `polkadot-js/api`.
/// It provides:
/// * [ApiKeyring] of npm package [@polkadot/keyring](https://www.npmjs.com/package/@polkadot/keyring)
/// * [ApiSetting], the [networkConst] and [networkProperties] of `polkadot-js/api`.
/// * [ApiAccount], for querying on-chain data of accounts, like balances or indices.
/// * [ApiTx], sign and send tx.
/// * [ApiStaking] and [ApiGov], the staking and governance module of substrate.
/// * [ApiUOS], provides the offline-signature ability of polkawallet.
/// * [ApiRecovery], the social-recovery module of Kusama network.
class SettPayApi {
  SettPayApi(this.service);

  final SubstrateService service;

  NetworkParams _connectedNode;

  ApiKeyring keyring;
  ApiSetting setting;
  ApiAccount account;
  ApiTx tx;

  ApiStaking staking;
  ApiGov gov;
  ApiUOS uos;
  ApiRecovery recovery;

  ApiWalletConnect walletConnect;

  final SubScanApi subScan = SubScanApi();

  void init() {
    keyring = ApiKeyring(this, service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);
    tx = ApiTx(this, service.tx);

    staking = ApiStaking(this, service.staking);
    gov = ApiGov(this, service.gov);
    uos = ApiUOS(this, service.uos);
    recovery = ApiRecovery(this, service.recovery);

    walletConnect = ApiWalletConnect(this, service.walletConnect);
  }

  NetworkParams get connectedNode => _connectedNode;

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams> connectNode(
      Keyring keyringStorage, List<NetworkParams> nodes) async {
    _connectedNode = null;
    final NetworkParams res = await service.webView.connectNode(nodes);
    if (res != null) {
      _connectedNode = res;

      // update indices of keyPairs after connect
      keyring.updateIndicesMap(keyringStorage);
    }
    return res;
  }

  /// subscribe message.
  Future<void> subscribeMessage(
    String JSCall,
    List params,
    String channel,
    Function callback,
  ) async {
    service.webView.subscribeMessage(
      'settings.subscribeMessage($JSCall, ${jsonEncode(params)}, "$channel")',
      channel,
      callback,
    );
  }

  /// unsubscribe message.
  void unsubscribeMessage(String channel) {
    service.webView.unsubscribeMessage(channel);
  }
}
