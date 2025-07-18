// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirva_app/api_models.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:nirva_app/my_hive_objects.dart';
import 'package:nirva_app/providers/chat_history_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:nirva_app/data.dart';
import 'package:nirva_app/hive_helper.dart';
import 'package:nirva_app/url_configuration.dart';

class NirvaAPI {
  // 服务器地址 localNetworkServerAddress
  static const String localNetworkServerAddress = '192.168.192.104';
  static const String devAWSServerAddress = '34.229.128.139';

  // 基础端口号
  static const int basePort = 8000;

  // 开发环境的 HTTP URL，局域网。
  static const String devLocalHostHttpUrl =
      'http://$localNetworkServerAddress:$basePort';

  // 开发环境的 HTTP URL, 外网。
  static const String devAwsServerHttpUrl =
      'http://$devAWSServerAddress:$basePort';

  // url 配置
  static final URLConfiguration _urlConfig = URLConfiguration();

  // 静态 Dio 实例
  static final Dio _dio = Dio(
      BaseOptions(
        baseUrl: devAwsServerHttpUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )
    ..interceptors.addAll([
      LogInterceptor(request: true, requestHeader: true, responseHeader: true),
      InterceptorsWrapper(
        onError: (error, handler) {
          Logger().e('Dio Error: ${error.message}');
          return handler.next(error);
        },
      ),
    ]);

  // 静态getter方法
  static URLConfiguration get urlConfig => _urlConfig;
  static Dio get dio => _dio;

  // 获取 URL 配置，故意不抓留给外面抓。
  static Future<URLConfigurationResponse?> getUrlConfig() async {
    final response = await _dio.get<dynamic>("/config");
    final url_configuration_response = URLConfigurationResponse.fromJson(
      response.data!,
    );
    _urlConfig.setup(url_configuration_response);
    return url_configuration_response;
  }

  // 登录方法
  static Future<UserToken?> login(User user) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _urlConfig.loginUrl,
      data: {
        'username': user.username,
        'password': user.password,
        'grant_type': 'password',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType, // OAuth2默认表单格式
      ),
    );

    if (response.statusCode != 200) {
      Logger().e('登录请求失败: ${response.statusCode}, ${response.statusMessage}');
      return null;
    }

    if (response.data == null) {
      Logger().e('登录请求没有返回数据');
      return null;
    }

