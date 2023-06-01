import 'dart:io';

import 'package:data/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:data/models/author.dart';
import 'package:data/models/post.dart';
import 'package:data/utils/app_utils.dart';

class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);

  @Operation.get('id')
  Future<Response> getPost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path('id') int id,
  ) async {
    try {
      final currenAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.notFound(message: 'Post not found');
      }

      if (currenAuthorId != post.author?.id) {
        return AppResponse.forbidden(message: 'Access to post denied');
      }

      post.backing.removeProperty('author');

      return AppResponse.ok(message: 'Get post success', body: post.backing.contents);
    } catch (error) {
      return AppResponse.serverError(error, message: 'Create post error');
    }
  }

  @Operation.delete('id')
  Future<Response> deletePost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path('id') int id,
  ) async {
    try {
      final currenAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.notFound(message: 'Post not found');
      }

      if (currenAuthorId != post.author?.id) {
        return AppResponse.forbidden(message: 'Access to post denied');
      }

      final qDeletePost = Query<Post>(managedContext)..where((post) => post.id).equalTo(id);
      await qDeletePost.delete();

      return AppResponse.ok(message: 'Delete post success');
    } catch (error) {
      return AppResponse.serverError(error, message: 'Delete post error');
    }
  }

  @Operation.post()
  Future<Response> createPost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Post post,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<Author>(id);
      if (author == null) {
        final qCreateAuthor = Query<Author>(managedContext)..values.id = id;
        await qCreateAuthor.insert();
      }

      final qCreatePost = Query<Post>(managedContext)
        ..values.author?.id = id
        ..values.content = post.content;

      await qCreatePost.insert();

      return AppResponse.ok(message: 'Create post success');
    } catch (error) {
      return AppResponse.serverError(error, message: 'Create post error');
    }
  }

  @Operation.get()
  Future<Response> getPosts(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qGetPosts = Query<Post>(managedContext)..where((post) => post.author?.id).equalTo(id);
      final List<Post> posts = await qGetPosts.fetch();

      if (posts.isEmpty) {
        return AppResponse.notFound(message: 'Posts not found');
      }

      return Response.ok(posts);
    } catch (error) {
      return AppResponse.serverError(error, message: 'Get posts error');
    }
  }
}
