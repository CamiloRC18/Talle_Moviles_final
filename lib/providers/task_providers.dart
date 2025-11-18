import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/task_repository.dart';
import '../models/task.dart';

// Provider del repositorio
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Provider del filtro actual
final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter.all;
});

// Provider de las tareas
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);
  return repository.getFilteredTasks(filter);
});

// Provider para contar operaciones pendientes
final pendingOperationsProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getPendingOperationsCount();
});

// StateNotifier para manejar el estado de las tareas
class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskRepository _repository;
  final Ref _ref;

  TaskNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final filter = _ref.read(taskFilterProvider);
      final tasks = await _repository.getFilteredTasks(filter);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createTask(String title) async {
    try {
      await _repository.createTask(title);
      await loadTasks();
    } catch (e) {
      // Manejar error
      rethrow;
    }
  }

  Future<void> toggleTask(String id) async {
    try {
      await _repository.toggleTaskCompleted(id);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _repository.updateTask(task);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncPendingOperations() async {
    try {
      await _repository.syncPendingOperations();
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
      final repository = ref.watch(taskRepositoryProvider);
      return TaskNotifier(repository, ref);
    });
