#!/usr/bin/env node
// AES — The task graph of an item: what can run now, in parallel, and what waits (standard/04 §5).
//
// Reads specs/<ID>/TASK-*.md (its "**Depends on:**" line) and TASK-*.scope, from the working copy
// or from a ref, and the state of each task in git:
//   merged       its branch task/<ID>/<TASK> was merged into the base (a merge commit names it)
//   in progress  its branch exists (local or origin) and is not merged
//   ready        every dependency is met: start it now
//   waiting      a code dependency is not merged yet
// "Depends on:" accepts none (or —), TASK-NNN (it needs that task's code: it starts after its merge)
// and TASK-NNN (contract) (it only needs the interface contract of the design note: it starts now,
// against the contract, and its PR opens once TASK-NNN is merged and the branch is updated with dev).
//
// It also checks that the tasks that would run at the same time have disjoint surfaces: two
// .scope files that can match the same file must not run in parallel (04 §5). It cannot be
// proved for any two globs, so it is conservative: a shared file, or one glob's fixed prefix
// inside the other's with compatible extensions, counts as an overlap.
//
// Usage: node .claude/scripts/aes-graph.mjs <ID> [--base origin/dev] [--ref <ref>] [--json]
// Exit: 0 = no overlap among the tasks that can run now, 1 = overlap (do not run them in parallel),
//       2 = usage or format error (an unknown task in "Depends on:", a cycle).
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';

const args = process.argv.slice(2);
const id = args.find((a) => !a.startsWith('--') && !['--base', '--ref'].includes(args[args.indexOf(a) - 1]));
const opt = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const base = opt('--base', 'origin/dev');
const ref = opt('--ref', '');
const asJson = args.includes('--json');
if (!id) {
  console.error('Usage: node .claude/scripts/aes-graph.mjs <ID> [--base origin/dev] [--ref <ref>] [--json]');
  process.exit(2);
}

const git = (...a) => {
  try { return execFileSync('git', a, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }); } catch { return ''; }
};
const dir = `specs/${id}`;
const list = ref
  ? git('ls-tree', '--name-only', `${ref}:${dir}`).split('\n').filter(Boolean)
  : existsSync(dir) ? readdirSync(dir) : [];
const read = (f) => (ref ? git('show', `${ref}:${dir}/${f}`) : existsSync(`${dir}/${f}`) ? readFileSync(`${dir}/${f}`, 'utf8') : '');

const tasks = list.filter((f) => /^TASK-\d+\.md$/.test(f)).sort().map((f) => f.replace(/\.md$/, ''));
if (!tasks.length) { console.error(`AES graph: no tasks in ${dir}${ref ? ` at ${ref}` : ''}.`); process.exit(2); }

