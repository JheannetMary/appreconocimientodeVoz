// grabadora_page.dart

import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:dialogflow_flutter/language.dart';

import 'package:flutter/material.dart';

//import 'package:http/http.dart' as http;

import 'package:flutter_tts/flutter_tts.dart';

import 'package:speech_to_text/speech_to_text.dart';

import 'package:dialogflow_flutter/dialogflowFlutter.dart';

class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  List<String> mensajes = [""];
  String _textoEscuchado = 'Presiona y mantén presionado para grabar';
  bool _grabando = false;
  String texto = "";
  String _iaresponseAPI = "";
  bool _available = false;
  final List<Message> _messages = [];
  final SpeechToText speech = SpeechToText();
  double confidence = 0;
  ScrollController _scrollController = ScrollController();

  // Inicializa la librería FLUTTER TTS
  FlutterTts flutterTts = FlutterTts();
  TextEditingController _textController = TextEditingController();
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
        List<dynamic> messages = aiResponse.getListMessage()!;

        for (var messageia in messages) {
          if (messageia.containsKey('text') &&
              messageia["text"]["text"][0].toString() != "") {
            print(messageia["text"]["text"][0].toString());
            Message newMessage = Message(
                content: messageia["text"]["text"][0].toString(),
                sender: 'Dialog flow');
            setState(() {
              _messages.add(newMessage);
            });
          }
        }

        _iaresponseAPI =
            aiResponse.getListMessage()![0]["text"]["text"][0].toString();
        //   mensajes.add(_iaresponseAPI);
        Message newMessage =
            Message(content: _iaresponseAPI, sender: 'Dialog flow');
        setState(() {
          //  _messages.add(newMessage);
        });

        _ReproducirTexto(_iaresponseAPI);
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });

      print(aiResponse.getListMessage()?[0]["text"]["text"][0].toString());
    } catch (e) {
      print("error");
      mensajes.add("ha ocurrrido un error!");
    }
  }

  Future<void> _initspeach() async {
    bool available2 = await speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    setState(() {
      _available = available2;
    });
  }

  @override
  void initState() {
    super.initState();
    // _speech = stt.SpeechToText();
    _initspeach();
  }

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
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                //   return ListTile(
                //   title: Text(mensajes[index]),

                // );
                return ChatBubble(message: _messages[index]);
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

            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Ingrese su texto',
              ),
            ),
            SizedBox(height: 16.0),
            // Botón que realiza una acción con el texto ingresado
            TextButton(
              onPressed: () async {
                setState(() {
                  mensajes.add(_textController.text);
                });
                response(_textController.text);

                Message newMessage =
                    Message(content: _textController.text, sender: 'User');
                setState(() {
                  _messages.add(newMessage);
                });

                _textController.clear();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // Color de fondo del botón
                primary: Colors.white, // Color del texto del botón
                padding: EdgeInsets.all(16.0), // Relleno del botón
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8.0), // Bordes redondeados
                ),
              ),
              child: Text('Enviar Texto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> iniciarGrabacion() async {
    // Inicia la grabación y obtén la ruta del archivo grabado
    //try {
    texto = "";
    setState(() {
      _grabando = true;
    });
    /*  bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'),
        );*/

    if (_available) {
      print('escucha');
      speech.listen(
        onResult: (val) => setState(() {
          texto = val.recognizedWords;
          if (val.hasConfidenceRating && val.confidence > 0) {
            confidence = val.confidence;
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
              texto = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            }),
          );
        }
      }*/
    //  } catch (e) {
    //    print("error");
    //  }
  }

  Future<void> detenerGrabacion() async {
    // Inicia la grabación y obtén la ruta del archivo grabado
    try {
      //  String? audiopath = await audioRecord.stop();
      speech.stop();
      setState(() {
        _grabando = false;
      });
      // mensajes.add(texto);
      Message newMessage = Message(content: texto, sender: 'User');
      setState(() {
        _messages.add(newMessage);
      });
      //_ReproducirTexto(texto);
      //playaudio();
      texto == ""
          ? mensajes.add("habla mas fuerte porfavor!")
          : response(texto);
      print(texto);
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
}

class Message {
  String content;
  String sender;

  Message({required this.content, required this.sender});
}

class ChatBubble extends StatefulWidget {
  final Message message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: widget.message.sender == 'User'
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  widget.message.sender == 'User' ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.sender,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.0),
                Container(
                  width: 200.0, // Ajusta según tus necesidades
                  child: Text(
                    widget.message.content,
                    style: TextStyle(color: Colors.white),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
