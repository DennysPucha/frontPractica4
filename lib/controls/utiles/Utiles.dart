import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Utiles{
  final _storage = const FlutterSecureStorage();
  void saveValue(key,value) async{
    await _storage.write(key: key, value: value);
  }
  Future<String?> getValue(key) async{
    return await _storage.read(key: key);
  }

  void removeValue(key) async{
    await _storage.delete(key: key);
  }

  void removeAll() async{
    await _storage.deleteAll();
  }

}