import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpertMessagesScreen extends StatefulWidget {
  const ExpertMessagesScreen({super.key});

  @override
  State<ExpertMessagesScreen> createState() => _ExpertMessagesScreenState();
}

class _ExpertMessagesScreenState extends State<ExpertMessagesScreen> {
  static const Color primaryColor = Color.fromARGB(255, 241, 179, 0);

  final TextEditingController searchController = TextEditingController();
  String filter = "All";

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _chatId(String a, String b) {
    final ids = [a, b];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final expert = currentUser;

    if (expert == null) {
      return const Scaffold(body: Center(child: Text("Expert not logged in")));
    }

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: width * 0.055,
            right: width * 0.055,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBack(context),
              const SizedBox(height: 18),
              _titleRow(),
              const SizedBox(height: 20),
              _searchBar(),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 12),
              Expanded(child: _peopleWithChats(expert.uid)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBack(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, "/expertHome");
      },
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 26, color: Color(0xff1E293B)),
      ),
    );
  }

  Widget _titleRow() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Messages",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 3),
        Text(
          "Chat with users and experts",
          style: TextStyle(color: Color(0xff64748B)),
        ),
      ],
    );
    }

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xffF1F2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Color(0xff94A3B8)),
          hintText: "Search users or experts...",
          hintStyle: TextStyle(color: Color(0xff94A3B8)),
        ),
      ),
    );
  }

  Widget _filters() {
    return Row(
      children: [
        _filterChip("All"),
        _filterChip("User"),
        _filterChip("Expert"),
      ],
    );
  }

  Widget _filterChip(String title) {
    final selected = filter == title;

    return GestureDetector(
      onTap: () => setState(() => filter = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffFFF4CC) : const Color(0xffF1F2F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? primaryColor : const Color(0xff475569),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _peopleWithChats(String expertId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllUsersAndExperts(expertId),
      builder: (context, peopleSnapshot) {
        if (peopleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (peopleSnapshot.hasError) {
          return Center(child: Text("Error: ${peopleSnapshot.error}"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .where("members", arrayContains: expertId)
              .snapshots(),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Map<String, dynamic>> people = peopleSnapshot.data ?? [];
            final chatDocs = chatSnapshot.data?.docs ?? [];

            final Map<String, Map<String, dynamic>> chatMap = {};

            for (var chat in chatDocs) {
              final chatData = chat.data() as Map<String, dynamic>? ?? {};
              chatMap[chat.id] = chatData;
            }

            for (var person in people) {
              final chatId = _chatId(expertId, person["id"]);
              final chatData = chatMap[chatId];

              person["chatId"] = chatId;
              person["lastMessage"] = chatData?["lastMessage"] ?? "";
              person["lastMessageTime"] = chatData?["lastMessageTime"];
              person["lastSenderId"] = chatData?["lastSenderId"] ?? "";

              final unreadCounts =
                  chatData?["unreadCounts"] as Map<String, dynamic>? ?? {};
              person["unreadCount"] = unreadCounts[expertId] ?? 0;
            }

            if (filter != "All") {
              people = people.where((person) {
                return person["role"].toString().toLowerCase() ==
                    filter.toLowerCase();
              }).toList();
            }

            final search = searchController.text.trim().toLowerCase();

            if (search.isNotEmpty) {
              people = people.where((person) {
                final name = person["name"].toString().toLowerCase();
                final email = person["email"].toString().toLowerCase();
                final role = person["role"].toString().toLowerCase();

                return name.contains(search) ||
                    email.contains(search) ||
                    role.contains(search);
              }).toList();
            }

            people.sort((a, b) {
              final aTime = a["lastMessageTime"];
              final bTime = b["lastMessageTime"];

              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }

              if (aTime is Timestamp) return -1;
              if (bTime is Timestamp) return 1;

              return a["name"].toString().compareTo(b["name"].toString());
            });

            if (people.isEmpty) {
              return const Center(child: Text("No users or experts found"));
            }

            return ListView.builder(
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];

                final receiverId = person["id"];
                final name = person["name"];
                final email = person["email"];
                final role = person["role"];
                final unreadCount = person["unreadCount"] ?? 0;
                final lastMessage = person["lastMessage"] ?? "";
                final isExpert = role.toString().toLowerCase() == "expert";

                return GestureDetector(
                  onTap: () async {
                    final chatId = await _createOrGetChatRoom(
                      currentUserId: expertId,
                      receiverId: receiverId,
                      receiverName: name,
                      receiverRole: role,
                    );

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpertChatDetailScreen(
                          chatId: chatId,
                          receiverId: receiverId,
                          receiverName: name,
                          receiverRole: role,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: unreadCount > 0
                          ? const Color(0xffFFF8E1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: isExpert
                              ? const Color(0xffDCFCE7)
                              : const Color(0xffFFF4CC),
                          child: Text(
                            _getInitials(name),
                            style: TextStyle(
                              color: isExpert
                                  ? const Color(0xff16A34A)
                                  : primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastMessage.toString().isEmpty
                                    ? email
                                    : lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unreadCount > 0
                                      ? Colors.black
                                      : const Color(0xff64748B),
                                  fontSize: 13,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isExpert
                                  ? const Color(0xffDCFCE7)
                                  : const Color(0xffFFF4CC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isExpert ? "Expert" : "User",
                              style: TextStyle(
                                color: isExpert
                                    ? const Color(0xff16A34A)
                                    : primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xff94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAllUsersAndExperts(
    String currentUserId,
  ) async {
    final List<Map<String, dynamic>> people = [];

    final usersSnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    for (var doc in usersSnapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();

      people.add({
        "id": doc.id,
        "name": data["name"]?.toString() ?? "Unknown User",
        "email": data["email"]?.toString() ?? "",
        "role": "User",
      });
    }

    final expertsSnapshot =
        await FirebaseFirestore.instance.collection("experts").get();

    for (var doc in expertsSnapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();
      final alreadyExists = people.any((person) => person["id"] == doc.id);

      if (!alreadyExists) {
        people.add({
          "id": doc.id,
          "name": data["name"]?.toString() ??
              data["expertName"]?.toString() ??
              "Unknown Expert",
          "email": data["email"]?.toString() ?? "",
          "role": "Expert",
        });
      }
    }

    return people;
  }

  Future<String> _createOrGetChatRoom({
    required String currentUserId,
    required String receiverId,
    required String receiverName,
    required String receiverRole,
  }) async {
    final ids = [currentUserId, receiverId];
    ids.sort();
    final chatId = "${ids[0]}_${ids[1]}";

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        "chatId": chatId,
        "members": ids,
        "createdBy": currentUserId,
        "receiverId": receiverId,
        "receiverName": receiverName,
        "receiverRole": receiverRole,
        "lastMessage": "",
        "lastSenderId": "",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCounts": {
          currentUserId: 0,
          receiverId: 0,
        },
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";

    final parts = name.trim().split(" ");

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }
}

class ExpertChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String receiverRole;

  const ExpertChatDetailScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
  });

  @override
  State<ExpertChatDetailScreen> createState() => _ExpertChatDetailScreenState();
}

class _ExpertChatDetailScreenState extends State<ExpertChatDetailScreen> {
  static const Color primaryColor = Color.fromARGB(255, 241, 179, 0);

  final TextEditingController messageController = TextEditingController();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> markMessagesAsRead() async {
    final expert = currentUser;
    if (expert == null) return;

    await FirebaseFirestore.instance.collection("chats").doc(widget.chatId).set({
      "unreadCounts": {expert.uid: 0}
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage() async {
    final expert = currentUser;
    final message = messageController.text.trim();

    if (expert == null || message.isEmpty) return;

    messageController.clear();

    final messageRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .doc();

    await messageRef.set({
      "messageId": messageRef.id,
      "senderId": expert.uid,
      "receiverId": widget.receiverId,
      "message": message,
      "type": "text",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance.collection("chats").doc(widget.chatId).set({
      "lastMessage": message,
      "lastSenderId": expert.uid,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "unreadCounts": {
        widget.receiverId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));
  }

  Future<void> pickAndSendFile() async {
    final expert = currentUser;
    if (expert == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to read selected file")),
        );
        return;
      }

      final fileName = file.name;
      final extension = file.extension ?? "";
      final storagePath =
          "chat_files/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_$fileName";

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      await storageRef.putData(file.bytes!);

      final fileUrl = await storageRef.getDownloadURL();

      final messageRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .doc();

      await messageRef.set({
        "messageId": messageRef.id,
        "senderId": expert.uid,
        "receiverId": widget.receiverId,
        "message": fileName,
        "fileName": fileName,
        "fileSize": file.size,
        "fileExtension": extension,
        "fileUrl": fileUrl,
        "storagePath": storagePath,
        "type": "file",
        "createdAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .set({
        "lastMessage": "📎 $fileName",
        "lastSenderId": expert.uid,
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCounts": {
          widget.receiverId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File send failed: $e")),
      );
    }
  }

  Future<void> openFile(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open file")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expert = currentUser;

    if (expert == null) {
      return const Scaffold(body: Center(child: Text("Expert not logged in")));
    }

    final isExpert = widget.receiverRole.toLowerCase() == "expert";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _chatHeader(context, isExpert),
            Expanded(child: _messagesList(expert.uid)),
            _messageInput(),
          ],
        ),
      ),
    );
  }

  Widget _chatHeader(BuildContext context, bool isExpert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isExpert ? const Color(0xffDCFCE7) : const Color(0xffFFF4CC),
            child: Text(
              _getInitials(widget.receiverName),
              style: TextStyle(
                color: isExpert ? const Color(0xff16A34A) : primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.receiverRole,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagesList(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Unable to load messages"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aTime = aData["createdAt"];
          final bTime = bData["createdAt"];

          if (aTime is Timestamp && bTime is Timestamp) {
            return aTime.compareTo(bTime);
          }

          return 0;
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Start your conversation",
              style: TextStyle(color: Color(0xff64748B)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>? ?? {};
            final isMe = data["senderId"] == currentUserId;
            final isFile = data["type"] == "file";
            final currentDate = _dateFromTimestamp(data["createdAt"]);

            bool showDateHeader = index == 0;

            if (index > 0) {
              final previousData =
                  docs[index - 1].data() as Map<String, dynamic>? ?? {};
              final previousDate =
                  _dateFromTimestamp(previousData["createdAt"]);
              showDateHeader = !_isSameDay(currentDate, previousDate);
            }

            return Column(
              children: [
                if (showDateHeader) _dateHeader(currentDate),
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: const Color(0xFFE0E4EA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFile)
                          _fileBubble(data, isMe)
                        else
                          Text(
                            data["message"]?.toString() ?? "",
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : const Color(0xFF2D3648),
                              fontSize: 15.5,
                              height: 1.35,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _messageTime(data["createdAt"]),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.78)
                                : const Color(0xff94A3B8),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _fileBubble(Map<String, dynamic> data, bool isMe) {
    final fileName = data["fileName"]?.toString() ?? "File";
    final fileUrl = data["fileUrl"]?.toString() ?? "";
    final extension = data["fileExtension"]?.toString().toLowerCase() ?? "";

    return GestureDetector(
      onTap: fileUrl.isEmpty ? null : () => openFile(fileUrl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _fileIcon(extension),
            size: 22,
            color: isMe ? Colors.white : primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF2D3648),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String extension) {
    switch (extension) {
      case "jpg":
      case "jpeg":
      case "png":
      case "gif":
      case "webp":
        return Icons.image;
      case "pdf":
        return Icons.picture_as_pdf;
      case "doc":
      case "docx":
        return Icons.description;
      case "ppt":
      case "pptx":
        return Icons.slideshow;
      case "xls":
      case "xlsx":
        return Icons.table_chart;
      case "zip":
      case "rar":
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _dateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _dayLabel(date),
        style: const TextStyle(
          color: Color(0xff475569),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  DateTime _dateFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    final diff = msgDay.difference(today).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Tomorrow";
    if (diff == -1) return "Yesterday";

    if (diff < 0 && diff >= -6) {
      return _weekdayName(date.weekday);
    }

    return "${_monthName(date.month)} ${date.day}";
  }

  String _messageTime(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      final date = (timestamp as Timestamp).toDate();
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, "0");
      final period = hour >= 12 ? "PM" : "AM";
      final normalHour = hour % 12 == 0 ? 12 : hour % 12;

      return "$normalHour:$minute $period";
    } catch (_) {
      return "";
    }
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      default:
        return "Sunday";
    }
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      default:
        return "Dec";
    }
  }

  Widget _messageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: pickAndSendFile,
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 15.5),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: const Color(0xffF1F2F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";

    final parts = name.trim().split(" ");

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }
}