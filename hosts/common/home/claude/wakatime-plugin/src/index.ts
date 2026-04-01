#!/usr/bin/env node

// Adapted from https://github.com/wakatime/claude-code-wakatime
// Copyright (c) 2025 WakaTime, LLC. BSD-3-Clause License.
// Simplified to use system-installed wakatime-cli (via Nix).

import { execFile } from 'child_process';
import { logger, LogLevel } from './logger';
import { Input } from './types';
import { formatArguments, getEntityFiles, parseInput, shouldSendHeartbeat, updateState } from './utils';

const VERSION = '3.1.6';
const WAKATIME_CLI = 'wakatime-cli';

function getDebugSetting(): boolean {
  try {
    const fs = require('fs');
    const os = require('os');
    const path = require('path');
    const home = process.env.WAKATIME_HOME || os.homedir();
    const cfg = fs.readFileSync(path.join(home, '.wakatime.cfg'), 'utf-8');
    return /^\s*debug\s*=\s*true/m.test(cfg);
  } catch {
    return false;
  }
}

async function sendHeartbeat(inp: Input | undefined): Promise<boolean> {
  const projectFolder = inp?.cwd;
  const { entities, claudeVersion } = await getEntityFiles(inp);
  if (entities.size === 0) return false;

  const promises: Promise<void>[] = [];

  for (const [entityFile, entityData] of entities.entries()) {
    logger.debug(`Entity: ${entityFile}`);
    const args: string[] = [
      '--sync-ai-disabled',
      '--entity',
      entityFile,
      '--entity-type',
      entityData.type,
      '--category',
      'ai coding',
      '--plugin',
      `claude/${claudeVersion} claude-code-wakatime/${VERSION}`,
    ];
    if (projectFolder) {
      args.push('--project-folder');
      args.push(projectFolder);
    }

    if (entityData.lineChanges) {
      args.push('--ai-line-changes');
      args.push(entityData.lineChanges.toString());
    }

    logger.debug(`Sending heartbeat: ${formatArguments(WAKATIME_CLI, args)}`);

    promises.push(
      new Promise<void>((resolve) => {
        execFile(WAKATIME_CLI, args, { windowsHide: true }, (error, stdout, stderr) => {
          const output = stdout.toString().trim() + stderr.toString().trim();
          if (output) logger.error(output);
          if (error) logger.error(error.toString());
          resolve();
        });
      }),
    );
  }

  await Promise.all(promises);

  return true;
}

async function main() {
  const inp = parseInput();

  const debug = getDebugSetting();
  logger.setLevel(debug ? LogLevel.DEBUG : LogLevel.INFO);

  try {
    if (inp) logger.debug(JSON.stringify(inp, null, 2));

    if (shouldSendHeartbeat(inp)) {
      if (await sendHeartbeat(inp)) {
        await updateState(inp);
      }
    }
  } catch (err) {
    logger.errorException(err);
  }
}

main();
