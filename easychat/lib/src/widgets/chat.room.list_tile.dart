import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_helpers/easy_helpers.dart';
import 'package:easy_locale/easy_locale.dart';
import 'package:easy_realtime_database/easy_realtime_database.dart';
import 'package:easychat/easychat.dart';
import 'package:easyuser/easyuser.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatRoomListTile extends StatelessWidget {
  const ChatRoomListTile({
    super.key,
    required this.room,
    this.onTap,
  });

  final ChatRoom room;
  final Function(BuildContext context, ChatRoom room, User? user)? onTap;

  @override
  Widget build(BuildContext context) {
    if (room.group == true) {
      return ListTile(
        minTileHeight: 72,
        leading: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.tertiaryContainer,
          ),
          width: 48,
          height: 48,
          clipBehavior: Clip.hardEdge,
          child: room.iconUrl != null && room.iconUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: room.iconUrl!,
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
        ),
        title: Text(
          room.name.trim().isNotEmpty ? room.name : "Group Chat",
        ),
        subtitle: subtitle(context),
        trailing: trailing,
        onTap: () => onTapTile(context, room, null),
      );
    }
    return UserBlocked(
      otherUid: getOtherUserUidFromRoomId(room.id)!,
      builder: (blocked) {
        if (blocked) {
          return const SizedBox.shrink();
        }
        return UserDoc.sync(
          uid: getOtherUserUidFromRoomId(room.id)!,
          builder: (user) {
            return ListTile(
              minTileHeight: 72,
              leading: user == null ? null : UserAvatar(user: user),
              title: Text(user != null && user.displayName.trim().isNotEmpty
                  ? user.displayName
                  : '...'),
              subtitle: subtitle(context),
              trailing: trailing,
              onTap: () => onTapTile(context, room, user),
            );
          },
        );
      },
    );
  }

  /// Returns a subtitle widget for the chat room list tile in chat room list view.
  ///
  /// It gets the last message from the chat/message/<room-id>.
  Widget? subtitle(BuildContext context) {
    if (!room.userUids.contains(myUid)) {
      if (room.description.trim().isEmpty) {
        return null;
      }
      return Text(
        room.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(90),
        ),
      );
    }
    return StreamBuilder<DatabaseEvent>(
      key: ValueKey("LastMessageText_${room.id}"),
      stream: ChatService.instance.messageRef(room.id).limitToLast(1).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("...");
        }
        // Maybe we can cache here to prevent the sudden "..." when the order is
        // being changed when there is new user.
        if (snapshot.data?.snapshot.value == null) {
          if (room.single == true) {
            return Text(
              'single chat no message, no invitations'.t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
              ),
            );
          } else {
            return Text(
              'no message yet'.t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
              ),
            );
          }
        }
        final firstRecord =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
                .entries
                .first;
        final messageJson = Map<String, dynamic>.from(firstRecord.value as Map);
        final lastMessage = ChatMessage.fromJson(messageJson, firstRecord.key);

        if (lastMessage.deleted) {
          return Text(
            'last message was deleted'.t,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
            ),
          );
        }
        if (UserService.instance.blockChanges.value
            .containsKey(lastMessage.uid)) {
          return const Text("...");
        }
        return Row(
          children: [
            if (!lastMessage.url.isNullOrEmpty) ...[
              const Icon(Icons.photo, size: 16),
              const SizedBox(width: 4),
            ],
            if (!lastMessage.text.isNullOrEmpty)
              Flexible(
                child: Text(
                  lastMessage.text!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (!lastMessage.url.isNullOrEmpty)
              Flexible(
                child: Text(
                  "[${'photo'.t}]",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(110),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget get trailing {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Value(
          ref: FirebaseDatabase.instance
              .ref()
              // TODO! DO NOT TYPE
              .child("chat/settings/${myUid!}/unread-message-count/${room.id}"),
          builder: (value, ref) {
            final int count = value ?? 0;
            if (count == 0) {
              return const SizedBox.shrink();
            }
            return ChatService.instance.newMessageBuilder
                    ?.call((value).toString()) ??
                Badge(
                  label: Text(
                    "$count",
                  ),
                );
          },
        ),
        Text((room.updatedAt).short),
      ],
    );
  }

  onTapTile(BuildContext context, ChatRoom room, User? user) {
    onTap != null
        ? onTap!.call(context, room, user)
        : ChatService.instance.showChatRoomScreen(
            context,
            room: room,
            user: user,
          );
  }
}