const parseDeps = (text) => {
  const m = text.match(/^\s*-?\s*\*\*(?:Depends on|Depende de):\*\*\s*(.*)$/mi);
  if (!m || /^\s*(none|ninguna|—|-)?\s*$/i.test(m[1])) return [];
  return [...m[1].matchAll(/(TASK-\d+)\s*(\((?:contract|contrato)\))?/gi)].map((d) => ({ task: d[1].toUpperCase(), contract: !!d[2] }));
};
const scopeOf = (t) => read(`${t}.scope`).split(/\r?\n/).map((l) => l.replace(/#.*/, '').trim()).filter(Boolean);

const merged = new Set(
  tasks.filter((t) => git('log', base, '--merges', '-E', '--format=%s', `--grep=task/${id}/${t}($|[^0-9])`).trim() !== ''),
);
const branches = git('branch', '-a', '--format=%(refname:short)').split('\n');
const started = (t) => branches.some((b) => b === `task/${id}/${t}` || b === `origin/task/${id}/${t}`);

const info = Object.fromEntries(tasks.map((t) => [t, { deps: parseDeps(read(`${t}.md`)), scope: scopeOf(t) }]));
for (const t of tasks) {
  for (const d of info[t].deps) {
    if (!info[d.task]) { console.error(`AES graph: ${t} depends on ${d.task}, which is not a task of ${id}.`); process.exit(2); }
  }
}
// Cycle check (depth-first).
const seen = {}; const visit = (t, path) => {
  if (seen[t] === 1) { console.error(`AES graph: dependency cycle ${[...path, t].join(' → ')}.`); process.exit(2); }
  if (seen[t] === 2) return; seen[t] = 1;
  for (const d of info[t].deps) visit(d.task, [...path, t]);
  seen[t] = 2;
};
tasks.forEach((t) => visit(t, []));

const state = {};
for (const t of tasks) {
  if (merged.has(t)) state[t] = 'merged';
  else if (started(t)) state[t] = 'in progress';
  else if (info[t].deps.every((d) => merged.has(d.task) || d.contract)) state[t] = 'ready';
  else state[t] = 'waiting';
}
const prBlockedBy = (t) => info[t].deps.filter((d) => !merged.has(d.task)).map((d) => d.task);

// Overlap between two scopes (conservative).
const files = git('ls-files').split('\n').filter(Boolean);
const toRe = (g) => new RegExp('^' + g.replace(/[.+^${}()|\\]/g, '\\$&').replace(/\*\*\//g, '\u0001').replace(/\*\*/g, '\u0002')
  .replace(/\*/g, '[^/]*').replace(/\?/g, '[^/]').replace(/\u0001/g, '(.*/)?').replace(/\u0002/g, '.*') + '$');
const prefix = (g) => g.replace(/[*?[].*$/, '');
const ext = (g) => (g.match(/\.([A-Za-z0-9]+)$/) || [])[1] || '';
const globsOverlap = (a, b) => {
  if (a === b) return true;
  const ra = toRe(a), rb = toRe(b);
  if (files.some((f) => ra.test(f) && rb.test(f))) return true;
  if (ra.test(b) || rb.test(a)) return true;
  const pa = prefix(a), pb = prefix(b);
  if (!(pa.startsWith(pb) || pb.startsWith(pa))) return false;
  const ea = ext(a), eb = ext(b);
  return !ea || !eb || ea === eb;
};
const overlaps = (x, y) => {
  const hits = [];
  for (const a of info[x].scope) for (const b of info[y].scope) if (globsOverlap(a, b)) hits.push(`${a} ~ ${b}`);
  return hits;
};

const active = tasks.filter((t) => state[t] === 'ready' || state[t] === 'in progress');
const conflicts = [];
for (let i = 0; i < active.length; i++) {
  for (let j = i + 1; j < active.length; j++) {
    const hits = overlaps(active[i], active[j]);
    if (hits.length) conflicts.push({ a: active[i], b: active[j], hits });
  }
}

if (asJson) {
  console.log(JSON.stringify({ id, base, tasks: tasks.map((t) => ({ task: t, state: state[t], deps: info[t].deps, prWaitsFor: prBlockedBy(t) })), conflicts }, null, 2));
} else {
  console.log(`AES graph of ${id} (base ${base})`);
  for (const t of tasks) {
    const deps = info[t].deps.length ? info[t].deps.map((d) => d.task + (d.contract ? ' (contract)' : '')).join(', ') : 'none';
    const note = (state[t] === 'ready' || state[t] === 'in progress') && prBlockedBy(t).length
      ? ` — its PR opens after ${prBlockedBy(t).join(', ')} merges, updated with ${base.replace(/^origin\//, '')}` : '';
    console.log(`  ${t}  ${state[t].padEnd(11)}  depends on: ${deps}${note}`);
  }
  const ready = tasks.filter((t) => state[t] === 'ready');
  console.log(`Start now: ${ready.length ? ready.join(', ') : '(none)'}`);
  if (conflicts.length) {
    console.log('Overlapping surfaces (they must not run at the same time; narrow the .scope or add a dependency):');
    for (const c of conflicts) console.log(`  ${c.a} / ${c.b}: ${c.hits.join('; ')}`);
  } else if (active.length > 1) {
    console.log(`Disjoint surfaces: ${active.join(', ')} can run in parallel.`);
  }
}
process.exit(conflicts.length ? 1 : 0);
