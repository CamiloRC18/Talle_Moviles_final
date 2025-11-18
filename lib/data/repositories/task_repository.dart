import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../local/database_helper.dart';
import '../romote/task_api.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper;
  final TaskApi _api;
  final Connectivity _connectivity;
  final Uuid _uuid = const Uuid();

  TaskRepository({
    DatabaseHelper? dbHelper,
    TaskApi? api,
    Connectivity? connectivity,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _api = api ?? TaskApi(),
       _connectivity = connectivity ?? Connectivity();

  // Verificar conectividad
  Future<bool> _hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  // Obtener todas las tareas (Offline-First)
  Future<List<Task>> getAllTasks() async {
    // Primero devolver datos locales
    final localTasks = await _dbHelper.getAllTasks();

    // Si hay conexión, intentar sincronizar en segundo plano
    if (await _hasConnection()) {
      _syncTasksInBackground();
    }

    return localTasks;
  }

  // Sincronizar tareas en segundo plano
  Future<void> _syncTasksInBackground() async {
    try {
      final remoteTasks = await _api.getTasks();

      // Actualizar base de datos local
      for (final remoteTask in remoteTasks) {
        final localTask = await _dbHelper.getTaskById(remoteTask.id);

        if (localTask == null) {
          // Tarea nueva del servidor
          await _dbHelper.createTask(remoteTask);
        } else {
          // Resolver conflictos usando Last-Write-Wins
          final remoteDate = DateTime.parse(remoteTask.updatedAt);
          final localDate = DateTime.parse(localTask.updatedAt);

          if (remoteDate.isAfter(localDate)) {
            await _dbHelper.updateTask(remoteTask);
          }
        }
      }
    } catch (e) {
      // Fallo silencioso en sincronización de fondo
      print('Error en sincronización de fondo: $e');
    }
  }

  // Crear tarea
  Future<Task> createTask(String title) async {
    final now = DateTime.now().toIso8601String();
    final task = Task(
      id: _uuid.v4(),
      title: title,
      completed: false,
      updatedAt: now,
    );

    // Guardar localmente primero
    await _dbHelper.createTask(task);

    // Encolar operación para sincronización
    final operation = QueuedOperation(
      id: _uuid.v4(),
      entity: 'task',
      entityId: task.id,
      op: 'CREATE',
      payload: json.encode(task.toJson()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _dbHelper.addQueueOperation(operation);

    // Intentar sincronizar inmediatamente si hay conexión
    if (await _hasConnection()) {
      _syncOperations();
    }

    return task;
  }

  // Actualizar tarea
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Actualizar localmente
    await _dbHelper.updateTask(updatedTask);

    // Encolar operación
    final operation = QueuedOperation(
      id: _uuid.v4(),
      entity: 'task',
      entityId: updatedTask.id,
      op: 'UPDATE',
      payload: json.encode(updatedTask.toJson()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _dbHelper.addQueueOperation(operation);

    // Intentar sincronizar
    if (await _hasConnection()) {
      _syncOperations();
    }

    return updatedTask;
  }

  // Marcar como completada
  Future<Task> toggleTaskCompleted(String id) async {
    final task = await _dbHelper.getTaskById(id);
    if (task == null) {
      throw Exception('Tarea no encontrada');
    }

    return updateTask(task.copyWith(completed: !task.completed));
  }

  // Eliminar tarea
  Future<void> deleteTask(String id) async {
    // Marcar como eliminada localmente
    await _dbHelper.deleteTask(id);

    // Encolar operación
    final operation = QueuedOperation(
      id: _uuid.v4(),
      entity: 'task',
      entityId: id,
      op: 'DELETE',
      payload: json.encode({'id': id}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _dbHelper.addQueueOperation(operation);

    // Intentar sincronizar
    if (await _hasConnection()) {
      _syncOperations();
    }
  }

  // Sincronizar operaciones pendientes
  Future<void> syncPendingOperations() async {
    if (!await _hasConnection()) {
      throw ApiException('Sin conexión a internet');
    }

    await _syncOperations();
  }

  Future<void> _syncOperations() async {
    final pendingOps = await _dbHelper.getPendingOperations();

    for (final op in pendingOps) {
      try {
        switch (op.op) {
          case 'CREATE':
            final task = Task.fromJson(json.decode(op.payload));
            await _api.createTask(task, idempotencyKey: op.id);
            break;
          case 'UPDATE':
            final task = Task.fromJson(json.decode(op.payload));
            await _api.updateTask(task, idempotencyKey: op.id);
            break;
          case 'DELETE':
            final data = json.decode(op.payload);
            await _api.deleteTask(data['id']);
            break;
        }

        // Operación exitosa, eliminar de la cola
        await _dbHelper.removeQueueOperation(op.id);
      } catch (e) {
        // Actualizar contador de intentos y error
        final updatedOp = QueuedOperation(
          id: op.id,
          entity: op.entity,
          entityId: op.entityId,
          op: op.op,
          payload: op.payload,
          createdAt: op.createdAt,
          attemptCount: op.attemptCount + 1,
          lastError: e.toString(),
        );
        await _dbHelper.updateQueueOperation(updatedOp);

        // Si hay muchos intentos fallidos, considerar eliminar
        if (updatedOp.attemptCount > 5) {
          print('Operación ${op.id} falló después de 5 intentos');
        }
      }
    }
  }

  // Obtener tareas filtradas
  Future<List<Task>> getFilteredTasks(TaskFilter filter) async {
    final allTasks = await getAllTasks();

    switch (filter) {
      case TaskFilter.all:
        return allTasks;
      case TaskFilter.pending:
        return allTasks.where((task) => !task.completed).toList();
      case TaskFilter.completed:
        return allTasks.where((task) => task.completed).toList();
    }
  }

  // Obtener conteo de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    final ops = await _dbHelper.getPendingOperations();
    return ops.length;
  }
}

enum TaskFilter { all, pending, completed }
