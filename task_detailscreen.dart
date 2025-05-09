import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/task_model.dart';
// Nếu bạn có model User và provider user, bạn có thể gửi ID assignedTo sang để hiển thị tên người giao

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDateString = task.dueDate != null
        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
        : 'Chưa đặt';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết công việc'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRow('Trạng thái', task.status),
            const SizedBox(height: 8),
            _buildRow('Độ ưu tiên', _priorityText(task.priority)),
            const SizedBox(height: 8),
            _buildRow('Hạn hoàn thành', dueDateString),
            const SizedBox(height: 8),
            _buildRow('Người tạo', task.createdBy),
            const SizedBox(height: 8),
            _buildRow('Người được giao', task.assignedTo ?? 'Chưa giao'),
            const SizedBox(height: 8),
            if (task.category != null && task.category!.isNotEmpty)
              _buildRow('Phân loại', task.category!),
            const SizedBox(height: 16),
            Text(
              'Mô tả:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 16),
            if (task.attachments != null && task.attachments!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tệp đính kèm:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...task.attachments!.map((attachment) => InkWell(
                    onTap: () {
                      // Xử lý mở tệp
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mở tệp: $attachment')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(child: Text(attachment, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        Expanded(child: Text(value)),
      ],
    );
  }
}