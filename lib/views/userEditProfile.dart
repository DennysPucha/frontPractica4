import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/utiles/Utiles.dart';

class UserEditProfile extends StatefulWidget {
  const UserEditProfile({Key? key}) : super(key: key);

  @override
  _UserEditProfileState createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombresC = TextEditingController();
  final TextEditingController apellidosC = TextEditingController();
  final TextEditingController fechaC = TextEditingController();
  final TextEditingController direccionC = TextEditingController();
  final TextEditingController celularC = TextEditingController();
  final TextEditingController correoC = TextEditingController();
  final TextEditingController claveC = TextEditingController();
  DateTime? selectedDate;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    cargarData();
  }

  void cargarData() async {
    Utiles  utiles = Utiles();
    String? user = await utiles.getValue('external');
    var response = await FacadeService().getUser(user!);
    
    print(response.datos);


    nombresC.text = response.datos['nombres'] ?? '';
    apellidosC.text = response.datos['apellidos'] ?? '';
    fechaC.text = response.datos['fecha_nac'] ?? '';
    direccionC.text = response.datos['direccion'] != "NONE" ? response.datos['direccion'] : '';
    celularC.text = response.datos['celular'] != "NONE" ? response.datos['celular'] : '';
    correoC.text = response.datos['cuenta']['correo'] ?? '';
    selectedDate = response.datos['fecha_nac'] != null ? DateTime.parse(response.datos['fecha_nac']) : null;
    claveC.text = response.datos['cuenta']['clave'] ?? '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fechaC.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      showPassword = !showPassword;
    });
  }

 void _iniciar() async {
  if (_formKey.currentState!.validate()) {
    Utiles utiles = Utiles();
    String? user= await utiles.getValue('external');
    Map<String, String> mapa = {
      "nombres": nombresC.text,
      "apellidos": apellidosC.text,
      "fecha": fechaC.text,
      "direccion": direccionC.text,
      "celular": celularC.text,
      "correo": correoC.text,
      "clave": claveC.text,
    };
    var value = await FacadeService().modifyUser(mapa, user!);
    if (value.code == 200) {
      final SnackBar msg = SnackBar(content: Text('Perfil actualizado'));
      ScaffoldMessenger.of(context).showSnackBar(msg);
      Navigator.pop(context);
    } else {
      final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
      ScaffoldMessenger.of(context).showSnackBar(msg);
    }
  } else {
    print("no furula");
  }
}
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Editar Perfil'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(32),
          children: <Widget>[
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
                    return 'Por favor ingrese su nombre';
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
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: fechaC,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Fecha de Nacimiento',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su fecha de nacimiento';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: direccionC,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Dirección',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su dirección';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: celularC,
                keyboardType:   TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Número de Celular',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de celular';
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
                  labelText: 'Correo Electrónico',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su correo electrónico';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextFormField(
                    controller: claveC,
                    obscureText: !showPassword,
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
                  IconButton(
                    onPressed: _togglePasswordVisibility,
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _iniciar,
                  child: const Text('Guardar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Regresar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