    final userToken = UserToken(
      access_token: response.data!['access_token'] ?? '',
      token_type: response.data!['token_type'] ?? '',
      refresh_token: response.data!['refresh_token'] ?? '', // 新增字段
    );
    HiveHelper.saveUserToken(userToken); // 保存到Hive中
    Logger().i('登录成功！令牌已获取');
    return userToken;
  }

  // 登出方法，故意不抓留给外面抓。
  static Future<bool> logout() async {
    final response = await _dio.post<Map<String, dynamic>>(
      _urlConfig.logoutUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveHelper.getUserToken().access_token}',
        },
      ),
    );

    if (response.statusCode != 200) {
      Logger().e('登出请求失败: ${response.statusCode}, ${response.statusMessage}');
      return false;
    }

    await HiveHelper.deleteUserToken(); // 清除本地令牌
    Logger().i('登出成功！令牌已清除');
    return true;
  }

  // 刷新访问令牌，故意不抓留给外面抓。
  static Future<UserToken?> refreshToken() async {
    if (HiveHelper.getUserToken().refresh_token.isEmpty) {
      Logger().e("没有可用的刷新令牌，无法刷新访问令牌。");
      return null;
    }

    // 发送刷新令牌请求
    final response = await _dio.post<Map<String, dynamic>>(
      _urlConfig.refreshUrl,
      // 使用表单数据格式发送
      data: FormData.fromMap({
        'refresh_token': HiveHelper.getUserToken().refresh_token,
      }),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      Logger().e('令牌刷新请求失败: ${response.statusCode}, ${response.statusMessage}');
      return null;
    }
    if (response.data == null) {
      Logger().e('令牌刷新请求没有返回数据');
      return null;
    }

    // 创建新的 Token 实例并保存到 Hive
    final newToken = UserToken(
      access_token: response.data!["access_token"],
      token_type: HiveHelper.getUserToken().token_type, // 保持原有的 token_type
      refresh_token: response.data!["refresh_token"],
    );

    // 保存更新后的令牌
    await HiveHelper.saveUserToken(newToken);
    Logger().i("令牌刷新成功！");
    return newToken;
  }

  // 简单的post请求方法
  static Future<Response<T>?> simplePost<T>(
    Dio dio,
    String path,
    UserToken userToken, {
    Object? data,
    Map<String, dynamic>? query,
    int receiveTimeout = 30, // 添加接收超时参数，默认30秒
  }) async {
    Logger().d('POST Request - URL: $path, Data: $data');
    final response = await dio.post<T>(
      path,
      data: data,
      queryParameters: query,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userToken.access_token}',
        },
        receiveTimeout: Duration(seconds: receiveTimeout), // 设置接收超时时间
      ),
    );

    if (response.statusCode != 200) {
      Logger().e('Error: ${response.statusCode}, ${response.statusMessage}');
      return null;
    }

    Logger().d('POST Response: ${response.data}');
    return response;
  }

  // 简单的get请求方法
  static Future<Response<T>?> simpleGet<T>(
    Dio dio,
    String path,
    UserToken userToken, {
    Map<String, dynamic>? query,
    int receiveTimeout = 30, // 添加接收超时参数，默认30秒
  }) async {
    Logger().d('GET Request - URL: $path, Query: $query');
    final response = await dio.get<T>(
      path,
      queryParameters: query,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userToken.access_token}',
        },
        receiveTimeout: Duration(seconds: receiveTimeout), // 设置接收超时时间
      ),
    );

    if (response.statusCode != 200) {
      Logger().e('Error: ${response.statusCode}, ${response.statusMessage}');
      return null;
    }

    Logger().d('GET Response: ${response.data}');
    return response;
  }

  // 安全POST请求方法 - 自动处理授权过期并重试, 内部会只抓取401错误
  static Future<Response<T>?> safePost<T>(
    Dio dio,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    int receiveTimeout = 30, // 添加接收超时参数
  }) async {
    //final appRuntimeContext = AppService();
    final userToken = HiveHelper.getUserToken();

    try {
      // 首次尝试发送请求，传递超时参数
      return await simplePost<T>(
        dio,
        path,
        userToken,
        data: data,
        query: query,
        receiveTimeout: receiveTimeout,
      );
    } on DioException catch (e) {
      // 捕获 401 未授权错误
      if (e.response?.statusCode == 401 && userToken.refresh_token.isNotEmpty) {
        Logger().w('授权已过期，尝试刷新令牌...');

        // 尝试刷新令牌
        final newToken = await refreshToken();
        if (newToken != null) {
          Logger().i('令牌刷新成功，重新发送请求');
          // 使用新令牌重新尝试请求，同样传递超时参数
          return await simplePost<T>(
            dio,
            path,
            newToken,
            data: data,
            query: query,
            receiveTimeout: receiveTimeout,
          );
        }
      }

      // 其他类型的 DioException，直接抛出
      Logger().e('请求失败: ${e.message}');
      rethrow;
    }
  }

  // 安全GET请求方法 - 自动处理授权过期并重试, 内部会只抓取401错误
  static Future<Response<T>?> safeGet<T>(
    Dio dio,
    String path, {
    Map<String, dynamic>? query,
    int receiveTimeout = 30, // 添加接收超时参数
  }) async {
    //final appRuntimeContext = AppService();
    final userToken = HiveHelper.getUserToken();

    try {
      // 首次尝试发送请求，传递超时参数
      return await simpleGet<T>(
        dio,
        path,
        userToken,
        query: query,
        receiveTimeout: receiveTimeout,
      );
    } on DioException catch (e) {
      // 捕获 401 未授权错误
      if (e.response?.statusCode == 401 && userToken.refresh_token.isNotEmpty) {
        Logger().w('授权已过期，尝试刷新令牌...');

        // 尝试刷新令牌
        final newToken = await refreshToken();
        if (newToken != null) {
          Logger().i('令牌刷新成功，重新发送请求');
          // 使用新令牌重新尝试请求，同样传递超时参数
          return await simpleGet<T>(
            dio,
            path,
            newToken,
            query: query,
            receiveTimeout: receiveTimeout,
          );
        }
      }

      // 其他类型的 DioException，直接抛出
      Logger().e('请求失败: ${e.message}');
      rethrow;
    }
  }

  // 聊天请求, 故意不抓留给外面抓。
  static Future<ChatActionResponse?> chat(
    String content,
    BuildContext? context,
  ) async {
    final uuid = Uuid(); // 创建UUID生成器实例

    // 获取 ChatHistoryProvider
    ChatHistoryProvider? chatHistoryProvider;
    if (context != null) {
      chatHistoryProvider = Provider.of<ChatHistoryProvider>(
        context,
        listen: false,
      );
    }

    final chatActionRequest = ChatActionRequest(
      human_message: ChatMessage(
        id: uuid.v4(), // 使用uuid生成唯一ID
        role: MessageRole.human,
        content: content,
        time_stamp: JournalFile.dateTimeToKey(DateTime.now()),
      ),
      chat_history: chatHistoryProvider?.chatHistory ?? [],
    );

    // 添加详细日志，查看完整请求体
    final requestJson = chatActionRequest.toJson();
    Logger().d('Chat request payload: ${jsonEncode(requestJson)}');

    final response = await safePost<Map<String, dynamic>>(
      _dio,
      _urlConfig.chatActionUrl,
      data: chatActionRequest.toJson(),
    );

    if (response == null || response.data == null) {
      Logger().e('Chat action failed: No response data');
      return null;
    }

    final chatResponse = ChatActionResponse.fromJson(response.data!);
    Logger().d('Chat action response: ${jsonEncode(chatResponse.toJson())}');

    if (chatHistoryProvider != null) {
      chatHistoryProvider.addChatMessages([
        chatActionRequest.human_message,
        chatResponse.ai_message,
      ]);

      // _saveMessages 会通过监听器自动调用
      HiveHelper.saveChatHistory(chatHistoryProvider.chatHistory);
    }
    return chatResponse; // 这里返回null是因为没有实现具体的聊天逻辑
  }

  // 上传转录文本, 故意不抓留给外面抓。
  static Future<UploadTranscriptActionResponse?> uploadTranscript(
    String transcriptContent,
    String timeStamp,
    int fileNumber,
    String fileSuffix,
  ) async {
    final uploadTranscriptActionRequest = UploadTranscriptActionRequest(
      transcript_content: transcriptContent,
      time_stamp: timeStamp,
      file_number: fileNumber,
      file_suffix: fileSuffix,
    );

    final response = await safePost<Map<String, dynamic>>(
      _dio,
      _urlConfig.uploadTranscriptUrl,
      data: uploadTranscriptActionRequest.toJson(),
    );

    if (response == null || response.data == null) {
      Logger().e('Upload transcript action failed: No response data');
      return null;
    }

    final uploadResponse = UploadTranscriptActionResponse.fromJson(
      response.data!,
    );
    Logger().d(
      'Upload transcript action response: ${jsonEncode(uploadResponse.toJson())}',
    );

    return uploadResponse;
  }

  // 分析请求, 故意不抓留给外面抓。
  static Future<BackgroundTaskResponse?> analyze(
    String timeStamp,
    int fileNumber,
  ) async {
    final analyzeActionRequest = AnalyzeActionRequest(
      time_stamp: timeStamp,
      file_number: fileNumber,
    );

    final response = await safePost<Map<String, dynamic>>(
      _dio,
      _urlConfig.analyzeActionUrl,
      data: analyzeActionRequest.toJson(),
      receiveTimeout: 60, // 设置接收超时时间为60秒, 时间较长。
    );

    if (response == null || response.data == null) {
      Logger().e('Analyze action failed: No response data');
      return null;
    }

    final backgroundTaskResponse = BackgroundTaskResponse.fromJson(
      response.data!,
    );
    Logger().d(
      'Analyze action response: ${jsonEncode(backgroundTaskResponse.toJson())}',
    );

    return backgroundTaskResponse;
  }

  static Future<JournalFile?> getJournalFile(String timeStamp) async {
    final response = await safeGet<Map<String, dynamic>>(
      _dio,
      _urlConfig.formatGetJournalFileUrl(timeStamp),
      query: {'time_stamp': timeStamp},
    );

    if (response == null || response.data == null) {
      Logger().e('Get journal file failed: No response data');
      return null;
    }

    // 直接存。
    await HiveHelper.createJournalFile(
      fileName: timeStamp,
      content: jsonEncode(response.data!),
    );

    // 读一下试试
    final journalFileStorage = HiveHelper.getJournalFile(timeStamp);

    // 没有存储成功，就是有问题。
    if (journalFileStorage == null) {
      return null;
    }

    // 直接测试一次！
    final jsonDecode =
        json.decode(journalFileStorage.content) as Map<String, dynamic>;

    final journalFile = JournalFile.fromJson(jsonDecode);
    Logger().d('Journal file loaded: ${jsonEncode(journalFile.toJson())}');

    // 注意：此方法不再自动添加到AppService，调用方需要自行处理
    // 如需添加到状态管理，请在调用方使用Provider
    return journalFile;
  }

  static Future<Map<String, dynamic>?> getTaskStatus(String taskId) async {
    final response = await safeGet<Map<String, dynamic>>(
      _dio,
      _urlConfig.formatTaskStatusUrl(taskId),
    );

    if (response == null || response.data == null) {
      Logger().e('Get task status failed: No response data');
      return null;
    }

    final taskStatus = response.data!;
    Logger().d('Task status response: ${jsonEncode(taskStatus)}');
    return taskStatus;
  }
}
