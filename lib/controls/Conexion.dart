import 'dart:convert';
import 'package:noticias/controls/servicio_back/RespuestaGenerica.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:noticias/controls/utiles/Utiles.dart';

class Conexion {
  final String URL = "http://192.168.3.10:3000/api/admin/";
  final String URL_MEDIA = "http://192.168.3.10:3000/multimedia/";
  static bool NO_TOKEN = false;

  Future<RespuestaGenerica> get(String recurso, bool token) async {
    RespuestaGenerica respuesta = RespuestaGenerica();

    Map<String, String> _header = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };
    if (token) {
      Utiles util = Utiles();
      String? tokenA = await util.getValue('token');
      log(tokenA.toString() + '**');
      _header["news-token"] = tokenA.toString();
    }
    final String _url = URL + recurso;
    final uri = Uri.parse(_url);
    try {
      final response = await http.get(uri, headers: _header);
      //log(response.body;
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          respuesta = _response(404, "Page not found", []);
        } else {
          respuesta = _response(response.statusCode, "Error", []);
        }
      } else {
        Map<dynamic, dynamic> mapa = jsonDecode(response.body);
        respuesta = _response(mapa['code'], mapa['msg'], mapa['datos']);
      }
    } catch (e) {
      respuesta = _response(500, "Internal error", []);
    }
    return respuesta;
  }

  RespuestaGenerica _response(int code, String msg, dynamic datos) {
    var respuesta = RespuestaGenerica();
    respuesta.code = code;
    respuesta.msg = msg;
    respuesta.datos = datos;
    return respuesta;
  }

  Future<RespuestaGenerica> post(String recurso, bool token, Map<dynamic,dynamic> mapa) async {
    RespuestaGenerica respuesta = RespuestaGenerica();

    Map<String, String> _header = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };
    if (token) {
      Utiles util = Utiles();
      String? tokenA = await util.getValue('token');
      log(tokenA.toString() + '**');
      _header["news-token"] = tokenA.toString();
    }
    final String _url = URL + recurso;
    final uri = Uri.parse(_url);
    log(_url);
    try {
      final response = await http.post(uri, headers: _header, body:jsonEncode(mapa));
      log(response.body);
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          respuesta = _response(404, "Page not found", []);
        } else {
          respuesta = _response(response.statusCode, "Error", []);
        }
      } else {
        Map<dynamic, dynamic> mapa = jsonDecode(response.body);
        respuesta = _response(mapa['code'], mapa['msg'], mapa['datos']);
      }
    } catch (e) {
      respuesta = _response(500, "Internal error", []);
    }
    return respuesta;
  }
}
