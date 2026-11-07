import 'package:get/get.dart';

abstract class SplashServiceInterface {
  Future<Response> getConfigData();
  Future<bool> initSharedData();
  Future<bool> removeSharedData();
  bool handleInitialTopicSubscription();
  bool showLangIntro();
  Future<bool> disableLangIntro();
}