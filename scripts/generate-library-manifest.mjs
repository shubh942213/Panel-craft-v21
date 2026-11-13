#!/usr/bin/env node
/**
 * Recursively generate the Panel Craft public component-library manifest.
 * Scans public/components_library and includes only .fcl, .flc and .zip files.
 * Run automatically during Netlify builds with: npm run build
 */
import { readdir, writeFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const libraryRoot = path.join(projectRoot, 'public', 'components_library');
const manifestPath = path.join(libraryRoot, 'manifest.json');
const allowed = new Set(['.fcl', '.flc', '.zip']);
const ignoredDirectoryNames = new Set(['.git', '.github', 'node_modules', '__macosx']);

async function walk(dir, relative = '') {
  const entries = await readdir(dir, { withFileTypes: true });
  entries.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));
  const files = [];
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    if (entry.isSymbolicLink()) continue;
    const rel = relative ? `${relative}/${entry.name}` : entry.name;
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (ignoredDirectoryNames.has(entry.name.toLowerCase())) continue;
      files.push(...await walk(absolute, rel));
    } else if (entry.isFile() && allowed.has(path.extname(entry.name).toLowerCase())) {
      const info = await stat(absolute);
      if (info.size > 0) files.push(rel.split(path.sep).join('/'));
    }
  }
  return files;
}

try {
  const files = (await walk(libraryRoot)).sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));
  const manifest = {
    version: 1,
    generatedBy: 'Panel Craft build',
    totalFiles: files.length,
    files
  };
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log(`[Panel Craft] Generated components_library/manifest.json with ${files.length} supported file(s).`);
  if (!files.length) console.warn('[Panel Craft] No .fcl, .flc or .zip files found. The public library will be empty.');
} catch (error) {
  console.error('[Panel Craft] Could not generate component-library manifest:', error);
  process.exitCode = 1;
}
