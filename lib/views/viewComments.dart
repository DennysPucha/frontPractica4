  import 'dart:developer';
  import 'package:flutter/material.dart';
  import 'package:noticias/controls/servicio_back/FacadeService.dart';

  class ViewComments extends StatefulWidget {
    const ViewComments({Key? key}) : super(key: key);
    static const routeName = '/ViewCommentsAll';
    @override
    _ViewCommentsState createState() => _ViewCommentsState();
  }

  class _ViewCommentsState extends State<ViewComments> {
    List<Map<String, dynamic>> comentarios = [];
    bool isLoading = true;
    String? externalId;

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      final arguments = ModalRoute.of(context)?.settings.arguments;
      externalId = arguments is String ? arguments : null;

      if (externalId != null) {
        log("external de la noticia ingresada $externalId");
        cargarComentarios();
      } else {
        log("Error: No se pudo obtener externalId");
      }
    }

    Future<void> cargarComentarios() async {
      try {
        log("Entró a comentarios");
        FacadeService servicio = FacadeService();
        var value = await servicio.getComentarios(externalId!);
        
        if (value.code == 200) {
          log("Entró a 200");
          setState(() {
            comentarios = List<Map<String, dynamic>>.from(value.datos);
          });
        } else {
          log(value.msg.toString());
          final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
          ScaffoldMessenger.of(context).showSnackBar(msg);
        }
      } catch (error) {
        log("Error al obtener Comentarios: $error");
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
          title: Text('Comentarios'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              alignment: Alignment.topCenter,
              color: Colors.white70,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 50,
                  dataRowHeight: 70,
                  columns: [
                    DataColumn(label: Text('Texto')),
                    DataColumn(label: Text('Fecha de publicacion')),
                    DataColumn(label: Text('Usuario')),
                    DataColumn(label: Text('Latitud')),
                    DataColumn(label: Text('Longitud')),
                  ],
                  rows: comentarios
                      .asMap()
                      .entries
                      .where((entry) => entry.value['estado'] == true)
                      .map(
                        (entry) => DataRow(
                          cells: [
                            DataCell(Text(comentarios[entry.key]['texto'])),
                            DataCell(Text(comentarios[entry.key]['fecha'])),
                            DataCell(Text(comentarios[entry.key]['usuario'])),
                            DataCell(Text(comentarios[entry.key]['latitud'].toString())),
                            DataCell(Text(comentarios[entry.key]['longitud'].toString())),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void main() {
    runApp(const MaterialApp(
      home: ViewComments(),
    ));
  }
