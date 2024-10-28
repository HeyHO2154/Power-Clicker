import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Login.dart';

class Vip extends StatefulWidget {
  @override
  _VipState createState() => _VipState();
}

class _VipState extends State<Vip> {
  int totalPoints = 0;
  String rewardStatus = "";
  List<Map<String, String>> messages = []; // 채팅 메시지 목록
  TextEditingController messageController = TextEditingController(); // 입력 메시지 컨트롤러
  ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
    _fetchMessages();

    refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchMessages();
    });
  }

  Future<void> _fetchUserPoints() async {
    final response = await http.get(
      Uri.parse('${Login.url}/api/getPoints?user_id=${Login.userId}'),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
      setState(() {
        totalPoints = data['points'];
      });
    } else {
      print('Failed to load points');
    }
  }

  Future<void> _fetchMessages() async {
    final response = await http.get(
      Uri.parse("${Login.url}/api/getMessages"),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
        setState(() {
          messages = data
              .map((item) => {
            "userId": item["userId"].toString(),
            "message": item["message"].toString(),
          })
              .take(10)
              .toList();
        });
        _scrollToBottom(); // 메시지 갱신 후 자동 스크롤
      } catch (e) {
        print("Error parsing messages: $e");
      }
    } else {
      print("Failed to load VIP messages");
    }
  }

  Future<void> _sendMessage() async {
    if (messageController.text.isNotEmpty) {
      final response = await http.post(
        Uri.parse("${Login.url}/api/sendMessage"),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "user_id": Login.userId,
          "message": messageController.text,
        }),
      );

      if (response.statusCode == 200) {
        messageController.clear();
        _fetchMessages();
      } else {
        print("Failed to send message");
      }
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // VIP 상단 박스
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade700, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${totalPoints}P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "VIP들끼리 메시지를 주고 받아보세요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "( 여기까지 온 당신, 정말 대단합니다!! )",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // 채팅 메시지 표시 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 스크롤 컨트롤러 추가
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isMyMessage =
                    messages[index]["userId"] == Login.userId; // 본인 메시지 확인
                return ListTile(
                  title: Align(
                    alignment:
                    isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMyMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          messages[index]["userId"]!,
                          style: TextStyle(
                              color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMyMessage
                                ? Colors.yellow.shade600
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            messages[index]["message"]!,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 메시지 입력 및 전송 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "메시지를 입력하세요...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.send, color: Colors.white),
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