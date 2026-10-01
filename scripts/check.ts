/**
 * `bun scripts/check.ts` validates the frontmatter of every recipe in mockup-stacks/ against the schema prifly's
 * loader uses (apps/desktop-host/src/mockup-stacks/recipe.ts), and that each `fixture` exists inside the extension.
 * Bun only: Bun.YAML parses the frontmatter. Exit 1 on any problem.
 */
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { isAbsolute, join, normalize } from "node:path";
import { existsSync as nodeExists, readFileSync as nodeRead } from "node:fs";
import { join as nodeJoin } from "node:path";

// prifly-extension.json: the manifest prifly reads when the extension is installed.
{
  const manifestPath = nodeJoin(import.meta.dir, "..", "prifly-extension.json");
  const bad: string[] = [];
  try {
    const m = JSON.parse(nodeRead(manifestPath, "utf8")) as Record<string, unknown>;
    if (typeof m.id !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(m.id)) bad.push("id: lower-case words joined by hyphens");
    if (typeof m.name !== "string" || m.name === "") bad.push("name: required text");
    if (typeof m.version !== "string" || m.version === "") bad.push("version: required text");
    if (typeof m.mockupStacks !== "string" || m.mockupStacks === "") bad.push("mockupStacks: required folder name");
    else if (!nodeExists(nodeJoin(import.meta.dir, "..", m.mockupStacks))) bad.push(`mockupStacks: folder ${m.mockupStacks} does not exist`);
  } catch (caught) {
    bad.push(`not readable JSON: ${caught instanceof Error ? caught.message : String(caught)}`);
  }
  if (bad.length > 0) {
    for (const problem of bad) console.log(`FAIL  prifly-extension.json: ${problem}`);
    process.exit(1);
  }
}


const dir = join(import.meta.dir, "..", "mockup-stacks");
const FRONT = /^﻿?---[ \t]*\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/;
const DATE = /^\d{4}-\d{2}-\d{2}$/;
const KEYS = new Set([
  "id", "name", "aliases", "detect", "route", "verified", "versions", "fixture",
  "priority", "kind", "where", "toolchain", "renderedBy", "verifiedBy",
]);

function textLike(value: unknown): boolean {
  return (typeof value === "string" && value !== "") || typeof value === "number";
}

function names(value: unknown, what: string, errors: string[]): void {
  if (value === undefined) return;
  if (!Array.isArray(value) || !value.every((item) => textLike(item))) {
    errors.push(`${what}: a list of non-empty names`);
  }
}

function problemsOf(file: string, text: string): string[] {
  const match = FRONT.exec(text);
  if (match === null) return ["no frontmatter block (--- ... --- at the top)"];
  const raw: unknown = Bun.YAML.parse(match[1] ?? "");
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
    return ["frontmatter is not a mapping of keys to values"];
  }
  const meta = raw as Record<string, unknown>;
  const errors: string[] = [];
  for (const key of Object.keys(meta)) if (!KEYS.has(key)) errors.push(`${key}: unknown key (the loader drops it)`);
  const id = meta["id"];
  if (typeof id !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(id)) errors.push("id: lower-case words joined by hyphens");
  else if (`${id}.md` !== file) errors.push(`id: ${id} does not match the file name ${file}`);
  if (!textLike(meta["name"])) errors.push("name: required");
  if (!textLike(meta["route"])) errors.push("route: required");
  if (!DATE.test(String(meta["verified"] ?? ""))) errors.push("verified: a date, YYYY-MM-DD");
  names(meta["aliases"], "aliases", errors);
  names(meta["renderedBy"], "renderedBy", errors);
  const detect = meta["detect"];
  if (detect !== undefined) {
    if (typeof detect !== "object" || detect === null || Array.isArray(detect)) errors.push("detect: a mapping");
    else for (const part of ["deps", "files", "globs"]) names((detect as Record<string, unknown>)[part], `detect.${part}`, errors);
  }
  const fixture = meta["fixture"];
  if (fixture !== undefined) {
    if (!textLike(fixture) || isAbsolute(String(fixture)) || normalize(String(fixture)).startsWith("..")) {
      errors.push("fixture: a path inside the recipe's folder");
    } else if (!existsSync(join(dir, String(fixture)))) errors.push(`fixture: ${fixture} does not exist`);
  }
  if (meta["priority"] !== undefined && !Number.isInteger(meta["priority"])) errors.push("priority: an integer");
  for (const heading of ["## Steps", "## Gotchas", "## States"]) {
    if (!text.includes(`\n${heading}\n`)) errors.push(`body: missing ${heading}`);
  }
  if (/\/(home|Users)\/[a-z]/i.test(text)) errors.push("body: contains a personal absolute path");
  return errors;
}

let bad = 0;
const files = readdirSync(dir).filter((name) => name.endsWith(".md"));
for (const file of files) {
  const errors = problemsOf(file, readFileSync(join(dir, file), "utf8"));
  for (const error of errors) console.log(`FAIL  ${file}: ${error}`);
  bad += errors.length;
}
console.log(`${files.length} recipe(s) checked, ${bad} problem(s)`);
process.exit(bad > 0 || files.length === 0 ? 1 : 0);
