const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    title: { type: String, required: [true, 'Task title is required'], trim: true, maxlength: [120, 'Title cannot exceed 120 characters'] },
    description: { type: String, trim: true, maxlength: [500, 'Description cannot exceed 500 characters'] },
    status: { type: String, enum: ['todo', 'in-progress', 'done'], default: 'todo' },
    priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    dueDate: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Task', taskSchema);
