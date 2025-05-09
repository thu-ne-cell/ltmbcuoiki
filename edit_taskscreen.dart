import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:file_picker/file_picker.dart";

import '../model/task_model.dart';
import '../model/user_model.dart';

class EditTaskScreen extends StatefulWidget {
  final Task? task; // Nếu null là tạo mới
  final List<User> userList; // Danh sách người dùng để chọn giao việc
  final User loggedInUser; // Người dùng đang đăng nhập

  EditTaskScreen({
    Key? key,
    this.task,
    required this.userList,
    required this.loggedInUser,
  }) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  late String _status;
  late int _priority;
  DateTime? _dueDate;
  String? _category;
  List<String> _attachments = [];
  String? _assignedTo;

  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _title = widget.task!.title;
      _description = widget.task!.description;
      _status = widget.task!.status;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _category = widget.task!.category;
      _attachments = widget.task!.attachments != null ? List.from(widget.task!.attachments!) : [];
      _assignedTo = widget.task!.assignedTo;
    } else {
      _title = '';
      _description = '';
      _status = _statusOptions[0];
      _priority = 2; // mặc định Trung bình
      _dueDate = null;
      _category = '';
      _attachments = [];
      _assignedTo = widget.loggedInUser.id; // default assigned cho chính mình
    }
  }

  Future<void> _pickDueDate() async {
    DateTime initialDate = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _attachments.addAll(result.files.map((f) => f.path ?? '').where((p) => p.isNotEmpty));
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newTask = Task(
        id: widget.task?.id ?? UniqueKey().toString(),
        title: _title,
        description: _description,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: _assignedTo,
        createdBy: widget.task?.createdBy ?? widget.loggedInUser.id,
        category: _category != '' ? _category : null,
        attachments: _attachments.isNotEmpty ? _attachments : null,
        completed: _status == 'Done',
      );

      Navigator.of(context).pop(newTask);
    }
  }

  void _deleteTask() {
    // Trả về một giá trị để màn hình cha biết xoá
    if (widget.task != null) {
      Navigator.of(context).pop({'delete': widget.task!.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.loggedInUser.username == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc' : 'Chỉnh sửa công việc'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: Text('Xác nhận'),
                        content: Text('Bạn có muốn xóa công việc này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _deleteTask();
                            },
                            child: Text('Xóa', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    });
              },
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tiêu đề
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Tiêu đề *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Trường này bắt buộc';
                  return null;
                },
                onSaved: (value) => _title = value!.trim(),
              ),
              SizedBox(height: 12),

              // Mô tả
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              SizedBox(height: 12),

              // Trạng thái
              DropdownButtonFormField<String>(
                value: _status,
                items: _statusOptions
                    .map((st) =>
                    DropdownMenuItem(
                      value: st,
                      child: Text(st),
                    ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _status = v;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Trạng thái *'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Trường này bắt buộc' : null,
              ),
              SizedBox(height: 12),

              // Độ ưu tiên
              DropdownButtonFormField<int>(
                value: _priority,
                items: _priorityOptions
                    .map((p) =>
                    DropdownMenuItem(
                      value: p,
                      child: Text(p == 1 ? 'Thấp' : (p == 2 ? 'Trung bình' : 'Cao')),
                    ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _priority = v;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Độ ưu tiên *'),
                validator: (value) => value == null ? 'Trường này bắt buộc' : null,
              ),
              SizedBox(height: 12),

              // Hạn hoàn thành
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate != null
                          ? 'Hạn hoàn thành: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}'
                          : 'Chưa chọn hạn hoàn thành',
                    ),
                  ),
                  TextButton(
                    child: Text('Chọn ngày'),
                    onPressed: _pickDueDate,
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Phân loại
              TextFormField(
                initialValue: _category,
                decoration: InputDecoration(labelText: 'Phân loại'),
                onSaved: (value) => _category = value,
              ),
              SizedBox(height: 12),

              // Người được giao
              DropdownButtonFormField<String>(
                value: _assignedTo,
                items: widget.userList.map((user) {
                  // Admin có thể chọn bất kỳ user, user thường chỉ chọn chính mình
                  if (isAdmin || user.id == widget.loggedInUser.id) {
                    return DropdownMenuItem(
                      value: user.id,
                      child: Text(user.username),
                    );
                  }
                  return null;
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _assignedTo = v;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Người được giao *'),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      (!isAdmin && value != widget.loggedInUser.id)) {
                    return 'Bạn chỉ có thể giao cho chính mình.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              // Tệp đính kèm
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tệp đính kèm'),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.attach_file),
                    label: Text('Thêm tệp'),
                    onPressed: _pickAttachments,
                  ),
                  SizedBox(height: 8),
                  ..._attachments.asMap().entries.map(
                        (entry) => ListTile(
                      title: Text(entry.value.split('/').last),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeAttachment(entry.key),
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Hủy
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Hủy'),
                  ),
                  // Lưu
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: Text('Lưu'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
