import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuickerAgentPage extends StatefulWidget {
  const QuickerAgentPage({super.key});

  @override
  State<QuickerAgentPage> createState() => _QuickerAgentPageState();
}

class _QuickerAgentPageState extends State<QuickerAgentPage> {
  final Color primaryColor = const Color(0xffA020F0);
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final String geminiApiKey = "AIzaSyA_seiNo1zrK5QexI3Ja6cRG-GMhtEVOtU";

  bool isLoading = false;

  final List<Map<String, String>> messages = [
    {
      "sender": "bot",
      "text": "Hi 👋 I am Quicker Agent. Ask me anything.",
    },
  ];

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
      });
      isLoading = true;
    });

    messageController.clear();
    _scrollToBottom();

    final reply = await _getAIReply(text);

    if (!mounted) return;

    setState(() {
      messages.add({
        "sender": "bot",
        "text": reply,
      });
      isLoading = false;
    });

    _scrollToBottom();
  }

  Future<String> _getAIReply(String question) async {
    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$geminiApiKey",
      );

      final List<Map<String, dynamic>> contents = [];

      contents.add({
        "role": "user",
        "parts": [
          {
            "text":
                "You are Quicker Agent, a helpful AI assistant inside a Flutter app. "
                "Give accurate, clear, and useful answers. "
                "If the user asks coding questions, explain step by step and give corrected code. "
                "If the answer is uncertain, say that clearly instead of guessing."
          }
        ],
      });

      contents.add({
        "role": "model",
        "parts": [
          {
            "text": "Understood. I will give accurate, clear, and helpful answers."
          }
        ],
      });

      for (final msg in messages) {
        final msgText = msg["text"];
        if (msgText == null || msgText.trim().isEmpty) continue;

        contents.add({
          "role": msg["sender"] == "user" ? "user" : "model",
          "parts": [
            {"text": msgText}
          ],
        });
      }

      contents.add({
        "role": "user",
        "parts": [
          {"text": question}
        ],
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": contents,
          "generationConfig": {
            "temperature": 0.3,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          }
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final candidates = data["candidates"];

        if (candidates is List &&
            candidates.isNotEmpty &&
            candidates[0]["content"] != null &&
            candidates[0]["content"]["parts"] != null &&
            candidates[0]["content"]["parts"].isNotEmpty) {
          return candidates[0]["content"]["parts"][0]["text"]?.toString() ??
              "No response generated.";
        }

        return "No response generated.";
      } else {
        final errorMessage =
            data["error"]?["message"]?.toString() ?? "Unknown API error";

        return "Gemini API Error: $errorMessage";
      }
    } catch (e) {
      return "Network error. Please check your internet and try again.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _bubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xff1E293B),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Quicker Agent"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (isLoading && index == messages.length) {
                  return _bubble("Typing...", false);
                }

                final msg = messages[index];
                final isUser = msg["sender"] == "user";

                return _bubble(msg["text"] ?? "", isUser);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ask Quicker Agent...",
                      filled: true,
                      fillColor: const Color(0xffF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: isLoading ? Colors.grey : primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: isLoading ? null : _sendMessage,
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