// Backend API for Task Management - v2.1 Final with /api routes - test
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const { Pool } = require("pg");

const app = express();
app.use(cors());
app.use(bodyParser.json());


const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT),
  ssl: {
    rejectUnauthorized: false
  }
});


// Criar tabela se não existir e só depois iniciar o servidor
(async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        completed BOOLEAN DEFAULT FALSE
      )
    `);
    console.log("Tabela tasks pronta!");

    // Inicia o servidor
    app.listen(3000, () => {
      console.log("Backend rodando na porta 3000");
    });
  } catch (err) {
    console.error("Erro ao iniciar o backend:", err);
    process.exit(1);
  }
})();

// Rotas - Suporte tanto /tasks quanto /api/tasks
const taskRoutes = ["/tasks", "/api/tasks"];

taskRoutes.forEach(route => {
  app.get(route, async (req, res) => {
    const { rows } = await pool.query("SELECT * FROM tasks ORDER BY id ASC");
    res.json(rows);
  });

  app.post(route, async (req, res) => {
    const { title } = req.body;
    const { rows } = await pool.query(
      "INSERT INTO tasks (title) VALUES ($1) RETURNING *",
      [title]
    );
    res.json(rows[0]);
  });
});

const taskIdRoutes = ["/tasks/:id", "/api/tasks/:id"];

taskIdRoutes.forEach(route => {
  app.put(route, async (req, res) => {
    const { id } = req.params;
    const { completed } = req.body;
    const { rows } = await pool.query(
      "UPDATE tasks SET completed = $1 WHERE id = $2 RETURNING *",
      [completed, id]
    );
    res.json(rows[0]);
  });

  app.delete(route, async (req, res) => {
    const { id } = req.params;
    await pool.query("DELETE FROM tasks WHERE id = $1", [id]);
    res.sendStatus(204);
  });
});
