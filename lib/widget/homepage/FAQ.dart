import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FAQWidget extends StatefulWidget {
  const FAQWidget({super.key});

  @override
  State<FAQWidget> createState() => _FAQWidgetState();
}

class _FAQWidgetState extends State<FAQWidget> {
  List<Map<String, dynamic>> faqItems = [];
  bool isLoading = true;
  String? token;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFAQ();
  }

  Future<void> _loadTokenAndFAQ() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      await fetchInitialConversation();
    } catch (e) {
      print('Error loading FAQ: $e');
      setState(() {
        isLoading = false;
      });
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
        setState(() {
          faqItems = (data['data']['nodes'] as List).map((node) {
            return {
              'id': node['id'],
              'question': node['question'],
              'button_text': node['button_text'],
              'answer': node['answer'],
              'category': _getCategoryFromQuestion(node['question']),
              'isExpanded': false,
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching FAQ: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getCategoryFromQuestion(String question) {
    if (question.toLowerCase().contains('tiket')) return '[Tiket]';
    if (question.toLowerCase().contains('refund')) return '[Refund]';
    if (question.toLowerCase().contains('transaksi')) return '[Transaksi]';
    if (question.toLowerCase().contains('transportasi')) return '[Transportasi]';
    return '[Umum]';
  }

  void _filterByCategory(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    var filteredItems = selectedCategory == null
        ? faqItems
        : faqItems.where((item) => item['category'] == selectedCategory).toList();

    return Container(
      height: 350,
      color: Colors.white,
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('Semua'),
                        selected: selectedCategory == null,
                        onSelected: (_) => _filterByCategory(null),
                        backgroundColor: Colors.grey[200],
                        selectedColor: Color(0xFF3C729A),
                        labelStyle: TextStyle(
                          color: selectedCategory == null ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      ...{
                        '[Tiket]',
                        '[Refund]',
                        '[Transaksi]',
                        '[Transportasi]',
                        '[Umum]'
                      }.map((category) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (_) => _filterByCategory(category),
                              backgroundColor: Colors.grey[200],
                              selectedColor: Color(0xFF3C729A),
                              labelStyle: TextStyle(
                                color: selectedCategory == category
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ExpansionTile(
                        title: Row(
                          children: [
                            Text(
                              item['category'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C729A),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['button_text'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          if (item['answer'] != null)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                item['answer'],
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          else
                            FutureBuilder(
                              future: _fetchChildren(item['id']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Error loading details'),
                                  );
                                }
                                final children = snapshot.data as List<Map<String, dynamic>>;
                                return Column(
                                  children: children.map((child) {
                                    return ListTile(
                                      title: Text(
                                        child['button_text'],
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      subtitle: child['answer'] != null
                                          ? Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Text(
                                                child['answer'],
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            )
                                          : null,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchChildren(int parentId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/conversation/children/$parentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data']['nodes'] as List).map((node) {
          return {
            'id': node['id'],
            'question': node['question'],
            'button_text': node['button_text'],
            'answer': node['answer'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching children: $e');
      return [];
    }
  }
}
