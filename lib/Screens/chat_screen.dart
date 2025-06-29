import 'package:chat_ai/Models/message.dart';
import 'package:chat_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _controller = TextEditingController() ;
  final List<Message> _message = [] ;
  final ApiService apiService = ApiService() ;

  FlutterTts flutterTts = FlutterTts() ;
  bool _isTtsEnabled = true ;
  String _selectedLanguage = "fr-FR" ;


  Future<void> sendMessage() async {
    String message = _controller.text.trim() ;
    if(message.isEmpty) return ;

    setState(() {
      _message.add(Message(texte: message, isUserMessage: true)) ; // mssg user
      _message.add(Message(texte: "....", isUserMessage: false)) ;// standby avant reponse
      _controller.clear() ;
    });

    FocusScope.of(context).unfocus() ;
    String botResponse ;

    try {
      botResponse = await apiService.getChatResponse(message) ;
    } catch(e){
      botResponse = "Erreur lors de la recuperation de la response" ;
    }

    await Future.delayed(Duration(milliseconds: 500), (){
      setState(() {
        _message.removeLast() ;
        _message.add(Message(texte: botResponse, isUserMessage: false)) ;
      });
      _controller.clear() ;
    }) ;

  }


  Future<void> _initTts() async {
    await flutterTts.setLanguage(_selectedLanguage) ;
    await flutterTts.setSpeechRate(0.5) ;
    await flutterTts.setPitch(1.0) ;
  }

  Future<void> _speak(String text) async {
    if(_isTtsEnabled && text.isNotEmpty){
      await flutterTts.speak(text) ;
    }
  }

  void _toggleTts(){
    setState(() {
      _isTtsEnabled = !_isTtsEnabled ;
    });
    if(!_isTtsEnabled){
      flutterTts.stop() ;
    }
    else{
      if(_message.isNotEmpty && _message.last.isBotMessage){
        _speak(_message.last.texte) ;

      }
    }
  }


  void initState(){
    super.initState() ;
    _initTts() ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chat Bot"),
        actions: [
          IconButton(onPressed: _toggleTts, icon: Icon(_isTtsEnabled? Icons.volume_up :Icons.volume_off )),

          PopupMenuButton<String>(
              icon: Icon(Icons.language),
              onSelected: (String lang){
                setState(() {
                  _selectedLanguage = lang ;
                  _initTts() ;
                });

              },
              itemBuilder: (BuildContext context)=>[
                PopupMenuItem(value: "fr-FR",child: Text("Français"),),
                PopupMenuItem(value: "en-US",child: Text("English"),),
                PopupMenuItem(value: "es-ES",child: Text("Espagnol"),),
                PopupMenuItem(value: "zh-CN",child: Text("Chinois(Simplifié)"),),
              ]
          ) ,
        ],

      ),
      body: Column(
        children: [
          Expanded(child: ListView.builder(
              itemCount: _message.length,
              itemBuilder: (context , index){
                final msg = _message[index] ;
                final isUser = msg.isUserMessage ;

                final avatar = CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(isUser? 'assets/profile.png' : 'assets/robot.png'),
                ) ;


                final messageText = Text(msg.texte) ;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: isUser? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(!isUser) avatar ,
                      SizedBox(width: 5,),
                      Flexible(child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isUser?Colors.blue : Colors.grey[300] ,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: messageText,
                      )),
                      if(isUser) ...[
                        SizedBox(width: 5,),
                        avatar,

                      ]
                    ],
                  ),
                ) ;
              }
          )),
          Padding(padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Ecrire un message..",
                  suffixIcon: IconButton(onPressed: sendMessage, icon: Icon(Icons.send))
                ),
              ))
            ],
          ),)
        ],
      ),
    ) ;
  }
}
