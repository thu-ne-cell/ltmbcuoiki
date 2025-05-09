import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/task_model.dart';
import '../model/user_model.dart';
import '../providers/task_providers.dart';
import '../providers/task_providers.dart';
import '../providers/user_providers.dart';
import '../screens/edit_taskscreen.dart';
import '../screens/task_detailscreen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  String? _filterStatus;

  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Lấy danh sách công việc theo user (admin xem tất cả)
    taskProvider.fetchTasks(
      userId: userProvider.currentUser?.id,
      isAdmin: userProvider.isAdmin,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String? tempStatus = _filterStatus;
        return AlertDialog(
          title: Text('Lọc theo trạng thái'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: Text('Tất cả'),
                value: null,
                groupValue: tempStatus,
                onChanged: (val) {
                  setState(() {
                    tempStatus = val;
                  });
                },
              ),
              ..._statusOptions.map((status) => RadioListTile<String?>(
                title: Text(status),
                value: status,
                groupValue: tempStatus,
                onChanged: (val) {
                  setState(() {
                    tempStatus = val;
                  });
                },
              )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text('Hủy')),
            TextButton(
                onPressed: () {
                  setState(() {
                    _filterStatus = tempStatus;
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text('Áp dụng')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Lọc và tìm kiếm
    List<Task> tasks = taskProvider.tasks;
    if (_filterStatus != null) {
      tasks = tasks.where((t) => t.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((t) {
        final lowerQuery = _searchQuery.toLowerCase();
        return t.title.toLowerCase().contains(lowerQuery) ||
            t.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách công việc'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc trạng thái',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              taskProvider.fetchTasks(
                  userId: userProvider.currentUser?.id, isAdmin: userProvider.isAdmin);
            },
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
        ),
      ),
      body: tasks.isEmpty
          ? Center(child: Text('Không có công việc nào'))
          : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (ctx, index) {
            final task = tasks[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(task.title),
                subtitle: Text('${task.status} - Ưu tiên: ${_priorityText(task.priority)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!task.completed)
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Đánh dấu hoàn thành',
                        onPressed: () async {
                          final updatedTask = task.copyWith(
                            status: 'Done',
                            completed: true,
                            updatedAt: DateTime.now(),
                          );
                          await taskProvider.updateTask(updatedTask);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Chỉnh sửa',
                      onPressed: () async {
                        // Lấy danh sách user để chuyển giao
                        final userList = await _fetchUserList(context);
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditTaskScreen(
                              task: task,
                              userList: userList,
                              loggedInUser: userProvider.currentUser!,
                            ),
                          ),
                        );
                        if (result != null) {
                          if (result is Map && result['delete'] != null) {
                            await taskProvider.deleteTask(result['delete']);
                          } else if (result is Task) {
                            if (task.id == result.id) {
                              await taskProvider.updateTask(result);
                            } else {
                              await taskProvider.addTask(result);
                            }
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Xóa',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Xác nhận xóa'),
                            content: Text('Bạn có chắc muốn xóa công việc này?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text('Hủy')),
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text('Xóa', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await taskProvider.deleteTask(task.id);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  );
                },
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm công việc mới',
        onPressed: () async {
          final userList = await _fetchUserList(context);
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditTaskScreen(
                userList: userList,
                loggedInUser: userProvider.currentUser!,
              ),
            ),
          );
          if (result != null && result is Task) {
            await taskProvider.addTask(result);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return '';
    }
  }

  Future<List<User>> _fetchUserList(BuildContext context) async {
    // TODO: Lấy danh sách user từ database hoặc provider
    // Ở đây giả định tạm thời trả về danh sách rỗng hoặc user mẫu:
    return [
      User(id: '1', username: 'admin', password: '', email: '', avatar: null, createdAt: DateTime.now(), lastActive: DateTime.now()),
      User(id: '2', username: 'user1', password: '', email: '', avatar: null, createdAt: DateTime.now(), lastActive: DateTime.now()),
      // Thêm người dùng khác...
    ];
  }
}