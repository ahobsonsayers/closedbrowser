import { spawn } from "child_process";

export default async function browserHook({ browser, req }) {
  const wsEndpoint = browser.wsEndpoint();
  if (!wsEndpoint) {
    return;
  }

  const sessionId = wsEndpoint.split('/').pop();
  const externalWs = browser.externalWs || browser.config?.getExternalWebSocketAddress?.();
  
  let wsUrl;
  if (externalWs) {
    const url = new URL(externalWs);
    wsUrl = `ws://localhost:${url.port}/devtools/browser/${sessionId}`;
  } else {
    wsUrl = wsEndpoint.replace('0.0.0.0', 'localhost').replace('127.0.0.1', 'localhost');
  }

  await connectToDashboard(wsUrl);

  browser.once("close", async () => {
    await disconnectFromDashboard(wsUrl);
  });
}

function connectToDashboard(wsUrl) {
  return new Promise((resolve) => {
    const proc = spawn("agent-browser", ["connect", wsUrl], {
      detached: true,
      stdio: "ignore",
    });
    proc.unref();
    proc.on("exit", (code) => {
      resolve(code === 0);
    });
    setTimeout(() => resolve(true), 2000);
  });
}

function disconnectFromDashboard(wsUrl) {
  return new Promise((resolve) => {
    const proc = spawn("agent-browser", ["close", wsUrl], {
      detached: true,
      stdio: "ignore",
    });
    proc.unref();
    proc.on("exit", (code) => {
      resolve(code === 0);
    });
    setTimeout(() => resolve(true), 2000);
  });
}