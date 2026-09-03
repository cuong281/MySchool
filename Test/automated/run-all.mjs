import { spawn } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentDir = dirname(fileURLToPath(import.meta.url));

const suites = [
  ['API', resolve(currentDir, 'api-tests.mjs')],
];

let failed = false;

for (const [name, script] of suites) {
  console.log('');
  console.log(`=== Running ${name} tests ===`);
  const code = await runNode(script);
  if (code !== 0) {
    failed = true;
  }
}

if (failed) {
  process.exitCode = 1;
}

function runNode(script) {
  return new Promise((resolveRun) => {
    const child = spawn(process.execPath, [script], {
      stdio: 'inherit',
      env: process.env,
    });
    child.on('exit', (code) => resolveRun(code ?? 1));
  });
}
