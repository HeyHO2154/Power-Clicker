import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class CardPage extends StatefulWidget {
  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  List<int> cards = [];
  String resultMessage = "";
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Card Game"),
      ),
      body: cards.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Your Cards: ${cards.join(', ')}"),
          if (resultMessage.isNotEmpty) Text(resultMessage),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
