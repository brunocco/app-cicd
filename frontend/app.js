const taskList = document.getElementById("task-list");
const form = document.getElementById("task-form");
const input = document.getElementById("task-input");

const API_BASE_URL = "http://app-cicd-alb-staging-ACCOUNT_ID.us-east-1.elb.amazonaws.com";
const API_URL = `${API_BASE_URL}/tasks`;

function loadTasks() {
  fetch(API_URL)
    .then(res => res.json())
    .then(tasks => {
      taskList.innerHTML = "";
      tasks.forEach(task => {
        const li = document.createElement("li");
        li.textContent = task.title;
        li.style.textDecoration = task.completed ? "line-through" : "none";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.checked = task.completed;
        checkbox.addEventListener("change", () => toggleTask(task.id, checkbox.checked));

        const delBtn = document.createElement("button");
        delBtn.textContent = "Deletar";
        delBtn.addEventListener("click", () => deleteTask(task.id));

        li.prepend(checkbox);
        li.appendChild(delBtn);
        taskList.appendChild(li);
      });
    });
}

form.addEventListener("submit", e => {
  e.preventDefault();
  const title = input.value.trim();
  if (!title) return;
  fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title })
  })
    .then(() => {
      input.value = "";
      loadTasks();
    });
});

function toggleTask(id, completed) {
  fetch(`${API_URL}/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ completed })
  }).then(() => loadTasks());
}

function deleteTask(id) {
  fetch(`${API_URL}/${id}`, { method: "DELETE" }).then(() => loadTasks());
}

loadTasks();
