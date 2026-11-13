#!/usr/bin/env node
import {
  constants,
  closeSync,
  fsyncSync,
  lstatSync,
  openSync,
  realpathSync,
  renameSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";

// The store owns the deployment template; only agenix supplies the owner policy.
async function render() {
  const [application, templateFile, policyFile, destination] =
    process.argv.slice(2);
  if (
    !application?.startsWith("/nix/store/") ||
    !destination?.startsWith("/run/user/")
  )
    throw new Error();
  const root = `${application}/lib/pi-manager-agent`;
  const { z } = createRequire(`${root}/package.json`)("zod");
  const { readRuntimePrivateJson, readRuntimeJson } = await import(
    pathToFileURL(`${root}/dist/runtime/files.js`)
  );
  const { controllerApplicationConfigSchema } = await import(
    pathToFileURL(`${root}/dist/runtime/application-config.js`)
  );
  const policy = readRuntimePrivateJson(
    policyFile,
    z.strictObject({
      version: z.literal(1),
      subjects:
        controllerApplicationConfigSchema.shape.browser.shape.identity.shape
          .subjects,
    }),
  );
  const template = readRuntimeJson(
    templateFile,
    z.record(z.string(), z.unknown()),
  );
  const configuration = controllerApplicationConfigSchema.parse({
    ...template,
    browser: {
      ...template.browser,
      identity: { ...template.browser.identity, subjects: policy.subjects },
    },
  });
  const parent = dirname(destination),
    info = lstatSync(parent);
  if (
    !info.isDirectory() ||
    info.isSymbolicLink() ||
    realpathSync(parent) !== parent ||
    info.uid !== process.getuid() ||
    (info.mode & 0o7777) !== 0o700
  )
    throw new Error();
  const temporary = join(parent, `.controller-${randomUUID()}.json`);
  let fd;
  try {
    fd = openSync(
      temporary,
      constants.O_WRONLY |
        constants.O_CREAT |
        constants.O_EXCL |
        constants.O_NOFOLLOW,
      0o400,
    );
    writeFileSync(fd, JSON.stringify(configuration));
    fsyncSync(fd);
    closeSync(fd);
    fd = undefined;
    renameSync(temporary, destination);
    const directory = openSync(
      parent,
      constants.O_RDONLY | constants.O_DIRECTORY | constants.O_NOFOLLOW,
    );
    try {
      fsyncSync(directory);
    } finally {
      closeSync(directory);
    }
  } finally {
    if (fd !== undefined) closeSync(fd);
    try {
      unlinkSync(temporary);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
}
render().catch(() => {
  console.error("Pi Manager runtime configuration could not be rendered");
  process.exitCode = 1;
});
