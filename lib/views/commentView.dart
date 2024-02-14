import 'dart:developer';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';
import 'package:validators/validators.dart';
import 'package:intl/intl.dart';

class CommentView extends StatefulWidget {
  const CommentView({Key? key}) : super(key: key);
  static const routeName = '/CommentView';

  @override
  _CommentViewState createState() => _CommentViewState();
}

class _CommentViewState extends State<CommentView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController textoControl = TextEditingController();

  void _iniciar(String externalId) {
  setState(() async {
    if (_formKey.currentState!.validate()) {
      FacadeService servicio = FacadeService();
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Utiles util = Utiles();

      try {
        String? external_user = await util.getValue('external');

        if (external_user != null) {
          Map<String, String> mapa = {
            "texto": textoControl.text,
            "fecha": formattedDate,
            "usuario": external_user,
            "noticia": externalId,
          };

          log(mapa.toString());
          servicio.postComentario(mapa).then((value) async {
            if (value.code == 200) {
              final SnackBar msg = SnackBar(content: Text('Comentario guardado con exito'));
              ScaffoldMessenger.of(context).showSnackBar(msg);
              Navigator.pushNamed(context, '/principal');
              log(value.datos.toString());
            } else {
              final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
              ScaffoldMessenger.of(context).showSnackBar(msg);
            }
          });
        } else {
          log("Error: No se pudo obtener el valor de external_user.");
        }
      } catch (e) {
        log("Error al obtener el valor de external_user: $e");
      }
    } else {
      log("Errores");
    }
  });
}

  void _enviar() {
    // Lógica para enviar el formulario
    log("Formulario enviado");
  }

  @override
  Widget build(BuildContext context) {
    final externalId = ModalRoute.of(context)?.settings.arguments as String;
    log("external de la noticia ingresada $externalId");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comentario"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(); // Navegar hacia atrás
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _iniciar(externalId);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: textoControl,
                maxLines: 5,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Debe ingresar su comentario";
                  }
                },
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton(
                child: const Text("Guardar Comentario"),
                onPressed: () {
                  _iniciar(externalId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: CommentView(),
  ));
}
