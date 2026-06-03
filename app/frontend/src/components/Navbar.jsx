import { useAuth } from "../context/AuthContext";

export default function Navbar() {
  const { user, logout } = useAuth();
  return (
    <nav>
      <span className="brand">⚡ MERN Tasks</span>
      <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
        <span style={{ fontSize: ".85rem", color: "#555" }}>
          {user?.name}
        </span>
        <button onClick={logout}>Logout</button>
      </div>
    </nav>
  );
}
