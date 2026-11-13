#!/usr/bin/env node
import assert from "node:assert/strict";
import {
  chmodSync,
  existsSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import test from "node:test";

const application = process.env.PI_MANAGER_TEST_PACKAGE;
const templateFile = process.env.PI_MANAGER_TEST_TEMPLATE;
const script = fileURLToPath(
  new URL("./_render-pi-manager.mjs", import.meta.url),
);
const failure = "Pi Manager runtime configuration could not be rendered\n";

test("Rennala runtime owner-policy rendering", async (t) => {
  assert.ok(application?.startsWith("/nix/store/"));
  assert.ok(templateFile?.startsWith("/nix/store/"));
  const template = JSON.parse(readFileSync(templateFile, "utf8"));
  assert.equal(Object.hasOwn(template.browser.identity, "subjects"), false);
  assert.equal(template.core.dispatchEnabled, false);
  const root = mkdtempSync(
    `/run/user/${process.getuid()}/pi-manager-render-test-`,
  );
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const policy = join(root, "policy.json");
  const destination = join(root, "controller.json");
  const fixture = { version: 1, subjects: ["PRIVATE_POLICY_FIXTURE_OWNER"] };
  writeFileSync(policy, JSON.stringify(fixture), { mode: 0o400 });
  const invoke = (base = templateFile, owner = policy, output = destination) =>
    spawnSync(process.execPath, [script, application, base, owner, output], {
      encoding: "utf8",
    });
  const reject = (result) => {
    assert.equal(result.status, 1);
    assert.equal(result.stdout, "");
    assert.equal(result.stderr, failure);
    assert.equal(
      readdirSync(root).some((name) => name.startsWith(".controller-")),
      false,
    );
  };
  await t.test(
    "valid policy yields a canonical owned private configuration",
    () => {
      const result = invoke();
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, "");
      assert.equal(result.stderr, "");
      const info = lstatSync(destination);
      assert.equal(info.uid, process.getuid());
      assert.equal(info.mode & 0o7777, 0o400);
      assert.equal(info.nlink, 1);
      const configuration = JSON.parse(readFileSync(destination, "utf8"));
      assert.deepEqual(
        configuration.browser.identity.subjects,
        fixture.subjects,
      );
      assert.equal(configuration.core.dispatchEnabled, false);
      assert.deepEqual(configuration.desktop, template.desktop);
    },
  );
  await t.test("replacement is atomic and leaves no staging file", () => {
    const previous = lstatSync(destination).ino;
    assert.equal(invoke().status, 0);
    assert.notEqual(lstatSync(destination).ino, previous);
    assert.equal(
      readdirSync(root).some((name) => name.startsWith(".controller-")),
      false,
    );
  });
  await t.test(
    "world-readable policy is refused without replacing valid configuration",
    () => {
      const previous = readFileSync(destination);
      chmodSync(policy, 0o644);
      try {
        reject(invoke());
      } finally {
        chmodSync(policy, 0o400);
      }
      assert.deepEqual(readFileSync(destination), previous);
    },
  );
  await t.test("symlinked policy is refused", () => {
    const link = join(root, "policy-link");
    symlinkSync(policy, link);
    reject(invoke(templateFile, link));
  });
  await t.test("nonprivate output directory is refused", () => {
    const output = join(root, "public", "controller.json");
    mkdirSync(dirname(output), { mode: 0o755 });
    reject(invoke(templateFile, policy, output));
    assert.equal(existsSync(output), false);
  });
  await t.test("unknown policy fields are refused without disclosure", () => {
    const invalid = join(root, "invalid-policy.json");
    writeFileSync(
      invalid,
      JSON.stringify({ ...fixture, secret: "PRIVATE_POLICY_FIXTURE_VALUE" }),
      { mode: 0o400 },
    );
    reject(invoke(templateFile, invalid));
  });
  await t.test("model grants cannot borrow operator-only authority", () => {
    const invalid = structuredClone(template);
    invalid.core.worker.grant.allowedOperations.push("supervisor.status");
    const base = join(root, "operator-grant.json");
    writeFileSync(base, JSON.stringify(invalid), { mode: 0o600 });
    const previous = readFileSync(destination);
    reject(invoke(base));
    assert.deepEqual(readFileSync(destination), previous);
  });
  await t.test("unbound supervisor sources are refused", () => {
    const invalid = structuredClone(template);
    invalid.core.supervisor.sources.unbound = structuredClone(
      invalid.core.supervisor.sources.pwa,
    );
    const base = join(root, "unbound-source.json");
    writeFileSync(base, JSON.stringify(invalid), { mode: 0o600 });
    reject(invoke(base));
  });
});
