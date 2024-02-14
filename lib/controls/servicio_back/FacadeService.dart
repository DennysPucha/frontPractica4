import 'dart:convert';

import 'package:noticias/controls/Conexion.dart';
import 'package:noticias/controls/servicio_back/RespuestaGenerica.dart';
import 'package:noticias/controls/servicio_back/modelo/InicioSesion.dart';
import "package:http/http.dart" as http;
import 'dart:developer';
class FacadeService {
  Conexion c = Conexion();
  Future<InicioSesionSw> login(Map<String, String> mapa) async {
    Map<String, String> header = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    final String _url = c.URL + "inicio_sesion";
    final uri = Uri.parse(_url);

    InicioSesionSw isw = InicioSesionSw();
    try {
      final response =
          await http.post(uri, headers: header, body: jsonEncode(mapa));
      //log(response.body);
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          isw.code = 404;
          isw.msg = "Page not found";
          isw.tag = "error";
          isw.datos = [];
        } else {
          Map<dynamic, dynamic> mapa = jsonDecode(response.body);
          isw.code = mapa['code'];
          isw.msg = mapa['msg'];
          isw.tag = mapa['tag'];
          isw.datos = mapa['datos'];
        }
      } else {
        Map<dynamic, dynamic> mapa = jsonDecode(response.body);
        isw.code = mapa['code'];
        isw.msg = mapa['msg'];
        isw.tag = "OK! Inicio sesion correcto";
        isw.datos = mapa['datos'];
      }
    } catch (e) {
      isw.code = 500;
      isw.msg = "Internal error";
      isw.tag = "error";
      isw.datos = [];
    }
    return isw;
  }

  Future<RespuestaGenerica> getNoticias() async {
    return await c.get('noticias', false);
  }

  Future<InicioSesionSw> registro(Map<String, String> mapa) async {
    Map<String, String> header = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    final String _url = c.URL + "persona/saveUser";
    final uri = Uri.parse(_url);

    InicioSesionSw isw = InicioSesionSw();
    try {
      final response =
          await http.post(uri, headers: header, body: jsonEncode(mapa));
      log(response.body);
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          isw.code = 404;
          isw.msg = "Page not found";
          isw.tag = "error";
          isw.datos = [];
        } else {
          Map<dynamic, dynamic> mapa = jsonDecode(response.body);
          isw.code = mapa['code'];
          isw.msg = mapa['msg'];
          isw.tag = mapa['tag'];
          isw.datos = mapa['datos'];
        }
      } else {
        Map<dynamic, dynamic> mapa = jsonDecode(response.body);
        isw.code = mapa['code'];
        isw.msg = mapa['msg'];
        isw.tag = "OK! Registro correcto";
        isw.datos = mapa['datos'];
      }
    } catch (e) {
      isw.code = 500;
      isw.msg = "Internal error";
      isw.tag = "error";
      isw.datos = [];
    }
    return isw;
  }

  Future<RespuestaGenerica> getComentarios(String external) async {
    return await c.get('noticia/get/comentarios/$external', false);
  }

  Future<RespuestaGenerica> postComentario(Map<String, String> mapa) async {
    return await c.post('comentario/save', false, mapa);
  }

}
