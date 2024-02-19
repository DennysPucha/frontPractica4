import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:noticias/controls/Conexion.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';
import 'package:validators/validators.dart';

class SessionView extends StatefulWidget {
  const SessionView({Key? key}) : super(key: key);

  @override
  _SessionViewState createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController correoControl = TextEditingController();
  final TextEditingController claveControl = TextEditingController();

  void _iniciar() {
    setState(() {
      FacadeService servicio = FacadeService();
      if (_formKey.currentState!.validate()) {
        //Conexion c=Conexion();
        //c.get("noticias", false);
        Map<String, String> mapa = {
          "correo": correoControl.text,
          "clave": claveControl.text
        };
        log(mapa.toString());
        servicio.login(mapa).then((value) async {
          log(value.tag.toString());
          if (value.code == 200) {
            Utiles util = Utiles();
            util.saveValue('token', value.datos['token']);
            util.saveValue('external', value.datos['external']);
            util.saveValue('user', value.datos['user']);
            util.saveValue('rolUser', value.datos['rol']);
            final SnackBar msg = SnackBar(
                content: Text('EXITO! BIENVENIDO ${value.datos["user"]}'));
            ScaffoldMessenger.of(context).showSnackBar(msg);
            if (value.datos['rol'] == 'admin') {
              Navigator.pushNamed(context, '/admin');
            } else {
              Navigator.pushNamed(context, '/principal');
            }
            // log(value.datos.toString());
          } else {
            final SnackBar msg = SnackBar(content: Text(value.tag.toString()));
            ScaffoldMessenger.of(context).showSnackBar(msg);
          }
        });

        log("entro aqui");
      } else {
        log("Errores");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(32),
          children: <Widget>[
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text("Noticias",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 30))),
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text("Noticias de todo el mundo aqui",
                    style: TextStyle(fontSize: 20))),
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text("Inicio de sesion",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: correoControl,
                decoration: const InputDecoration(
                    labelText: 'Correo',
                    suffixIcon: Icon(Icons.alternate_email)),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Debe ingresar su correo";
                  }
                  if (!isEmail(value)) {
                    return "Debe ingresar un correo valido";
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Clave', suffixIcon: Icon(Icons.key)),
                controller: claveControl,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Debe ingresar su clave";
                  }
                },
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton(
                  child: const Text("Inicio"), onPressed: _iniciar),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("¿No tienes cuenta?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Registrate',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
