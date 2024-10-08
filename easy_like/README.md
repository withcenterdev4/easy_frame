# Easy Like and Dislike

The `like` unctionality can be applied to various entities in the app, such as user profiles, uploaded photos, posts, and comments.

A simple way to handle this is by saving a list of user IDs who liked or disliked an item. However, if the document becomes too large, it can slow down the app and increase costs for network usage on Firebase. Additionally, Firestore documents have a 1MB size limit, which can cause issues when there are too many like.

The `easy_like` package provides an easy and efficient way to manage the `like` functionality.

It does not support `dislike` since most of the community don't provide `dislike` button. It discourages usres to participate the community.

## Installation

### Security rules

- On the document, the `likes` should be open to be written by any one.

## Terms

- `vote` is the action of voting(doing) like or unlike.
- `like document` is the document under `/likes` collection.
- `target document` is the original document that hte like is refering. It can be a user document, post document, commnet document, chat room document, or what ever.

## Database structure for Like and Dislike

- `/likes/{documentId}`: This is where like information saved. And the id of the document is the target document.
- `documentReference`: This field is reference of the target document. It's a reference. So it can access the target document regardless of any collection.
- `likedBy`: This field is the list of user uid who did like. If the user unlikes, then the uid will be removed from this field.
- `likeCount`: This field is the no of the likes. It can be used for search purpose.

- Note that, the `like document ID` is the same as the target document ID.

## Logic

- It uses transaction to increase and decrease.
- Whenever there is a changes on `vote`, the number of `likeCount` must be updated in the original document.
- When the user unlike(or the like again), then the no of like will be decrease.

## Displaying the no of likes

- Since the `likeCount` field is saved on the document, it can simply display with the document. so, the `easy_like` package does not provide andy widgets.

- Below is how to diplay `likeCount` on a post detail screen. Note the the post detail screen should listen to the database update.

Example:

```dart
TextButton(
  onPressed: () async {
    final like = Like(uid: my.uid, documentReference: widget.post.ref);
    await like.like();
  },
  child: Text(
    'Like'.tr( args: {'n': widget.post.likeCount}, form: widget.post.likeCount),
  ),
),
```

## Changing Icons if like or unlike

- You can display diffrent widget base on the status of the like (like or unlike)

- `LikeDoc` is a widget that you can use to determine of the like status(like or unlike)

Example

```dart
IconButton(
  onPressed: () async {
    final like = Like(documentReference: post.ref);
    await like.like();
  },
  icon: LikeDoc(
      uid: my.uid,
      documentReference: post.ref,
      sync: true,
      builder: (islike) {
        return FaIcon(
          islike
              ? FontAwesomeIcons.solidHeart
              : FontAwesomeIcons.heart,
          color: Colors.pink[700],
          size: 30,
        );
      }),
),
```

# onLiked CallBack

The `onLiked` is a callback after the liked/unliked is triggered using the Like.like() model is fired.

Usage: (e.g. send push notification to other user)

In the example below, we can send push notification to the post owner after the like is triggered. It contains the `Like` information, and `isLiked` if the like is liked or not.

```dart
    LikeService.instance.init(
      onLiked: ({required Like like, required bool isLiked}) async {
        /// only send notification if it is liked
        if (isLiked == false) return;

        /// get the like document reference for more information
        /// then base from the document reference you can swich or decide where the notificaiton should go
        /// set push notification. e.g. send push notification to post like
        if (like.documentReference.toString().contains('posts/')) {
          Post post = await Post.get(like.documentReference.id);

          /// dont send push notification if the owner of the post is the loggin user.
          if (post.uid == myUid) return;

          /// can get more information base from the documentReference
          /// can give more details on the push notification
          MessagingService.instance.sendMessageToUids(
            uids: [post.uid],
            title: 'Your post got liked',
            body: '${my.displayName} liked ${post.title}',
            data: {
              "action": 'like',
              "source": 'post',
              'postId': post.id,
              'documentReference': like.documentReference.toString(),
            },
          );
        }
      },
    );
```
