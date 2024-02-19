import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:noticias/controls/servicio_back/FacadeService.dart';
import 'package:noticias/controls/servicio_back/RespuestaGenerica.dart';
import 'package:simple_tiles_map/simple_tiles_map.dart';
import 'package:geolocator/geolocator.dart';

class Mapa extends StatefulWidget {
  const Mapa({Key? key}) : super(key: key);

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  List<Marker> markers = [];
  Map<String, dynamic> noticia = {};
  late LatLng _currentPosition; // Variable para almacenar la posición actual
  String externalIdNoti = "";
  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(-4.027333, -79.215609); // la pordefecto :(
    _getCurrentLocation(); //obtener posicion actual
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      verComentariosUser();
    } catch (error) {
      print("Error al obtener la posición actual: $error");
    }
  }

  Future<void> verComentariosUser() async {
  try {
    FacadeService servicio = FacadeService();
    await obtenerExternalNoti();
    RespuestaGenerica value;
    if (externalIdNoti.isNotEmpty) {      
      value = await servicio.getComentarios(externalIdNoti);
      await obtenerNoticia();
      print("entro a con noti");
    } else {
      value = await servicio.getAllComentarios();
      print("entro a sin noti");
    }
    
    if (value.code == 200) {
      var comentariosAPI = List<Map<String, dynamic>>.from(value.datos);
      List<Marker> newMarkers = [];

      for (var comentario in comentariosAPI) {
        var response = await FacadeService().getUser(comentario['usuario']);

        if (response.code == 200) {
          var usuario = response.datos;
          comentario['user'] =
              "${usuario['nombres']} ${usuario['apellidos']}";
        } else {
          comentario['user'] = "Usuario Desconocido";
        }
        //print(comentario);

        var marker = Marker(
          width: 150.0,
          height: 150.0,
          point: LatLng(
            comentario['latitud'].toDouble(),
            comentario['longitud'].toDouble(),
          ),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.mode_comment_rounded,
                  color: Colors.greenAccent,
                  size: 50.0,
                ),
                SizedBox(height: 5.0),
                Text(
                  comentario['user'],
                  style: TextStyle(
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        newMarkers.add(marker);
      }

      setState(() {
        markers = newMarkers;
      });
    } else {
      final SnackBar msg = SnackBar(content: Text(value.msg.toString()));
      ScaffoldMessenger.of(context).showSnackBar(msg);
    }
  } catch (error) {
    print("Error al obtener comentarios: $error");
  }
}

Future<void> obtenerExternalNoti() async {
  try {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      final externalId = arguments['external'] as String?;
      if (externalId != null) {
        externalIdNoti = externalId;
        print("El ID externo es: $externalIdNoti");
      } else {
        print("El ID externo es nulo");
      }
    } else {
      print("Los argumentos no son de tipo Map<String, dynamic>");
    }
  } catch (e) {
    print("Error al obtener externalId: $e");
  }
}

Future<void> obtenerNoticia()async{
    try{
        var response = await FacadeService().getNoticia(externalIdNoti);
        if (response.code == 200) {
          noticia = response.datos;
          print("Noticia: $noticia");
        } else {
          final SnackBar msg = SnackBar(content: Text(response.msg.toString()));
          ScaffoldMessenger.of(context).showSnackBar(msg);
        }

    }catch(e){
      print("Error al obtener noticia: $e");
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.greenAccent,
            padding: EdgeInsets.all(16.0),
            child: Text( noticia.isNotEmpty ? "Noticia: ${noticia['titulo']}" : "Comentarios de Usuarios",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SimpleTilesMap(
              typeMap: TypeMap.esriStreets,
              mapOptions: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 13.0,
              ),
              otherLayers: [
                MarkerLayer(
                  markers: markers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
