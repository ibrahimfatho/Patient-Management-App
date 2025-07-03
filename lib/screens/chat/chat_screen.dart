import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../utils/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_notifier.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart' as app_user;

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String chatRoomId;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ChatNotifier _chatNotifier;
  late app_user.User _currentUser;
  late types.User _user;
  late ChatService _chatService;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _chatNotifier = Provider.of<ChatNotifier>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = authProvider.currentUser!;
    _chatService = ChatService();

    _user = types.User(
      id: _currentUser.id!,
      firstName: _currentUser.name.split(' ').first,
      lastName: _currentUser.name.split(' ').length > 1 ? _currentUser.name.split(' ').last : '',
      imageUrl: _currentUser.photoUrl,
    );

    _chatNotifier.listenToMessages(widget.chatRoomId);
    _chatNotifier.markMessagesAsRead();

    setState(() {
      _isLoading = false;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 237, 235, 235).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            title: Row(
              children: [
                Hero(
                  tag: 'avatar_${widget.otherUserId}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary,
                      child: widget.otherUserPhotoUrl != null && widget.otherUserPhotoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.network(
                                widget.otherUserPhotoUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                              ),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _showUserInfo,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 237, 235, 235).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer<ChatNotifier>(
                builder: (context, chatNotifier, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark 
                          ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
                          : [const Color(0xFFF8F9FA), Colors.white],
                      ),
                    ),
                    child: Chat(
                      messages: chatNotifier.messages,
                      onSendPressed: _handleSendPressed,
                      user: _user,
                      theme: _buildChatTheme(theme, isDark),
                      showUserAvatars: true,
                      showUserNames: false,
                      customBottomWidget: _buildCustomInputField(chatNotifier, theme, isDark),
                      typingIndicatorOptions: const TypingIndicatorOptions(
                        typingUsers: [],
                      ),
                      emptyState: _buildEmptyState(theme),
                      l10n: const ChatL10nAr(),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF1976D2),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
            ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
            : [const Color(0xFFF8F9FA), Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل المحادثة...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ابدأ المحادثة الآن',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اكتب رسالتك الأولى لبدء محادثة رائعة',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DefaultChatTheme _buildChatTheme(ThemeData theme, bool isDark) {
    return DefaultChatTheme(
      primaryColor: theme.colorScheme.primary,
      secondaryColor: isDark 
        ? const Color(0xFF2D2D2D) 
        : theme.colorScheme.primary.withOpacity(0.08),
      backgroundColor: Colors.transparent,
      inputBackgroundColor: isDark 
        ? const Color(0xFF1A1A1A) 
        : Colors.white,
      inputTextColor: theme.colorScheme.onSurface,
      inputBorderRadius: BorderRadius.circular(30),
      inputMargin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      inputPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      inputTextStyle: TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      sendButtonIcon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
      sendingIcon: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
      sentMessageBodyTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      receivedMessageBodyTextStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      messageBorderRadius: 20,
      messageInsetsHorizontal: 16,
      messageInsetsVertical: 12,
      sentMessageCaptionTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 12,
      ),
      receivedMessageCaptionTextStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: 12,
      ),
      dateDividerTextStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      emptyChatPlaceholderTextStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: 16,
      ),
      sentMessageDocumentIconColor: Colors.white,
      receivedMessageDocumentIconColor: theme.colorScheme.primary,
    );
  }

  void _handleSendPressed(types.PartialText message) {
    if (message.text.trim().isEmpty) return;
    
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
      status: types.Status.sent,
    );

    _chatNotifier.sendMessage(textMessage);
  }
  
  Widget _buildCustomInputField(ChatNotifier chatNotifier, ThemeData theme, bool isDark) {
    final TextEditingController textController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.grey.shade800 
                : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                Icons.attach_file_rounded,
                color: isDark 
                  ? Colors.white70 
                  : AppTheme.primaryColor.withOpacity(0.7),
                size: 22,
              ),
              onPressed: () {
                // Show attachment options
                _showAttachmentOptions(theme, isDark);
              },
            ),
          ),
          const SizedBox(width: 12),
          
          // Text input field
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: isDark 
                  ? Colors.grey.shade800.withOpacity(0.5) 
                  : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(27),
              ),
              child: TextField(
                controller: textController,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: InputBorder.none,
                ),
                textDirection: TextDirection.rtl,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _handleSendPressed(types.PartialText(text: text));
                    textController.clear();
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          GestureDetector(
            onTap: () {
              final text = textController.text;
              if (text.trim().isNotEmpty) {
                _handleSendPressed(types.PartialText(text: text));
                textController.clear();
              }
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAttachmentOptions(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'إرسال مرفق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image_rounded,
                  label: 'صورة',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement image attachment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم دعم إرسال الصور قريباً'))
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'كاميرا',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement camera attachment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم دعم الكاميرا قريباً'))
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'ملف',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement file attachment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم دعم إرسال الملفات قريباً'))
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [Colors.white, const Color(0xFFF8F9FA)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Hero(
                tag: 'user_info_avatar_${widget.otherUserId}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: widget.otherUserPhotoUrl != null && widget.otherUserPhotoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              widget.otherUserPhotoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildLargeAvatarFallback(),
                            ),
                          )
                        : _buildLargeAvatarFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.otherUserName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
             
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'حذف المحادثة',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'ستختفي من قائمة محادثاتك فقط',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLargeAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
  final BuildContext screenContext = context; // Capture ChatScreen's context

  showDialog(
    context: screenContext, // Use ChatScreen's context to show the confirmation dialog
    builder: (BuildContext alertDialogContext) { // This is the AlertDialog's context
      final theme = Theme.of(alertDialogContext);
      final isDark = theme.brightness == Brightness.dark;
      
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('حذف المحادثة'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه المحادثة؟ ستختفي من قائمة محادثاتك فقط، ولن تُحذف للطرف الآخر.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertDialogContext), // Pop AlertDialog using its own context
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                // 1. Pop the confirmation dialog
                Navigator.pop(alertDialogContext); 

                // 2. Show loading dialog using ChatScreen's context
                showDialog(
                  context: screenContext, 
                  barrierDismissible: false,
                  builder: (BuildContext loadingDialogContext) { 
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                try {
                  // 3. Perform deletion
                  final success = await _chatService.markChatAsDeletedForUser(
                    widget.chatRoomId,
                    _currentUser.id!,
                  );

                  if (!mounted) {
                    try { Navigator.of(screenContext, rootNavigator: true).pop(); } catch (_) {}
                    return;
                  }

                  // 4. Pop the loading dialog using ChatScreen's context
                  Navigator.pop(screenContext); 

                  if (success) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(
                        content: const Text('تم حذف المحادثة بنجاح'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    // 5. Pop the ChatScreen itself using ChatScreen's context
                    Navigator.pop(screenContext); 
                  } else {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(
                        content: const Text('فشل في حذف المحادثة'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) {
                     try { Navigator.of(screenContext, rootNavigator: true).pop(); } catch (_) {}
                    return;
                  }
                  // 4b. Pop the loading dialog in case of error
                  Navigator.pop(screenContext); 
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(
                      content: const Text('حدث خطأ أثناء حذف المحادثة'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    },
  );
}
}

// Arabic localization for chat UI
class ChatL10nAr implements ChatL10n {
  const ChatL10nAr();
  
  @override
  String get attachmentButtonAccessibilityLabel => 'إرسال مرفق';
  
  @override
  String get emptyChatPlaceholder => 'لا توجد رسائل بعد';
  
  @override
  String get fileButtonAccessibilityLabel => 'ملف';
  
  @override
  String get inputPlaceholder => 'اكتب رسالتك...';
  
  @override
  String get sendButtonAccessibilityLabel => 'إرسال';
  
  @override
  String get unreadMessagesLabel => 'الرسائل غير المقروءة';

  @override
  String get and => 'و';

  @override
  String get isTyping => 'يكتب...';

  @override
  String get others => 'آخرون';
  
  @override
  String? get customDateHeaderText => null;
  
  @override
  TextStyle? get emptyChatPlaceholderTextStyle => null;
  
  @override
  String? get fileButtonText => null;
  
  @override
  TextStyle? get inputPlaceholderTextStyle => null;
  
  @override
  TextStyle? get inputTextStyle => null;
  
  String? get sendingIndicatorText => null;
  String? get statusErrorText => null;
  String? get statusSendingText => null;
  String? get statusSentText => null;
  TextStyle? get userNameTextStyle => null;
  String? get userTypingText => null;
  
  @override
  String get today => 'اليوم';
  
  @override
  String get yesterday => 'أمس';
  
  @override
  String get messageSending => 'جاري الإرسال';
  
  @override
  String get messageDelivered => 'تم التسليم';
  
  @override
  String get messageRead => 'تم القراءة';
  
  @override
  String get messageError => 'خطأ';
  
  @override
  String get sendButtonText => 'إرسال';
}