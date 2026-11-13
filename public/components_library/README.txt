PANEL CRAFT PUBLIC COMPONENT LIBRARY

Copy your compatible .fcl, .flc or .zip component files into this folder.
Nested subfolders are supported.

Do not manually edit manifest.json. The build script recursively scans this folder
and generates manifest.json automatically each time Netlify deploys.

To test locally from the repository root, run: npm run build

Only non-empty .fcl, .flc and .zip files are included. Hidden files, unrelated
file types, empty files and symlinks are skipped.
