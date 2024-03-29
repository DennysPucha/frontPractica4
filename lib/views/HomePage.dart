import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noticias/controls/Conexion.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  Future<void> verComentariosUser(String externalId) async {
    try {
      FacadeService servicio = FacadeService();
      var value = await servicio.getComentarios(externalId);
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

  Future<void> verComentariosNoti(String externalNoticia) async {
    try {
      Utiles util = Utiles();
      String? externalUser = await util.getValue('external');
      FacadeService servicio = FacadeService();
      Map<String, String> mapa = {"persona": externalUser.toString()};
      var value = await servicio.verComentariosUserNoti(externalNoticia, mapa);
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
          _comentariosLocales = comentariosAPI;
        });
      } else {
        final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
    } catch (error) {
      print("Error al obtener comentarios: $error");
    }
  }

  Future<void> agregarComentario(String externalId) async {
    String comentario = _commentController.text;
    Utiles util = Utiles();
    String? external_user = await util.getValue('external');

    // Verificar y solicitar permiso de ubicación si es necesario
    if (await Permission.location.isGranted) {
      try {
        Position position = await _determinarposicion();

        String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        Map<String, String> mapa = {
          "texto": comentario,
          "usuario": external_user.toString(),
          "fecha": formattedDate,
          "latitud": position.latitude.toString(),
          "longitud": position.longitude.toString(),
          "noticia": externalId,
        };

        var response = await FacadeService().postComentario(mapa);
        if (response.code == 200) {
          // Marcar que se agregó un comentario con éxito
          comentarioAgregado = true;
        } else {
          showPlatformDialog(
            context: context,
            builder: (context) {
              return BasicDialogAlert(
                title: Text("Error"),
                content: Text(response.msg.toString()),
                actions: <Widget>[
                  BasicDialogAction(
                    title: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        print('Error al obtener la posición: $e');
      }
    } else {
      await Permission.location.request();
    }
  }

  Future<Position> _determinarposicion() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
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
    await verComentariosUser(externalId);
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
                            DropdownMenuItem(
                              value: true,
                              child: Text("Mis comentarios"),
                            ),
                          ],
                          onChanged: (value) async{
                            setState(() {
                              mostrarMisComentarios = value!;
                              
                            });
                            //await verComentariosUser(externalId);
                          },
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
                            trailing: (mostrarMisComentarios)
                                ? PopupMenuButton<String>(
                                    onSelected: (String choice) async {
                                      if (choice == 'editar') {
                                        _showEditCommentSheet(
                                          comentario['texto'],
                                          (editedText) async {
                                            await editarComentario(
                                              comentario['external_id'],
                                              editedText,
                                              noticias[entryKey]['external_id'],
                                            );
                                            setState(() {});
                                          },
                                        );
                                      } else if (choice == 'cancelar') {}
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'editar',
                                        child: Text('Editar comentario'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'cancelar',
                                        child: Text('Cancelar'),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () async {
                            await agregarComentario(externalId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Comentario agregado')),
                            );
                            await verComentariosNoti(externalId);
                            await verComentariosUser(externalId);
                            setState(() {});
                            _commentController.clear();
                          },
                          icon: Icon(Icons.send),
                        ),
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

  Future<void> editarComentario(
      String externalId, String comentario, String externalNoticia) async {
    Utiles util = Utiles();
    String? externalUser = await util.getValue('external');
    Position position = await _determinarposicion();
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, String> mapa = {
      "texto": comentario,
      "usuario": externalUser.toString(),
      "latitud": position.latitude.toString(),
      "longitud": position.longitude.toString(),
      "fecha": formattedDate,
    };
    var response = await FacadeService().modifyComment(mapa, externalId);
    if (response.code == 200) {
      SnackBar msg = SnackBar(content: Text('Comentario editado'));
      ScaffoldMessenger.of(context).showSnackBar(msg);

      await verComentariosNoti(externalNoticia); // Actualiza los comentarios
      await actualizarComentarios();
      await verComentariosUser(externalId);
    } else {
      showPlatformDialog(
        context: context,
        builder: (context) {
          return BasicDialogAlert(
            title: Text("Error"),
            content: Text(response.msg.toString()),
            actions: <Widget>[
              BasicDialogAction(
                title: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> actualizarComentarios() async {
    setState(() {
      comentarios = List.from(_comentariosLocales);
      print("simn simn$comentarios");
    });
  }

  void _showEditCommentSheet(String initialText, Function(String) onSave) {
    TextEditingController _editController =
        TextEditingController(text: initialText);

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Editar comentario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _editController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        onSave(_editController.text);
                        Navigator.of(context).pop();
                      },
                      child: Text('Guardar'),
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
                color: Colors.blue,
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
    home: HomePage(),
  ));
}
