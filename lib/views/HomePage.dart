import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:noticias/controls/Conexion.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/views/commentView.dart';
import 'package:noticias/views/viewComments.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> noticias = [];
  Conexion c = Conexion();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
    try {
      log("Entró a noticias");
      FacadeService servicio = FacadeService();
      var value = await servicio.getNoticias();

      if (value.code == 200) {
        log("Entró a 200");
        setState(() {
          noticias = List<Map<String, dynamic>>.from(value.datos);
          log(noticias.toString());
          log(noticias[0]['archivo'].toString());
        });
      } else {
        log(value.msg.toString());
        final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
    } catch (error) {
      log("Error al obtener noticias: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Noticias'),
        centerTitle: true,
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
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(noticias[entry.key]['titulo']),
                              content: SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(noticias[entry.key]['cuerpo']),
                                      if (noticias[entry.key]['archivo'].toString() != "noticia.png")
                                        Image.network(c.URL_MEDIA + noticias[entry.key]['archivo'].toString())
                                    ],
                                  ),
                                ),
                              ),
                              contentPadding: EdgeInsets.all(16),
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
                      },
                      child: ListTile(
                        title: Text(noticias[entry.key]['titulo']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${noticias[entry.key]['fecha']}'),
                            Text('Tipo de noticia: ${noticias[entry.key]['tipo_noticia']}'),
                          ],
                        ),
                        leading: noticias[entry.key]['archivo'].toString() != "noticia.png"
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(c.URL_MEDIA + noticias[entry.key]['archivo'].toString()),
                              )
                            : SizedBox.shrink(),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_note_rounded),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  CommentView.routeName,
                                  arguments: noticias[entry.key]['external_id'],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.sentiment_very_satisfied_rounded),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  ViewComments.routeName,
                                  arguments: noticias[entry.key]['external_id'],
                                );
                              },
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
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}
