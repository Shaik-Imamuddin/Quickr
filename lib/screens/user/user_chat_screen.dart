import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final Color primaryColor = const Color(0xffA020F0);
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
    final user = currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
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
              _topRow(context),
              const SizedBox(height: 18),
              _titleRow(),
              const SizedBox(height: 22),
              _searchBar(),
              const SizedBox(height: 20),
              _filters(),
              const SizedBox(height: 12),
              Expanded(child: _peopleWithChats(user.uid)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 28),
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Chat",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              SizedBox(height: 3),
              Text("Connect with users and experts",
                  style: TextStyle(color: Color(0xff64748B))),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: primaryColor,
          child: const Icon(Icons.chat, color: Colors.white),
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
          color: selected ? const Color(0xffF3E8FF) : const Color(0xffF1F2F6),
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

  Widget _peopleWithChats(String currentUserId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllUsersAndExperts(currentUserId),
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
              .where("members", arrayContains: currentUserId)
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
              final chatId = _chatId(currentUserId, person["id"]);
              final chatData = chatMap[chatId];

              person["chatId"] = chatId;
              person["lastMessage"] = chatData?["lastMessage"] ?? "";
              person["lastMessageTime"] = chatData?["lastMessageTime"];
              person["lastSenderId"] = chatData?["lastSenderId"] ?? "";

              final unreadCounts =
                  chatData?["unreadCounts"] as Map<String, dynamic>? ?? {};
              person["unreadCount"] = unreadCounts[currentUserId] ?? 0;
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
                final chatId = person["chatId"];
                final lastMessage = person["lastMessage"] ?? "";
                final unreadCount = person["unreadCount"] ?? 0;
                final isExpert = role.toString().toLowerCase() == "expert";

                return GestureDetector(
                  onTap: () async {
                    final finalChatId = await _createOrGetChatRoom(
                      currentUserId: currentUserId,
                      receiverId: receiverId,
                      receiverName: name,
                      receiverRole: role,
                    );

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          chatId: finalChatId,
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
                          ? const Color(0xffFAF5FF)
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
                              : const Color(0xffF3E8FF),
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
                        const SizedBox(width: 8),
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
                                  : const Color(0xffF3E8FF),
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
        "role": data["role"]?.toString().isNotEmpty == true
            ? data["role"].toString()
            : "User",
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

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String receiverRole;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final Color primaryColor = const Color(0xffA020F0);
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
    final user = currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .set({
      "unreadCounts": {
        user.uid: 0,
      }
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage() async {
    final user = currentUser;
    final message = messageController.text.trim();

    if (user == null || message.isEmpty) return;

    messageController.clear();

    final messageRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .doc();

    await messageRef.set({
      "messageId": messageRef.id,
      "senderId": user.uid,
      "receiverId": widget.receiverId,
      "message": message,
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .set({
      "lastMessage": message,
      "lastSenderId": user.uid,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "unreadCounts": {
        widget.receiverId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final isExpert = widget.receiverRole.toLowerCase() == "expert";

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isExpert ? const Color(0xffDCFCE7) : const Color(0xffF3E8FF),
              child: Text(
                _getInitials(widget.receiverName),
                style: TextStyle(
                  color: isExpert ? const Color(0xff16A34A) : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.receiverRole,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};

                    final isMe = data["senderId"] == user.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          data["message"]?.toString() ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffE5E7EB))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
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
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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