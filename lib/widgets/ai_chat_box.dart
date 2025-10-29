import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiChatBox extends StatefulWidget {
  const AiChatBox({super.key});

  @override
  State<AiChatBox> createState() => _AiChatBoxState();
}

class _AiChatBoxState extends State<AiChatBox> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ========= Hàm gửi tin nhắn =========
  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _controller.clear();
      _isLoading = true;
    });

    final answer = await _smartAnswer(question);

    setState(() {
      _messages.add({'role': 'bot', 'text': answer});
      _isLoading = false;
    });
  }

  // ========= Hàm chính “AI thông minh” =========
  Future<String> _smartAnswer(String question) async {
    try {
      // 1️⃣ Dịch câu hỏi sang tiếng Anh bằng Google Translate API free
      final engText = await _translate(question, to: 'en');

      // 2️⃣ Tìm Wikipedia
      final wikiResult = await _fetchWikiSummary(engText);

      // 3️⃣ Nếu không có dữ liệu, gợi ý lại người dùng
      if (wikiResult == null) {
        return '🤔 Mình không tìm thấy thông tin này trên Wikipedia. '
            'Bạn thử hỏi lại ngắn gọn hơn (ví dụ: “Flutter”, “Vietnam”, “Elon Musk”) nhé.';
      }

      // 4️⃣ Dịch kết quả về tiếng Việt
      final viAnswer = await _translate(wikiResult, to: 'vi');
      return '📚 ${viAnswer[0].toUpperCase()}${viAnswer.substring(1)}';
    } catch (e) {
      return '⚠️ Lỗi khi xử lý câu hỏi: $e';
    }
  }

  // ========= Dịch văn bản bằng Google Translate free API =========
  Future<String> _translate(String text, {required String to}) async {
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body[0][0][0];
    } else {
      return text; // fallback nếu lỗi
    }
  }

  // ========= Lấy tóm tắt từ Wikipedia =========
  Future<String?> _fetchWikiSummary(String query) async {
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['extract'];
    }
    return null;
  }

  // ========= UI giao diện =========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với AI (Wikimedia Bot)'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.deepPurple
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon:
                    const Icon(Icons.send_rounded, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
