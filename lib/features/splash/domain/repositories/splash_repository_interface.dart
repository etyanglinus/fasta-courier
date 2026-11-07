import 'package:fasta_deliveries_delivery/interface/repository_interface.dart';

abstract class SplashRepositoryInterface extends RepositoryInterface {
  Future<dynamic> getConfigData();
  Future<bool> initSharedData();
  Future<bool> removeSharedData();
  bool handleInitialTopicSubscription();
  bool showLangIntro();
  Future<bool> disableLangIntro();
}
