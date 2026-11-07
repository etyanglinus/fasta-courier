import 'package:get/get.dart';
import 'package:fasta_deliveries_delivery/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:fasta_deliveries_delivery/features/splash/domain/services/splash_service_interface.dart';

class SplashService implements SplashServiceInterface {
  final SplashRepositoryInterface splashRepositoryInterface;
  SplashService({required this.splashRepositoryInterface});

  @override
  Future<Response> getConfigData() async {
    return await splashRepositoryInterface.getConfigData();
  }

  @override
  Future<bool> initSharedData() {
    return splashRepositoryInterface.initSharedData();
  }

  @override
  Future<bool> removeSharedData() {
    return splashRepositoryInterface.removeSharedData();
  }

  @override
  bool handleInitialTopicSubscription() {
    return splashRepositoryInterface.handleInitialTopicSubscription();
  }

  @override
  bool showLangIntro() {
    return splashRepositoryInterface.showLangIntro();
  }

  @override
  Future<bool> disableLangIntro() {
    return splashRepositoryInterface.disableLangIntro();
  }
}
