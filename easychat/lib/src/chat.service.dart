import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:easychat/easychat.dart';
import 'package:easyuser/easyuser.dart';
import 'package:firebase_database/firebase_database.dart' as db;
import 'package:flutter/material.dart';

/// Chat Service
///
/// This is the chat service class that will be used to manage the chat rooms.
class ChatService {
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();

  ChatService._();

  /// Whether the service is initialized or not.
  ///
  /// Note that, chat service can be initialized multiple times.
  bool initialized = false;

  /// Callback function
  Future<void> Function({BuildContext context, bool openGroupChatsOnly})?
      $showChatRoomListScreen;
  Future<fs.DocumentReference> Function({BuildContext context})?
      $showChatRoomEditScreen;

  init({
    Future<void> Function({BuildContext context, bool openGroupChatsOnly})?
        $showChatRoomListScreen,
    Future<fs.DocumentReference> Function({BuildContext context})?
        $showChatRoomEditScreen,
  }) {
    UserService.instance.init();

    initialized = true;

    this.$showChatRoomListScreen =
        $showChatRoomListScreen ?? this.$showChatRoomListScreen;
    this.$showChatRoomEditScreen =
        $showChatRoomEditScreen ?? this.$showChatRoomEditScreen;
  }

  /// Firebase CollectionReference for Chat Room docs
  fs.CollectionReference get roomCol =>
      fs.FirebaseFirestore.instance.collection('chat-rooms');

  /// Firebase chat collection query by new message counter for the current user.
  fs.Query get myRoomQuery => roomCol.orderBy(
      '${ChatRoom.field.users}.$myUid.${ChatRoomUser.field.newMessageCounter}');

  /// CollectionReference for Chat Room Meta docs
  fs.CollectionReference roomMetaCol(String roomId) =>
      fs.FirebaseFirestore.instance
          .collection('chat-rooms')
          .doc(roomId)
          .collection('chat-room-meta');

  /// DocumentReference for chat room private settings.
  fs.DocumentReference roomPrivateDoc(String roomId) =>
      roomMetaCol(roomId).doc('private');

  db.DatabaseReference messageRef(String roomId) =>
      db.FirebaseDatabase.instance.ref().child("chat-messages").child(roomId);

  /// Show the chat room list screen.
  Future showChatRoomListScreen(BuildContext context,
      {ChatRoomListOption queryOption = ChatRoomListOption.allMine}) {
    return $showChatRoomListScreen?.call() ??
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => ChatRoomListScreen(
            queryOption: queryOption,
          ),
        );
  }

  Future showOpenChatRoomListScreen(BuildContext context) {
    return $showChatRoomListScreen?.call(
          context: context,
          openGroupChatsOnly: true,
        ) ??
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => const ChatRoomListScreen(
            queryOption: ChatRoomListOption.open,
          ),
        );
  }

  /// Show the chat room edit screen. It's for borth create and update.
  Future<fs.DocumentReference?> showChatRoomEditScreen(BuildContext context,
      {ChatRoom? room}) {
    return $showChatRoomEditScreen?.call(context: context) ??
        showGeneralDialog<fs.DocumentReference>(
          context: context,
          pageBuilder: (_, __, ___) => ChatRoomEditScreen(room: room),
        );
  }

  showChatRoomScreen(BuildContext context, {User? user, ChatRoom? room}) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "Chat Room",
      pageBuilder: (_, __, ___) => ChatRoomScreen(
        user: user,
        room: room,
      ),
    );
  }

  showRejectListScreen(
    BuildContext context,
  ) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => const RejectedChatRoomInviteListScreen(),
    );
  }

  Future sendMessage(
    ChatRoom room, {
    String? photoUrl,
    String? text,
    ChatMessage? replyTo,
  }) async {
    if ((text ?? "").isEmpty && (photoUrl == null || photoUrl.isEmpty)) return;
    await _shouldBeOrBecomeMember(room);
    List<Future> futures = [
      ChatMessage.create(
        roomId: room.id,
        text: text,
        url: photoUrl,
        replyTo: replyTo,
      ),
      room.updateNewMessagesMeta(
        lastMessageText: text,
        lastMessageUrl: photoUrl,
      ),
    ];
    await Future.wait(futures);
  }

  _shouldBeOrBecomeMember(
    ChatRoom room,
  ) async {
    if (room.joined) return;
    if (room.open) return await room.join();
    if (room.invitedUsers.contains(my.uid) ||
        room.rejectedUsers.contains(my.uid)) {
      // The user may mistakenly reject the chat room
      // The user may accept it by replying.
      return await room.acceptInvitation();
    }

    throw "chat-room/uninvited-chat You can only send a message to a chat room where you are a member or an invited user.";
  }
}
