import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/task.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class TaskApi {
  // Cambia esta URL según tu dispositivo:
  // Android Emulator: http://10.0.2.2:3000
  // iOS Simulator: http://localhost:3000
  // Dispositivo físico: http://TU_IP:3000
  static const String baseUrl = 'http://10.0.2.2:3000'; // Para Android Emulator
  final http.Client _client;
  final Duration timeout = const Duration(seconds: 10);

  TaskApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Task>> getTasks() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/tasks'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw ApiException(
          'Error del cliente: ${response.reasonPhrase}',
          response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          'Error del servidor: ${response.reasonPhrase}',
          response.statusCode,
        );
      } else {
        throw ApiException(
          'Error desconocido: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } on HttpException {
      throw ApiException('No se pudo encontrar el servidor');
    } on FormatException {
      throw ApiException('Respuesta inválida del servidor');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  Future<Task> createTask(Task task, {String? idempotencyKey}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };

      final response = await _client
          .post(
            Uri.parse('$baseUrl/tasks'),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw ApiException(
          'Error al crear tarea: ${response.reasonPhrase}',
          response.statusCode,
        );
      } else {
        throw ApiException(
          'Error del servidor al crear tarea',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al crear tarea: $e');
    }
  }

  Future<Task> getTask(String id) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/tasks/$id'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Tarea no encontrada', 404);
      } else {
        throw ApiException('Error al obtener tarea', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener tarea: $e');
    }
  }

  Future<Task> updateTask(Task task, {String? idempotencyKey}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };

      final response = await _client
          .put(
            Uri.parse('$baseUrl/tasks/${task.id}'),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Tarea no encontrada', 404);
      } else {
        throw ApiException('Error al actualizar tarea', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al actualizar tarea: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/tasks/$id'))
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw ApiException('Tarea no encontrada', 404);
      } else {
        throw ApiException('Error al eliminar tarea', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al eliminar tarea: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
