import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../data/repositories/task_repository.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskNotifierProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final pendingOpsAsync = ref.watch(pendingOperationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          // Indicador de sincronización pendiente
          pendingOpsAsync.when(
            data: (count) {
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Badge(
                      label: Text('$count'),
                      child: IconButton(
                        icon: const Icon(Icons.sync),
                        onPressed: () => _syncNow(context, ref),
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => _syncNow(context, ref),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<TaskFilter>(
              segments: const [
                ButtonSegment(
                  value: TaskFilter.all,
                  label: Text('Todas'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: TaskFilter.pending,
                  label: Text('Pendientes'),
                  icon: Icon(Icons.radio_button_unchecked),
                ),
                ButtonSegment(
                  value: TaskFilter.completed,
                  label: Text('Completadas'),
                  icon: Icon(Icons.check_circle),
                ),
              ],
              selected: {currentFilter},
              onSelectionChanged: (Set<TaskFilter> newSelection) {
                ref.read(taskFilterProvider.notifier).state =
                    newSelection.first;
                ref.read(taskNotifierProvider.notifier).loadTasks();
              },
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(currentFilter),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(taskNotifierProvider.notifier).loadTasks();
            },
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskListItem(task: tasks[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error al cargar tareas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(taskNotifierProvider.notifier).loadTasks();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getEmptyMessage(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'No hay tareas. ¡Agrega una nueva!';
      case TaskFilter.pending:
        return 'No hay tareas pendientes';
      case TaskFilter.completed:
        return 'No hay tareas completadas';
    }
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const AddTaskDialog());
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(taskNotifierProvider.notifier).syncPendingOperations();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
