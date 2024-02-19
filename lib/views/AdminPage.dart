import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noticias/controls/Conexion.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> noticias = [];
  List<Map<String, dynamic>> comentarios = [];
  List<Map<String, dynamic>> _comentariosLocales = [];
  List<Map<String, dynamic>> comentariosAPI = [];

  Conexion c = Conexion();
  bool isLoading = true;
  TextEditingController _commentController = TextEditingController();
  bool comentarioAgregado = false;
  String user = '';

  @override
  void initState() {
    super.initState();
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
    try {
      FacadeService servicio = FacadeService();
      var value = await servicio.getNoticias();
      Utiles util = Utiles();
      var user = await util.getValue('user');
      setState(() {
        this.user = user.toString();
      });
      if (value.code == 200) {
        setState(() {
          noticias = List<Map<String, dynamic>>.from(value.datos);
        });
      } else {
        final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
    } catch (error) {
      print("Error al obtener noticias: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verComentariosNoti(String externalNoticia) async {
    try {
      Utiles util = Utiles();
      String? externalUser = await util.getValue('external');
      FacadeService servicio = FacadeService();
      Map<String, String> mapa = {"persona": externalUser.toString()};
      var value = await servicio.getComentarios(externalNoticia);
      if (value.code == 200) {
        var comentariosAPI = List<Map<String, dynamic>>.from(value.datos);
        for (var comentario in comentariosAPI) {
          var response = await FacadeService().getUser(comentario['usuario']);

          if (response.code == 200) {
            var usuario = response.datos;
            comentario['user'] =
                "${usuario['nombres']} ${usuario['apellidos']}";
          } else {
            comentario['user'] = "Usuario Desconocido";
          }
        }
        setState(() {
          comentarios = comentariosAPI;
        });
      } else {
        final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
    } catch (error) {
      print("Error al obtener comentarios: $error");
    }
  }

  void cerrarSesion() async {
    Utiles util = Utiles();
    util.removeAll();
    SnackBar msg = SnackBar(content: Text('Sesión cerrada'));
    ScaffoldMessenger.of(context).showSnackBar(msg);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _showCommentsDialog(int entryKey) async {
    String externalId = noticias[entryKey]['external_id'].toString();
    comentarios.clear();
    comentarioAgregado = true;
    await verComentariosNoti(externalId);
    bool mostrarMisComentarios = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Text(
                            noticias[entryKey]['titulo'],
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(noticias[entryKey]['cuerpo']),
                        SizedBox(height: 8),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Comentarios",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        DropdownButton<bool>(
                          value: mostrarMisComentarios,
                          items: [
                            DropdownMenuItem(
                              value: false,
                              child: Text("Todos los comentarios"),
                            ),
                          ],
                          onChanged: (value) async {},
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: mostrarMisComentarios
                            ? _comentariosLocales.length
                            : comentarios.length,
                        itemBuilder: (context, index) {
                          var comentario = mostrarMisComentarios
                              ? _comentariosLocales[index]
                              : comentarios[index];
                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_2_rounded,
                                      size: 15,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      comentario['user'],
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(comentario['texto']),
                                SizedBox(height: 4),
                                Text(
                                  comentario['fecha'],
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.block,
                                  color: Colors.red), // Icono rojo para banear
                              onPressed: () async {
                                // Lógica para banear el comentario
                                String externalId =comentario['external_id'].toString();
                                String noticia=noticias[entryKey]['external_id'].toString();
                                await banearComentario(externalId,noticia);
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

Future<void> banearComentario(String externalId, String noticia) async {
  try {
    bool? confirmacion = await mostrarDialogoConfirmacion(context);
    if (confirmacion != null && confirmacion) {
      FacadeService servicio = FacadeService();
      Map<String, String> mapa = {"comentario": externalId};
      var response = await servicio.banearUsuarioxComentario(externalId,mapa);
      if (response.code == 200) {
        await verComentariosNoti(noticia);
        final SnackBar msg = SnackBar(content: Text('Comentario baneado exitosamente'));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      } else {
        final SnackBar msg = SnackBar(content: Text(response.msg.toString()));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
    }
  } catch (error) {
    print("Error al banear comentario: $error");
  }
}

Future<bool?> mostrarDialogoConfirmacion(BuildContext context) async {
  return await showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmación'),
        content: Text('¿Estás seguro de que quieres banear a esta persona?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Confirma la acción
            },
            child: Text('Sí'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Cancela la acción
            },
            child: Text('Cancelar'),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Noticias'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.greenAccent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'https://img.freepik.com/vector-premium/icono-perfil-usuario-estilo-plano-ilustracion-vector-avatar-miembro-sobre-fondo-aislado-concepto-negocio-signo-permiso-humano_157943-15752.jpg'),
                  ),
                  Text(
                    user.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Editar perfil'),
              onTap: () {
                Navigator.pushNamed(context, '/editarPerfilUser');
              },
            ),
            ListTile(
              leading: Icon(Icons.share_location),
              title: Text('Ver Mapa de comentarios'),
              onTap: () {
                Navigator.pushNamed(context, '/mapa');
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar sesión'),
              onTap: () {
                cerrarSesion();
              },
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            children: noticias
                .asMap()
                .entries
                .map(
                  (entry) => Card(
                    color: Colors.blueGrey[50],
                    child: InkWell(
                      onTap: () {
                        _showCommentsDialog(entry.key);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            noticias[entry.key]['archivo'].toString() !=
                                    "noticia.png"
                                ? Image.network(
                                    c.URL_MEDIA +
                                        noticias[entry.key]['archivo']
                                            .toString(),
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : SizedBox.shrink(),
                            SizedBox(height: 8),
                            Text(
                              noticias[entry.key]['titulo'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Fecha: ${noticias[entry.key]['fecha']}'),
                            Text(
                                'Tipo de noticia: ${noticias[entry.key]['tipo_noticia']}'),
                            ButtonBar(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.share_location),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/mapa',
                                        arguments: {
                                          'external': noticias[entry.key]
                                                  ['external_id']
                                              .toString()
                                        });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminPage(),
  ));
}
