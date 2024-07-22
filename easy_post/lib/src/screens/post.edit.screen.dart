import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_locale/easy_locale.dart';
import 'package:easy_post_v2/easy_post_v2.dart';
import 'package:easy_post_v2/unit_test/post_test.dart';
import 'package:easy_storage/easy_storage.dart';
import 'package:flutter/material.dart';
import 'package:easy_storage/easy_storage.dart';

class PostEditScreen extends StatefulWidget {
  static const String routeName = '/PostEdit';
  const PostEditScreen({super.key, required this.category, this.post});

  final String? category;
  final Post? post;

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  String? category;

  bool get isCreate => widget.post == null;
  bool get isUpdate => !isCreate;

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final youtubeController = TextEditingController();

  final List<String> urls = [];
  double uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      category = widget.category!;
    }
  }

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isCreate ? 'Create'.t : 'Update'.t,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButton<String?>(
                    isDense: false,
                    padding: const EdgeInsets.only(
                        left: 12, top: 4, right: 4, bottom: 4),
                    isExpanded: true, // 화살표 아이콘을 오른쪽에 밀어 붙이기
                    menuMaxHeight: 300, // 높이 조절
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Select Category'),
                      ),
                      ...PostService.instance.categories.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }),
                    ],
                    value: category,
                    onChanged: (value) {
                      setState(() {
                        category = value;
                      });
                    }),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: contentController,
                  minLines: 5,
                  maxLines: 8,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: youtubeController,
                  decoration: InputDecoration(
                    hintText: 'Youtube'.t,
                    labelText: 'Youtube'.t,
                  ),
                ),
                const SizedBox(height: 24),
                DisplayEditableUploads(
                    urls: urls,
                    onDelete: (url) async {
                      setState(() => urls.remove(url));

                      /// If isUpdate then delete the url silently from the server
                      /// sometimes the user delete a url from post/comment but didnt save the post. so the url still exist but the actual image is already deleted
                      /// so we need to update the post to remove the url from the server
                      /// this will prevent error like the url still exist but the image is already deleted
                      if (isUpdate) {
                        await widget.post!.update(
                          urls: widget.post!.urls,
                        );
                      }
                    }),
                Row(
                  children: [
                    UploadIconButton(
                      photoCamera: true,
                      photoGallery: true,
                      videoCamera: false,
                      videoGallery: false,
                      gallery: false,
                      file: false,
                      icon: const Icon(Icons.camera_alt),
                      onUpload: (url) {
                        urls.add(url);
                        setState(() {});
                      },
                      progress: (v) {
                        setState(() => uploadProgress = v);
                      },
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        final ref = await Post.create(
                            category: category ?? '',
                            title: titleController.text,
                            content: contentController.text,
                            youtubeUrl: youtubeController.text,
                            urls: urls);
                        if (context.mounted) {
                          Navigator.of(context).pop(ref);
                        }
                      },
                      child: Text('Created'.t),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
