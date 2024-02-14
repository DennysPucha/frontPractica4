import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({ Key? key }) : super(key: key);

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombresC = TextEditingController(); // Define nombresC
  final TextEditingController apellidosC = TextEditingController(); // Define apellidosC
  final TextEditingController correoC = TextEditingController(); // Define correoC
  final TextEditingController claveC = TextEditingController(); // Define claveC

  void _iniciar(){
    setState(() {
      FacadeService servicio = FacadeService();
      if(_formKey.currentState!.validate()){
        Map<String, String> mapa = {
          "nombres": nombresC.text,
          "apellidos": apellidosC.text,
          "clave": claveC.text,
          "correo": correoC.text,
        };
        //log(mapa.toString());
        servicio.registro(mapa).then((value) async {
          if(value.code==200){
            final SnackBar msg=SnackBar(content: Text('Cuenta creada con exito'));
            ScaffoldMessenger.of(context).showSnackBar(msg);
            Navigator.pushNamed(context, '/home');
          }else{
            final SnackBar msg=SnackBar(content: Text(value.tag.toString()));
            ScaffoldMessenger.of(context).showSnackBar(msg);
          }
        });
      }else{
        log("okn't");
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
              child: const Text(
                "Noticias",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 30,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                "Registro",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: nombresC,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nombres',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese sus nombres';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: apellidosC,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Apellidos',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese sus apellidos';
                  }
                  return null;
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: correoC,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Correo',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su correo';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: claveC,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Clave',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su clave';
                  }
                  return null;
                },
              ),
            ),
            
            
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton(
                onPressed: _iniciar,
                child: const Text("Registrar"),
              ),
            ), 
            Row(
              children: <Widget>[
                const Text("¿Ya tienes cuenta?"),
                TextButton(
                  child: const Text(
                    'Inicia sesión',
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}