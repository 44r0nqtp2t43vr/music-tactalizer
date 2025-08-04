import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:mini_music_app/services/ble_service.dart';
import 'package:mini_music_app/services/logger_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final logger = await LoggerService.getInstance();

  // Dependencies
  sl.registerSingleton<BLEService>(BLEService());

  Get.put<BLEService>(sl());

  sl.registerSingleton<LoggerService>(logger);

  Get.put<LoggerService>(sl());

  // UseCases
  // sl.registerSingleton<ScanDevicesUseCase>(ScanDevicesUseCase(sl()));

  // Blocs
  // sl.registerFactory<BluetoothBloc>(() => BluetoothBloc(sl(), sl(), sl(), sl(), sl()));
}
