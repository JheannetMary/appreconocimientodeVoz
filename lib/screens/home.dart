// grabadora_page.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:dialogflow_flutter/language.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:dialogflow_flutter/dialogflowFlutter.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  List<String> mensajes = ["hola", "quiero hacer un pedido"];
  String _textoEscuchado = 'Presiona y mantén presionado para grabar';
  bool _grabando = false;
  String _texto = "";
  String _iaresponseAPI = "";
  bool _available = false;

  late stt.SpeechToText _speech = stt.SpeechToText();
  double _confidence = 0;

  late String grabacionPath;

  late Record audioRecord;
  late AudioPlayer audioplayer;
  String? audiopath = "";
  // Inicializa la librería FLUTTER TTS
  FlutterTts flutterTts = FlutterTts();

  // Inicializa la librería Record
  void response(query) async {
    try {
      AuthGoogle authGoogle = await AuthGoogle(
              fileJson: "assets/pedidos-colchones-e6e6d625f407.json")
          .build();
      DialogFlow dialogflow =
          DialogFlow(authGoogle: authGoogle, language: Language.spanish);
      AIResponse aiResponse = await dialogflow.detectIntent(query);
      setState(() {
        /* messsages.insert(0, {
        "data": 0,
        "message": aiResponse.getListMessage()?[0]["text"]["text"][0].toString()
      });*/
        _iaresponseAPI =
            aiResponse.getListMessage()![0]["text"]["text"][0].toString();
        mensajes.add(_iaresponseAPI);
        _ReproducirTexto(_iaresponseAPI);
      });

      print(aiResponse.getListMessage()?[0]["text"]["text"][0].toString());
    } catch (e) {
      print("error");
      mensajes.add("ha ocurrrido un error!");
    }
  }

  Future<void> _initspeach() async {
    bool available2 = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    setState(() {
      _available = available2;
    });
  }

  @override
  void initState() {
    // audioplayer = AudioPlayer();
    //audioRecord = Record();
    super.initState();
    // _speech = stt.SpeechToText();
    _initspeach();
  }
  // Inicializa la librería Record

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - PEDIDOS'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(mensajes[index]),
                );
              },
            )),
            Text(_textoEscuchado),
            GestureDetector(
              onLongPress: () async {
                await iniciarGrabacion();
                setState(() {
                  _textoEscuchado = 'Grabando...';
                });
              },
              onLongPressEnd: (details) async {
                await detenerGrabacion();
                //await reconocerVoz();
                setState(() {
                  _textoEscuchado = 'Reconociendo...';
                });
                await Future.delayed(Duration(seconds: 2));

                setState(() {
                  _textoEscuchado = 'Presiona y mantén presionado para grabar';
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _grabando ? Colors.red : Colors.blue,
                ),
                child: Icon(
                  _grabando ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> iniciarGrabacion() async {
    // Inicia la grabación y obtén la ruta del archivo grabado
    try {
      _texto = "";
      setState(() {
        _grabando = true;
      });
      /*  bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'),
        );*/
      if (_available) {
        _speech.listen(
          onResult: (val) => setState(() {
            _texto = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
      /* if (await audioRecord.hasPermission()) {
        // await audioRecord.start();

        setState(() {
          _grabando = true;
        });
        /*  bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'),
        );*/
        if (_available) {
          _speech.listen(
            onResult: (val) => setState(() {
              _texto = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            }),
          );
        }
      }*/
    } catch (e) {
      print("error");
    }
  }

  Future<void> detenerGrabacion() async {
    // Inicia la grabación y obtén la ruta del archivo grabado
    try {
      //  String? audiopath = await audioRecord.stop();
      _speech.stop();
      setState(() {
        _grabando = false;
        grabacionPath = audiopath!;
      });
      mensajes.add(_texto);
      _ReproducirTexto(_texto);
      //playaudio();
      _texto == ""
          ? mensajes.add("habla mas fuerte porfavor!")
          : response(_texto);
      print(_texto);
    } catch (e) {
      print("error");
    }
  }

  Future<void> _ReproducirTexto(String texto_a_reproducir) async {
    await flutterTts.setLanguage("es-ES"); // Establecer el idioma
    await flutterTts.setPitch(1.0); // Establecer el tono
    await flutterTts.setSpeechRate(0.5); // Establecer la velocidad

    await flutterTts.speak(texto_a_reproducir);
  }

  Future<void> playaudio() async {
    // Inicia la grabación y obtén la ruta del archivo grabado
    try {
      Source urlsource = UrlSource(grabacionPath);
      await audioplayer.play(urlsource);
    } catch (e) {
      print("error");
    }
  }

  Future<List<int>> leerArchivoComoBytes(String filePath) async {
    File file = File(filePath);
    return await file.readAsBytes();
  }

  Future<List<int>> _getAudioContent() async {
    // Asegúrate de que el archivo M4A esté presente en la ruta adecuada
    final path = grabacionPath;

    try {
      // Lee el contenido del archivo M4A como bytes
      List<int> audioBytes = await File(path).readAsBytes();
      return audioBytes;
    } catch (e) {
      print('Error al leer el archivo M4A: $e');
      return <int>[]; // o maneja el error de la manera que desees
    }
  }

  Future<void> reconocerVoz() async {
    if (grabacionPath != null && grabacionPath != "") {
      print("se obtuvo el audio");
      // Lee el archivo grabado como bytes

      //   List<int> audioBytes = await leerArchivoComoBytes(grabacionPath);

      List<int> audioBytes = await _getAudioContent();

      // Llama a la función que maneja los bytes del audio
      String response = await reconocerVozApi(audioBytes);
      print(response);
    } else {
      print('No hay grabación para procesar.');
    }
  }

  Future<String> reconocerVozApi(List<int> audioBytes) async {
    // Define la URL de la API de Speech-to-Text
    const url =
        'https://speech.googleapis.com/v1/speech:recognize?key=AIzaSyBOanzfn8rDLStsBP3agkhHyUbxTTJvq3g';

    // Reemplaza 'TU_CLAVE_DE_API' con tu clave de API real

    // Construye la estructura de la solicitud JSON
    // 'encoding': 'LINEAR16',
    //     'sampleRateHertz': 16000,
    //     'languageCode': 'es-ES', // Cambia según el idioma que desees

    final requestBody = {
      'config': {
        'encoding': 'FLAC',
        'sampleRateHertz': 44100,
        'languageCode': 'es-ES'
      },
      'audio': {
        'uri': "https://storage.googleapis.com/proyreconocimiento/Voz-002.flac"
      },
    };

    // Realiza la solicitud HTTP POST a la API de Speech-to-Text
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    print(response.body);

    // Maneja la respuesta de la API
    if (response.statusCode == 200) {
      // Procesa y extrae el texto reconocido de la respuesta

      print(response.body);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> results = responseData['results'];
      if (results.isNotEmpty) {
        final String transcription =
            results.first['alternatives'].first['transcript'];
        print(transcription);
        return transcription;
      } else {
        return 'No se encontraron resultados de reconocimiento.';
      }
    } else {
      // Maneja errores en la respuesta de la API
      return 'Error en la solicitud a la API: ${response.statusCode}';
    }
  }
}
