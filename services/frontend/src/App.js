import React, { useEffect, useState } from "react";
import axios from "axios";

const apiBaseUrl = process.env.REACT_APP_API_BASE_URL || "/api";
const appTitle = "Yasn Ticket System";

function App() {
  const [tickets, setTickets] = useState([]);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [token, setToken] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchTickets = async () => {
    if (!token) return;
    setLoading(true);
    setError("");
    try {
      const resp = await axios.get(`${apiBaseUrl}/tickets`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      setTickets(resp.data);
    } catch (err) {
      setError("Failed to load tickets");
    } finally {
      setLoading(false);
    }
  };

  const createTicket = async (e) => {
    e.preventDefault();
    if (!token) {
      setError("Missing token");
      return;
    }
    setLoading(true);
    setError("");
    try {
      await axios.post(
        `${apiBaseUrl}/tickets`,
        { title, description },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );
      setTitle("");
      setDescription("");
      await fetchTickets();
    } catch (err) {
      setError("Failed to create ticket");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (token) {
      fetchTickets();
    }
  }, [token]);

  return (
    <div style={{ maxWidth: "800px", margin: "0 auto", padding: "1rem" }}>
      <h1>{appTitle}</h1>

      <section>
        <h2>Auth token</h2>
        <p>
          Paste a Cognito access token here for now,
          later this will be replaced with a proper login flow.
        </p>
        <input
          style={{ width: "100%", padding: "0.5rem" }}
          type="text"
          placeholder="Cognito access token"
          value={token}
          onChange={(e) => setToken(e.target.value)}
        />
      </section>

      <section>
        <h2>Create ticket</h2>
        <form onSubmit={createTicket}>
          <div>
            <input
              style={{ width: "100%", padding: "0.5rem", marginBottom: "0.5rem" }}
              type="text"
              placeholder="Title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>
          <div>
            <textarea
              style={{ width: "100%", padding: "0.5rem", marginBottom: "0.5rem" }}
              placeholder="Description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>
          <button type="submit" disabled={loading}>
            Create
          </button>
        </form>
      </section>

      <section>
        <h2>Tickets</h2>
        {loading && <p>Loading...</p>}
        {error && <p style={{ color: "red" }}>{error}</p>}
        {!loading && !error && tickets.length === 0 && <p>No tickets yet.</p>}
        <ul>
          {tickets.map((t) => (
            <li key={t.id}>
              <strong>{t.title}</strong> ({t.status}) by {t.created_by}
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}

export default App;
