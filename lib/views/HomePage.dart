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
  Conexion c = Conexion();
  bool isLoading = true;
  TextEditingController _commentController = TextEditingController();
  bool comentarioAgregado = false;
  String user='';

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
      var user=await util.getValue('user');
      setState(() {
        this.user=user.toString();
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

  Future<void> verComentariosNoti(String externalId) async {
    try {
      FacadeService servicio = FacadeService();
      var value = await servicio.getComentarios(externalId);
      if (value.code == 200) {
        setState(() {
          comentarios = List<Map<String, dynamic>>.from(value.datos);
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
    comentarios.clear(); // Limpiar la lista de comentarios
    await verComentariosNoti(externalId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(noticias[entryKey]['titulo']),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height *
                    0.5, // Ajusta la altura según tu preferencia
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(noticias[entryKey]['cuerpo']),
                    SizedBox(height: 8),
                    Text(
                      "Comentarios",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    // Lista de comentarios
                    Expanded(
                      child: comentarios.isEmpty && !comentarioAgregado
                          ? Center(
                              child: Text('No hay comentarios'),
                            )
                          : ListView.builder(
                              itemCount: comentarios.length,
                              itemBuilder: (context, index) {
                                var comentario = comentarios[index];
                                return ListTile(
                                  title: Text(comentario['texto']),
                                  subtitle: Text(
                                    '${comentario['usuario']} - ${comentario['fecha']}',
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 8),
                    // Agregar comentario
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
                            await verComentariosNoti(externalId); // Esperar a que se carguen los comentarios
                            setState(() {}); // Actualizar la interfaz
                            _commentController.clear();
                          },
                          icon: Icon(Icons.send),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
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
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://img.freepik.com/vector-premium/icono-perfil-usuario-estilo-plano-ilustracion-vector-avatar-miembro-sobre-fondo-aislado-concepto-negocio-signo-permiso-humano_157943-15752.jpg'),
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
                // Implementar acción de editar perfil aquí
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
                .where((entry) => entry.value['estado'] == true)
                .map(
                  (entry) => Card(
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
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}
