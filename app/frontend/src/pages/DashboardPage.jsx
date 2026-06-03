import { useEffect, useState } from "react";
import { getTasks, createTask, updateTask, deleteTask, getStats } from "../services/api";
import { useAuth } from "../context/AuthContext";

const EMPTY_FORM = { title: "", description: "", priority: "medium", dueDate: "" };

export default function DashboardPage() {
  const { user } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState([]);
  const [form, setForm] = useState(EMPTY_FORM);
  const [filter, setFilter] = useState("all");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const fetchAll = async () => {
    try {
      const params = filter !== "all" ? { status: filter } : {};
      const [tRes, sRes] = await Promise.all([getTasks(params), getStats()]);
      setTasks(tRes.data.tasks);
      setStats(sRes.data.stats);
    } catch {
      setError("Failed to load tasks");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAll(); }, [filter]);

  const handle = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const addTask = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) return;
    try {
      await createTask(form);
      setForm(EMPTY_FORM);
      fetchAll();
    } catch (err) {
      setError(err.response?.data?.message || "Failed to create task");
    }
  };

  const toggleStatus = async (task) => {
    const next = task.status === "done" ? "todo" : task.status === "todo" ? "in-progress" : "done";
    await updateTask(task._id, { status: next });
    fetchAll();
  };

  const remove = async (id) => {
    await deleteTask(id);
    fetchAll();
  };

  const count = (s) => stats.find((x) => x._id === s)?.count || 0;

  return (
    <>
      <h2 style={{ marginBottom: "1.5rem" }}>Hello, {user?.name} 👋</h2>

      {/* Stats */}
      <div className="stats">
        <div className="stat"><div className="num">{count("todo")}</div><div className="lbl">To do</div></div>
        <div className="stat"><div className="num" style={{ color: "#d97706" }}>{count("in-progress")}</div><div className="lbl">In progress</div></div>
        <div className="stat"><div className="num" style={{ color: "#16a34a" }}>{count("done")}</div><div className="lbl">Done</div></div>
      </div>

      {/* Add task form */}
      <form className="task-form" onSubmit={addTask}>
        <input
          name="title"
          placeholder="New task title…"
          value={form.title}
          onChange={handle}
          required
        />
        <select name="priority" value={form.priority} onChange={handle}>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>
        <input name="dueDate" type="date" value={form.dueDate} onChange={handle} />
        <button className="btn" type="submit">+ Add</button>
      </form>

      {error && <p className="error">{error}</p>}

      {/* Filter */}
      <div style={{ display: "flex", gap: ".5rem", marginBottom: "1rem" }}>
        {["all", "todo", "in-progress", "done"].map((s) => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            style={{
              padding: ".35rem .85rem",
              borderRadius: "999px",
              border: "1px solid #ddd",
              background: filter === s ? "#2563eb" : "#fff",
              color: filter === s ? "#fff" : "#555",
              cursor: "pointer",
              fontSize: ".8rem",
            }}
          >
            {s}
          </button>
        ))}
      </div>

      {/* Task list */}
      {loading ? (
        <p className="empty">Loading…</p>
      ) : tasks.length === 0 ? (
        <p className="empty">No tasks yet — add one above!</p>
      ) : (
        <div className="task-list">
          {tasks.map((t) => (
            <div className="task-card" key={t._id}>
              <input
                type="checkbox"
                checked={t.status === "done"}
                onChange={() => toggleStatus(t)}
                style={{ cursor: "pointer", width: 16, height: 16 }}
              />
              <span className={`title ${t.status === "done" ? "done" : ""}`}>
                {t.title}
              </span>
              <span className={`badge ${t.status}`}>{t.status}</span>
              <span className={`badge ${t.priority}`}>{t.priority}</span>
              {t.dueDate && (
                <span style={{ fontSize: ".75rem", color: "#aaa" }}>
                  {new Date(t.dueDate).toLocaleDateString()}
                </span>
              )}
              <button className="del" onClick={() => remove(t._id)} title="Delete">✕</button>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
