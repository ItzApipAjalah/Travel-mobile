import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Category {
  final int id;
  final String name;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name_category'],
      description: json['description'],
    );
  }
}

class ChatMessage {
  String messageContent;
  String messageType;
  List<NodeItem>? nodes;
  String? question;

  ChatMessage({
    required this.messageContent,
    required this.messageType,
    this.nodes,
    this.question,
  });
}

class NodeItem {
  final int id;
  final String question;
  final String buttonText;
  final String? answer;

  NodeItem({
    required this.id,
    required this.question,
    required this.buttonText,
    this.answer,
  });

  factory NodeItem.fromJson(Map<String, dynamic> json) {
    return NodeItem(
      id: json['id'],
      question: json['question'],
      buttonText: json['button_text'],
      answer: json['answer'],
    );
  }
}

class ChatBot extends StatefulWidget {
  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  List<ChatMessage> messages = [];
  bool isLoading = true;
  String? token; // Add your token here
  List<Category> categories = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedPriority = 'low';
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    fetchInitialConversation();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            categories = (data['data'] as List)
                .map((category) => Category.fromJson(category))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> fetchInitialConversation() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/conversation/initial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nodes = (data['data']['nodes'] as List)
            .map((node) => NodeItem.fromJson(node))
            .toList();

        setState(() {
          messages = [
            ChatMessage(
              messageContent: data['data']['question'],
              messageType: "receiver",
              nodes: nodes,
            ),
          ];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching initial conversation: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchChildren(int parentId) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/conversation/children/$parentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nodes = (data['data']['nodes'] as List)
            .map((node) => NodeItem.fromJson(node))
            .toList();

        setState(() {
          messages.add(ChatMessage(
            messageContent: data['data']['question'],
            messageType: "receiver",
            nodes: nodes,
          ));
        });
      }
    } catch (e) {
      print('Error fetching children: $e');
    }
  }

  void handleNodeClick(NodeItem node) {
    setState(() {
      // Add user's selection as a message
      messages.add(ChatMessage(
        messageContent: node.buttonText,
        messageType: "sender",
      ));

      if (node.answer != null) {
        // If there's an answer, show it
        messages.add(ChatMessage(
          messageContent: node.answer!,
          messageType: "receiver",
        ));
      } else {
        // If no answer, fetch children
        fetchChildren(node.id);
      }
    });
  }

  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Add this helper method for better text matching
  bool isTextMatching(String text1, String text2) {
    final t1 = text1.toLowerCase().trim();
    final t2 = text2.toLowerCase().trim();

    // Split into words for more flexible matching
    final words1 = t1.split(' ');
    final words2 = t2.split(' ');

    // Check if any significant words match
    for (var word1 in words1) {
      if (word1.length < 3) continue; // Skip short words
      for (var word2 in words2) {
        if (word2.length < 3) continue;
        if (word1.contains(word2) || word2.contains(word1)) {
          return true;
        }
      }
    }

    return false;
  }

  // Add this method to handle casual greetings
  bool isCasualGreeting(String message) {
    final greetings = [
      'hi',
      'hello',
      'halo',
      'hay',
      'hei',
      'hey',
      'selamat pagi',
      'pagi',
      'selamat siang',
      'siang',
      'selamat sore',
      'sore',
      'selamat malam',
      'malam',
      'assalamualaikum',
      'assalamu\'alaikum',
      'permisi',
      'p',
      'hai',
      'hallo',
      'oi',
      'woi'
    ];

    return greetings.any((greeting) =>
        message.toLowerCase().trim().contains(greeting.toLowerCase()));
  }

  String getCasualResponse(String message) {
    final timeNow = DateTime.now().hour;
    final lowerMessage = message.toLowerCase().trim();

    if (lowerMessage.contains('assalamu') ||
        lowerMessage.contains('assalamu\'alaikum')) {
      return "Wa'alaikumsalam, ada yang bisa saya bantu?";
    }

    if (lowerMessage.contains('pagi') || (timeNow >= 5 && timeNow < 11)) {
      return "Selamat pagi! Ada yang bisa saya bantu hari ini?";
    }

    if (lowerMessage.contains('siang') || (timeNow >= 11 && timeNow < 15)) {
      return "Selamat siang! Ada yang bisa saya bantu?";
    }

    if (lowerMessage.contains('sore') || (timeNow >= 15 && timeNow < 18)) {
      return "Selamat sore! Ada yang bisa saya bantu?";
    }

    if (lowerMessage.contains('malam') || (timeNow >= 18 || timeNow < 5)) {
      return "Selamat malam! Ada yang bisa saya bantu?";
    }

    return "Halo! Ada yang bisa saya bantu hari ini?";
  }

  // Update the findMatchingResponse method
  Future<void> findMatchingResponse(String message) async {
    // First check if it's a casual greeting
    if (isCasualGreeting(message)) {
      setState(() {
        messages.add(ChatMessage(
          messageContent: getCasualResponse(message),
          messageType: "receiver",
        ));
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/conversation/initial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nodes = (data['data']['nodes'] as List)
            .map((node) => NodeItem.fromJson(node))
            .toList();

        // Find matching node using the new matching method
        NodeItem? matchingNode;
        for (var node in nodes) {
          if (isTextMatching(node.buttonText, message) ||
              isTextMatching(node.question, message)) {
            matchingNode = node;
            break;
          }
        }

        if (matchingNode != null) {
          handleNodeClick(matchingNode);
          return;
        }

        // If no match found in initial nodes, check all children nodes
        for (var node in nodes) {
          if (node.answer == null) {
            final childResponse = await http.get(
              Uri.parse(
                  'http://127.0.0.1:8000/api/conversation/children/${node.id}'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (childResponse.statusCode == 200) {
              final childData = json.decode(childResponse.body);
              final childNodes = (childData['data']['nodes'] as List)
                  .map((node) => NodeItem.fromJson(node))
                  .toList();

              // Find matching child node using the new matching method
              NodeItem? matchingChildNode;
              for (var childNode in childNodes) {
                if (isTextMatching(childNode.buttonText, message) ||
                    isTextMatching(childNode.question, message)) {
                  matchingChildNode = childNode;
                  break;
                }
              }

              if (matchingChildNode != null) {
                handleNodeClick(matchingChildNode);
                return;
              }
            }
          }
        }

        // If no match found, send default response
        setState(() {
          messages.add(ChatMessage(
            messageContent:
                "Maaf, saya tidak dapat menemukan jawaban yang sesuai. Silakan pilih dari opsi yang tersedia atau hubungi CS kami untuk bantuan lebih lanjut.",
            messageType: "receiver",
          ));
        });
      }
    } catch (e) {
      print('Error finding matching response: $e');
    }
  }

  // Update _sendMessage method
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final messageText = _controller.text;
      setState(() {
        messages.add(ChatMessage(
          messageContent: messageText,
          messageType: "sender",
        ));
        _controller.clear();
      });

      // Find and send matching response
      findMatchingResponse(messageText);
    }
  }

  // metod untuk simulasi in saat ngeklik opsion nya
  void _selectOption(String selectedOption) {
    setState(() {
      messages.add(
          ChatMessage(messageContent: selectedOption, messageType: "sender"));
      messages.add(ChatMessage(
        messageContent:
            // ini balesannya (cuma contoh)
            "Proses pengembalian uang tiket biasanya memerlukan waktu 5 hingga 14 hari kerja, tergantung pada metode pembayaran yang Anda gunakan.",
        messageType: "receiver",
      ));
    });
  }

  // umpan balik category
  void _onCategoryClick(String categoryName) {
    setState(() {
      messages.add(
          ChatMessage(messageContent: categoryName, messageType: "sender"));
    });
  }

  Widget _buildNodesList(List<NodeItem> nodes) {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes
            .map((node) => Column(
                  children: [
                    InkWell(
                      onTap: () => handleNodeClick(node),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                node.buttonText,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (nodes.last != node) Divider(),
                  ],
                ))
            .toList(),
      ),
    );
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Buat Tiket Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Prioritas',
                        border: OutlineInputBorder(),
                      ),
                      items: ['low', 'medium', 'high'].map((String priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedPriority = value ?? 'low';
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((Category category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3C729A),
                  ),
                  onPressed: () => _createTicket(context),
                  child: Text(
                    'Buat Tiket',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createTicket(BuildContext context) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/tickets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleController.text,
          'description': descriptionController.text,
          'priority': selectedPriority,
          'category_id': selectedCategoryId,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true) {
        // Clear form
        titleController.clear();
        descriptionController.clear();
        selectedPriority = 'low';
        selectedCategoryId = null;

        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tiket berhasil dibuat')),
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to create ticket');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 400,
        backgroundColor: Color(0xFF3C729A),
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/women/44.jpg"),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Text(
                "BOT EZ",
                style: TextStyle(
                  color: const Color.fromARGB(255, 238, 238, 238),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: messages.length,
                  padding: EdgeInsets.only(top: 10, bottom: 60),
                  itemBuilder: (context, index) {
                    if (messages[index].nodes != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMessageBubble(messages[index]),
                          _buildNodesList(messages[index].nodes!),
                        ],
                      );
                    }
                    return _buildMessageBubble(messages[index]);
                  },
                ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 70, left: 15),
                height: 30,
                width: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF3C729A), width: 1.0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: FloatingActionButton(
                  heroTag: "chatCsButton",
                  onPressed: _showCreateTicketDialog,
                  child: Text(
                    "Chat CS",
                    style: TextStyle(
                      color: Color(0xFF3C729A),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Color(0xFF3C729A),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Tulis pesan di sini...",
                        hintStyle: TextStyle(color: Colors.white),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 28,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget sama be
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
      child: Align(
        alignment: (message.messageType == "receiver"
            ? Alignment.topLeft
            : Alignment.topRight),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (message.messageType == "receiver"
                ? Colors.grey.shade200
                : Colors.blue[200]),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            message.messageContent,
            style: TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}
