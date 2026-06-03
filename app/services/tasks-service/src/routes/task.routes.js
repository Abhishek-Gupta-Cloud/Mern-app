const router = require('express').Router();
const { protect } = require('../middleware/auth.middleware');
const { getTasks, getTask, createTask, updateTask, deleteTask, getStats } = require('../controllers/task.controller');

router.use(protect);

router.route('/').get(getTasks).post(createTask);
router.get('/stats', getStats);
router.route('/:id').get(getTask).patch(updateTask).delete(deleteTask);

module.exports = router;
