const express = require('express');
const { Worker, isMainThread, workerData } = require('worker_threads');
const os = require('os');
const app = express();
const PORT = process.env.PORT || 3000;

// Inline worker code — each worker busy-loops for the given duration
const WORKER_CODE = `
const { workerData } = require('worker_threads');
const end = Date.now() + workerData.durationMs;
while (Date.now() < end) { Math.sqrt(Math.random() * 1e12); }
`;

function stressCores(durationMs) {
  const numCores = os.cpus().length;
  return new Promise((resolve) => {
    let done = 0;
    for (let i = 0; i < numCores; i++) {
      const worker = new Worker(WORKER_CODE, {
        eval: true,
        workerData: { durationMs }
      });
      worker.on('exit', () => {
        if (++done === numCores) resolve(numCores);
      });
    }
  });
}

// Home page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title>Lab 4 - Hello World</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 60px auto; text-align: center; }
        h1 { color: #0078d4; }
        a.btn {
          display: inline-block; margin-top: 20px; padding: 12px 24px;
          background: #d9534f; color: white; text-decoration: none;
          border-radius: 4px; font-size: 1rem;
        }
        a.btn:hover { background: #c9302c; }
        p.note { color: #666; font-size: 0.9rem; margin-top: 10px; }
      </style>
    </head>
    <body>
      <h1>Hello World!</h1>
      <p>Azure Web App is running. Deployed via GitHub Actions CI/CD.</p>
      <a class="btn" href="/cpu-stress">Trigger CPU Stress</a>
      <p class="note">Click repeatedly to spike CPU and trigger the Azure Monitor alert.</p>
    </body>
    </html>
  `);
});

// CPU stress endpoint — spawns one worker thread per CPU core for ~5 seconds
app.get('/cpu-stress', async (req, res) => {
  const durationMs = 5000;
  const numCores = await stressCores(durationMs);

  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <title>CPU Stress Done</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 60px auto; text-align: center; }
        h1 { color: #d9534f; }
        a.btn {
          display: inline-block; margin-top: 20px; padding: 12px 24px;
          background: #0078d4; color: white; text-decoration: none;
          border-radius: 4px; font-size: 1rem;
        }
      </style>
    </head>
    <body>
      <h1>CPU Stress Complete</h1>
      <p>Pinned <strong>${numCores} core(s)</strong> at 100% for 5 seconds.</p>
      <p>Reload this page or click below to stress again.</p>
      <a class="btn" href="/cpu-stress">Stress Again</a>
      &nbsp;
      <a class="btn" style="background:#0078d4" href="/">Home</a>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
