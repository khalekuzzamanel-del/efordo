import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../workspaces/domain/workspace.dart';
import '../../workspaces/providers/workspace_notifier.dart';
import '../domain/project.dart';
import '../providers/project_notifier.dart';

class ProjectsShell extends ConsumerStatefulWidget {
  const ProjectsShell({super.key});

  @override
  ConsumerState<ProjectsShell> createState() => _ProjectsShellState();
}

class _ProjectsShellState extends ConsumerState<ProjectsShell> {
  bool _showWorkspaces = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(workspacesProvider.notifier).load();
      await ref.read(projectsProvider.notifier).load();
    });
  }

  Future<void> _showCreateProjectSheet({Project? project}) async {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController = TextEditingController(text: project?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = project != null;
    final workspaces = ref.read(workspacesProvider).valueOrNull ?? [];
    var selWsId = project?.workspaceId;
    var selStatus = project?.status ?? 'active';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(isEdit ? 'Edit Project' : 'Create Project', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: selWsId,
                  decoration: const InputDecoration(labelText: 'Workspace'),
                  items: workspaces.map((w) => DropdownMenuItem(
                    value: w.id, child: Text(w.name),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selWsId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: Project.statuses.map((s) => DropdownMenuItem(
                    value: s, child: Text(_statusLabel(s)),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selStatus = v ?? 'active'),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final data = {
                      'workspace_id': selWsId,
                      'name': nameController.text.trim(),
                      'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                      'status': selStatus,
                    };
                    final notifier = ref.read(projectsProvider.notifier);
                    if (isEdit) {
                      await notifier.update(project!.id, data);
                    } else {
                      await notifier.create(data);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateEditWorksheet({Workspace? workspace}) async {
    final nameController = TextEditingController(text: workspace?.name ?? '');
    final descController = TextEditingController(text: workspace?.description ?? '');
    final colorController = TextEditingController(text: workspace?.color ?? '#6C63FF');
    final formKey = GlobalKey<FormState>();
    final isEdit = workspace != null;
    final notifier = ref.read(workspacesProvider.notifier);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(isEdit ? 'Edit Workspace' : 'New Workspace', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final data = <String, dynamic>{
                    'name': nameController.text.trim(),
                    'description': descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    'color': colorController.text.trim(),
                  };
                  if (isEdit) {
                    await notifier.update(workspace!.id, data);
                  } else {
                    await notifier.create(data);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(isEdit ? 'Save' : 'Create'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleArchiveWorkspace(Workspace ws) async {
    final confirmed = await showConfirmationDialog(context,
      title: 'Archive Workspace', message: 'Archive "${ws.name}"?',
      confirmLabel: 'Archive', isDestructive: true,
    );
    if (confirmed == true) await ref.read(workspacesProvider.notifier).archive(ws.id);
  }

  Future<void> _handleRestoreWorkspace(Workspace ws) async {
    await ref.read(workspacesProvider.notifier).restore(ws.id);
  }

  Future<void> _handleDeleteWorkspace(Workspace ws) async {
    final confirmed = await showConfirmationDialog(context,
      title: 'Delete Workspace', message: 'Delete "${ws.name}" permanently?',
      confirmLabel: 'Delete', isDestructive: true,
    );
    if (confirmed == true) await ref.read(workspacesProvider.notifier).delete(ws.id);
  }

  Future<void> _handleArchiveProject(Project p) async {
    final confirmed = await showConfirmationDialog(context,
      title: 'Archive Project',
      message: 'Archive "${p.name}"?',
      confirmLabel: 'Archive', isDestructive: true,
    );
    if (confirmed == true) await ref.read(projectsProvider.notifier).archive(p.id);
  }

  Future<void> _handleRestoreProject(Project p) async {
    await ref.read(projectsProvider.notifier).restore(p.id);
  }

  Future<void> _handleDeleteProject(Project p) async {
    final confirmed = await showConfirmationDialog(context,
      title: 'Delete Project',
      message: 'Delete "${p.name}" permanently?',
      confirmLabel: 'Delete', isDestructive: true,
    );
    if (confirmed == true) await ref.read(projectsProvider.notifier).delete(p.id);
  }

  String _statusLabel(String s) {
    switch (s) { case 'active': return 'Active'; case 'on_hold': return 'On Hold'; case 'completed': return 'Completed'; default: return s; }
  }

  Color _statusColor(String s) {
    switch (s) { case 'active': return Colors.green; case 'on_hold': return Colors.orange; case 'completed': return Colors.blue; default: return Colors.grey; }
  }

  String _workspaceName(String id) {
    final ws = ref.read(workspacesProvider).valueOrNull ?? [];
    return ws.where((w) => w.id == id).firstOrNull?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspacesAsync = ref.watch(workspacesProvider);
    final projectsAsync = ref.watch(projectsProvider);

    if (_showWorkspaces) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Workspaces'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _showWorkspaces = false),
              child: const Text('All Projects'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(workspacesProvider.notifier).load(),
          child: workspacesAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorStateWidget(
              message: e.toString(),
              retryLabel: 'Retry',
              onRetry: () => ref.read(workspacesProvider.notifier).load(),
            ),
            data: (workspaces) {
              if (workspaces.isEmpty) {
                return ListView(children: const [
                  SizedBox(height: 200),
                  EmptyStateWidget(
                    icon: Icons.folder_outlined,
                    title: 'No workspaces yet',
                    subtitle: 'Create your first workspace to organize projects',
                  ),
                ]);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: workspaces.length,
                itemBuilder: (ctx, i) {
                  final ws = workspaces[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () async {
                        ref.read(projectsProvider.notifier).setWorkspaceFilter(ws.id);
                        await ref.read(projectsProvider.notifier).load();
                        if (mounted) setState(() => _showWorkspaces = false);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ws.color != null
                              ? Color(int.parse(ws.color!.replaceFirst('#', '0xFF')))
                              : theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.folder_outlined),
                        ),
                        title: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${ws.projectCount ?? 0} projects'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'edit':
                                _showCreateEditWorksheet(workspace: ws);
                              case 'archive':
                                _handleArchiveWorkspace(ws);
                              case 'restore':
                                _handleRestoreWorkspace(ws);
                              case 'delete':
                                _handleDeleteWorkspace(ws);
                            }
                          },
                          itemBuilder: (ctx) {
                            final items = <PopupMenuEntry<String>>[];
                            if (ws.isArchived) {
                              items.add(const PopupMenuItem(value: 'restore', child: Text('Restore')));
                            } else {
                              items.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
                              items.add(const PopupMenuItem(value: 'archive', child: Text('Archive')));
                            }
                            items.add(const PopupMenuDivider());
                            items.add(const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ));
                            return items;
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateProjectSheet(),
          heroTag: 'projects_fab',
          child: const Icon(Icons.add),
        ),
      );
    }

    // Project list view
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          if (ref.read(projectsProvider.notifier).workspaceFilter != null)
            TextButton(
              onPressed: () async {
                ref.read(projectsProvider.notifier).setWorkspaceFilter(null);
                await ref.read(projectsProvider.notifier).load();
                if (mounted) setState(() {});
              },
              child: const Text('Clear Filter'),
            ),
          TextButton(
            onPressed: () => setState(() => _showWorkspaces = true),
            child: const Text('Workspaces'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(projectsProvider.notifier).load(),
        child: projectsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString(),
            retryLabel: 'Retry',
            onRetry: () => ref.read(projectsProvider.notifier).load(),
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 200),
                EmptyStateWidget(
                  icon: Icons.task_alt_outlined,
                  title: 'No projects',
                  subtitle: 'Tap + to create a project',
                ),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: projects.length,
              itemBuilder: (ctx, i) {
                final p = projects[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${_workspaceName(p.workspaceId)}  •  ${_statusLabel(p.status)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(p.status).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(p.status),
                              style: TextStyle(fontSize: 11, color: _statusColor(p.status), fontWeight: FontWeight.w600),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              switch (v) {
                                case 'edit': _showCreateProjectSheet(project: p);
                                case 'archive': _handleArchiveProject(p);
                                case 'restore': _handleRestoreProject(p);
                                case 'delete': _handleDeleteProject(p);
                              }
                            },
                            itemBuilder: (ctx) {
                              final items = <PopupMenuEntry<String>>[];
                              if (p.isArchived) {
                                items.add(const PopupMenuItem(value: 'restore', child: Text('Restore')));
                              } else {
                                items.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
                                items.add(const PopupMenuItem(value: 'archive', child: Text('Archive')));
                              }
                              items.add(const PopupMenuDivider());
                              items.add(const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ));
                              return items;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectSheet(),
        heroTag: 'projects_fab2',
        child: const Icon(Icons.add),
      ),
    );
  }
}
