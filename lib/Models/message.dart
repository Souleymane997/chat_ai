class Message{
  late String texte ;
  late bool isUserMessage ;

  Message({this.texte = '' , this.isUserMessage  = false}) ;

  bool get isBotMessage => !isUserMessage ;
}