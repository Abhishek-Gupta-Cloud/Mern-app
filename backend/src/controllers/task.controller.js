const Task = require("../models/Task.model");

// GET /api/tasks
exports.getTasks = async (req, res) => {
  const { status, priority, page = 1, limit = 20 } = req.query;
  const filter = { user: req.user.id };
  if (status) filter.status = status;
  if (priority) filter.priority = priority;

  const tasks = await Task.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(Number(limit));

  const total = await Task.countDocuments(filter);
  res.json({ tasks, total, page: Number(page) });
};

// GET /api/tasks/:id
exports.getTask = async (req, res) => {
  const task = await Task.findOne({ _id: req.params.id, user: req.user.id });
  if (!task) return res.status(404).json({ message: "Task not found" });
  res.json({ task });
};

// POST /api/tasks
exports.createTask = async (req, res) => {
  const task = await Task.create({ ...req.body, user: req.user.id });
  res.status(201).json({ task });
};

// PATCH /api/tasks/:id
exports.updateTask = async (req, res) => {
  const task = await Task.findOneAndUpdate(
    { _id: req.params.id, user: req.user.id },
    req.body,
    { new: true, runValidators: true }
  );
  if (!task) return res.status(404).json({ message: "Task not found" });
  res.json({ task });
};

// DELETE /api/tasks/:id
exports.deleteTask = async (req, res) => {
  const task = await Task.findOneAndDelete({
    _id: req.params.id,
    user: req.user.id,
  });
  if (!task) return res.status(404).json({ message: "Task not found" });
  res.json({ message: "Task deleted" });
};

// GET /api/tasks/stats
exports.getStats = async (req, res) => {
  const stats = await Task.aggregate([
    { $match: { user: req.user._id } },
    { $group: { _id: "$status", count: { $sum: 1 } } },
  ]);
  res.json({ stats });
};
