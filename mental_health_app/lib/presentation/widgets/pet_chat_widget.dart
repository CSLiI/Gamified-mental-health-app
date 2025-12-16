import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/providers/pet_provider.dart';
import '../../core/constants/app_colors.dart';
import 'dart:math';

class PetChatWidget extends StatefulWidget {
  final bool isEmbedded;
  
  const PetChatWidget({
    Key? key, 
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<PetChatWidget> createState() => _PetChatWidgetState();
}

class _PetChatWidgetState extends State<PetChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  final List<String> _petResponses = [
    "I'm here for you! 🐾",
    "You're doing great! keep it up!",
    "Want to play properly later?",
    "I believe in you!",
    "Don't forget to drink water!",
    "You are strong!",
    "I'm happy to be your friend.",
    "*Happy sounds*",
    "*Wags tail enthusiastically*",
    "Tell me more!",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // ... REST OF METHOD unchanged ...
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate pet thinking delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Call interact to gain affection/xp
    final petProvider = context.read<PetProvider>();
    petProvider.interact(); 

    setState(() {
      _isTyping = false;
      final petName = petProvider.activePet?['name'] ?? 'Pet';
      final response = _petResponses[Random().nextInt(_petResponses.length)];
      _messages.add({'sender': 'pet', 'text': response});
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final activePet = petProvider.activePet;

    if (activePet == null) {
      return const SizedBox.shrink(); // Don't show if no pet
    }

    return Container(
      margin: widget.isEmbedded ? EdgeInsets.only(top: 16.h) : EdgeInsets.all(16.w),
      padding: widget.isEmbedded ? EdgeInsets.zero : EdgeInsets.all(16.w),
      decoration: widget.isEmbedded 
          ? null 
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  activePet['emoji'] ?? '🐾',
                  style: TextStyle(fontSize: 20.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Chat with ${activePet['name']}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Messages Area
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: EdgeInsets.all(12.w),
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation with your companion!',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['sender'] == 'user';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 0.75.sw),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                topRight: Radius.circular(16.r),
                                bottomLeft: isUser
                                    ? Radius.circular(16.r)
                                    : Radius.zero,
                                bottomRight: isUser
                                    ? Radius.zero
                                    : Radius.circular(16.r),
                              ),
                              boxShadow: isUser
                                  ? [] // No shadow for user message (flat design)
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isTyping)
             Padding(
               padding: EdgeInsets.only(top: 8.h, left: 16.w),
               child: Text(
                '${activePet['name']} is typing...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
               ),
             ),
          SizedBox(height: 12.h),

          // Input Area
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.all(10.w),
                  constraints: const BoxConstraints(),
                  iconSize: 20.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
