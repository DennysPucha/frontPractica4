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

   Future<RespuestaGenerica> getNoticia(String external) async {
    return await c.get('noticia/get/$external', false);
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
    return await c.get('noticia/get/comentarios/$external', true);
  }

  Future<RespuestaGenerica> getAllComentarios() async {
    return await c.get('comentarios', true);
  }

  Future<RespuestaGenerica> verComentariosUserNoti(String externalNoticia, Map<String, String> mapa) async {
    Map<String, String> header = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    final String _url = c.URL + "noticia/get/comentariosbyUser/$externalNoticia";
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
        isw.tag = "OK!Obtencion correcto";
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

  Future<RespuestaGenerica> postComentario(Map<String, String> mapa) async {
    return await c.post('comentario/save', true, mapa);
  }

  Future<RespuestaGenerica> getUser(String external) async {
    return await c.get('persona/get/$external', true);
  }

  Future<RespuestaGenerica> modifyUser(
      Map<String, String> mapa, String external) async {
    return await c.post('persona/modificar/$external',true, mapa);
  }

  Future<RespuestaGenerica> modifyComment(
      Map<String, String> mapa, String external) async {
    return await c.post('comentario/modify/$external', true, mapa);
  }

  Future<RespuestaGenerica> banearUsuarioxComentario(String external, Map<String, String> mapa) async {
    return await c.post('comentario/banear/$external', true, mapa);
  }

  
}
