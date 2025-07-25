import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:nirva_app/message.dart';
import 'package:nirva_app/nirva_api.dart';
import 'package:nirva_app/api_models.dart';
import 'package:nirva_app/providers/chat_history_provider.dart';

class AssistantChatPage extends StatefulWidget {
  final TextEditingController textController;

  const AssistantChatPage({super.key, required this.textController});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  String _getContent(ChatMessage message) {
    if (message.role == MessageRole.human) {
      return 'You: ${message.content}';
    } else if (message.role == MessageRole.ai) {
      return 'Nirva: ${message.content}';
    }
    return 'Illegal: ${message.content}';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final message = widget.textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final response = await NirvaAPI.chat(message, context);
      if (response != null) {
        //AppRuntimeContext().chat.addUserMessage(message);
        //AppRuntimeContext().chat.addAIMessage('AI 回复: ${response.message}');
      } else {
        //AppRuntimeContext().chat.addAIMessage('错误: 无法获取回复1');
      }
    } catch (e) {
      //AppRuntimeContext().chat.addAIMessage('错误: 无法获取回复2');
    }

    widget.textController.clear();
    _scrollToBottom();

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nirva'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 返回上一页
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatHistoryProvider>(
              builder: (context, chatHistoryProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatHistoryProvider.chatHistory.length,
                  itemBuilder: (context, index) {
                    final message = chatHistoryProvider.chatHistory[index];
                    final isUser = message.role == MessageRole.human;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Align(
                        alignment:
                            isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _getContent(message),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.textController,
                      decoration: InputDecoration(
                        hintText: '输入内容...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isSending ? Colors.grey : Colors.blue,
                    ),
                    onPressed: _isSending ? null : _handleSendMessage,
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
