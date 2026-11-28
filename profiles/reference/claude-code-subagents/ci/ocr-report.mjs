#!/usr/bin/env node
// AES — Summary of an Open Code Review run in CI (standard/05 §7.1), layer L3.
//
// Reads the JSON of `ocr review --format json` and:
//   - prints a GitHub annotation per finding (error: critical/high, warning: medium, notice: low),
//     so they appear on the PR's diff;
//   - writes the Markdown summary (the PR comment and the job summary) to <summary.md>;
//   - prints "critical=<n> high=<n> medium=<n> low=<n>" on its last line.
// The severity is the reviewer model's claim, not a fact: the orchestrator confirms each
// finding and classifies it with 02 §9.3. Only a critical one fails CI (ocr-review.sh decides).
//
// Usage: node ci/ocr-report.mjs <review.json> <summary.md> [<marker>]
import { readFileSync, writeFileSync } from 'node:fs';

const [input, output, marker = '<!-- aes-ocr-review -->'] = process.argv.slice(2);
if (!input || !output) {
  console.error('Usage: node ci/ocr-report.mjs <review.json> <summary.md> [<marker>]');
  process.exit(2);
}

const ORDER = ['critical', 'high', 'medium', 'low', 'unknown'];
const run = JSON.parse(readFileSync(input, 'utf8'));
const comments = Array.isArray(run.comments) ? run.comments : [];
const sev = (c) => (ORDER.includes(String(c.severity).toLowerCase()) ? String(c.severity).toLowerCase() : 'unknown');
const count = Object.fromEntries(ORDER.map((s) => [s, 0]));
for (const c of comments) count[sev(c)]++;

// One-line text for annotations: GitHub cuts them at a newline and needs %, \r and \n escaped.
const esc = (s) => String(s).replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
const level = { critical: 'error', high: 'error', medium: 'warning', low: 'notice', unknown: 'notice' };
for (const c of comments) {
  const s = sev(c);
  const where = c.path ? `file=${c.path}${c.start_line ? `,line=${c.start_line}` : ''}${c.end_line ? `,endLine=${c.end_line}` : ''},` : '';
  console.log(`::${level[s]} ${where}title=OCR ${s}${c.category ? ` (${c.category})` : ''}::${esc(c.content || '')}`);
}

const firstLine = (s) => String(s || '').split('\n')[0].slice(0, 300);
const rows = [...comments]
  .sort((a, b) => ORDER.indexOf(sev(a)) - ORDER.indexOf(sev(b)))
  .map((c, i) => `| R-${i + 1} | ${sev(c)} | ${c.category || ''} | \`${c.path || ''}${c.start_line ? `:${c.start_line}` : ''}\` | ${firstLine(c.content).replace(/\|/g, '\\|')} |`);

const s = run.summary || {};
const lines = [
  marker,
  '### AES · second review (Open Code Review)',
  '',
  `Model: \`${run.llm?.provider ? `${run.llm.provider}/` : ''}${run.llm?.model || '?'}\` · status: \`${run.status || '?'}\` · files reviewed: ${s.files_reviewed ?? 0} · tokens: ${s.total_tokens ?? '?'} · time: ${s.elapsed ?? '?'}`,
  '',
  `**Critical ${count.critical} · High ${count.high} · Medium ${count.medium} · Low ${count.low}**${count.unknown ? ` · no severity ${count.unknown}` : ''}`,
  '',
  'Each finding is the reviewer model\'s claim. The orchestrator confirms it with evidence or discards it with a reason, and classifies it by AES 02 §9.3. A new **critical** one fails CI until it is fixed or the human dismisses it with `aes:review-dismissed`.',
];
if (rows.length) lines.push('', '| ID | Severity | Category | Where | Finding |', '|---|---|---|---|---|', ...rows);
else lines.push('', run.message || 'No findings.');
if (['partial', 'completed_with_errors', 'completed_with_warnings'].includes(run.status) || (Array.isArray(run.warnings) && run.warnings.length)) {
  lines.push('', `Status \`${run.status}\`${run.warnings?.length ? `, ${run.warnings.length} warning(s)` : ''}: part of the diff may not have been reviewed.`);
}
writeFileSync(output, lines.join('\n') + '\n');
console.log(`critical=${count.critical} high=${count.high} medium=${count.medium} low=${count.low}`);
