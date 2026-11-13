PANEL CRAFT v2.1 — ULTIMATE PANEL BUILDER TOOL
NETLIFY LICENSING + PHONE BINDING + AUTO-LOADED ONLINE COMPONENT LIBRARY
=========================================================================

PACKAGE CONTENTS
----------------
public/index.html
  Main app. It starts only after the Netlify license function verifies the
  user's signed session.

public/panel-craft-license-admin.html
  Separate administrator dashboard for generating and managing licenses.

public/components_library/
  Public component catalogue, published at the website path /components_library/.
  It is a folder, not a single library file. The app loads it automatically.

public/components_library/manifest.json
  Auto-generated file list. Do not edit manually; npm run build scans the folder.

netlify/functions/panelcraft-license.mjs
  Server-side license validation, phone binding, session signing and admin API.
  This folder is deliberately outside public/ so function source is not exposed.

package.json / netlify.toml
  Netlify dependency and build configuration. Static publish directory is public/;
  functions directory is netlify/functions/.

1. PREPARE THE PUBLIC COMPONENT LIBRARY (AUTOMATIC MANIFEST)
------------------------------------------------------------
A. Put all public component files inside public/components_library/. You can use
   as many nested folders as you need. Supported file types are:
      .fcl  Native Panel Craft FCL1 component file (recommended)
      .flc  Accepted extension alias for the same FCL1 binary format
      .zip  ZIP archive containing compatible .fcl/.flc files

B. You do NOT need to type thousands of filenames into manifest.json. The package
   now includes scripts/generate-library-manifest.mjs. It recursively scans the
   components_library folder, includes all non-empty .fcl/.flc/.zip files, sorts
   paths, and writes public/components_library/manifest.json automatically.

C. Netlify runs this generator on every deployment through `npm run build`. The
   build command is configured in netlify.toml. Keep package.json, netlify.toml,
   scripts/, public/ and netlify/ at the repository root. Do not set the Netlify
   build command to blank. The publish directory remains public/.

D. To test the generator locally from the repository root, run:
      npm run build
   or directly:
      node scripts/generate-library-manifest.mjs
   The terminal reports how many supported files were found. You can open the
   generated public/components_library/manifest.json to inspect the result.

E. After adding, removing or renaming library files, commit and push those changes.
   Netlify rebuilds the manifest automatically. Existing users can click Settings >
   Refresh online library or reload the browser tab. No manual JSON editing is needed.

F. The browser currently accepts up to 20,000 manifest entries and fetches assets
   in small concurrent batches. For very large catalogues, keep folders organized
   and avoid uploading duplicate ZIP archives alongside the same extracted FCL files.

IMPORTANT: The manifest lists files; it does not convert arbitrary formats into
FCL1. Files must be valid compatible .fcl/.flc files or ZIP archives containing
compatible components. Empty files, hidden files/folders, symlinks and unrelated
file types are skipped by the generator. The online library is public/read-only.

2. KEEP PERSONAL IMPORT / CUSTOM COMPONENTS
--------------------------------------------
The existing Settings controls remain available:
  Import library  — select individual .fcl, .flc or .zip files from the computer.
  Import folder   — select a folder containing supported files (Chrome/Edge).
  Connect project folder — connect a local writable folder to read/save its
                          components_library and output folders.

Personal imports are added to the user's local browser library (IndexedDB). Custom
components created in the app can be saved to a connected writable local
components_library folder as .fcl files. If no writable folder is connected, the
custom component stays in that browser's local storage. Personal files are not
uploaded to Netlify and are not visible to other customers automatically.

To publish a component for all customers, add the compatible file under
public/components_library/ and redeploy. The build script automatically adds its
relative path to manifest.json. The public online library is intentionally
read-only in the browser.

3. DEPLOY THE COMPLETE PACKAGE USING GITHUB + NETLIFY
----------------------------------------------------
A. Extract the ZIP to a new folder. Keep the directory structure unchanged.
B. Before uploading, confirm this structure:

   package.json
   netlify.toml
   public/
     index.html
     panel-craft-license-admin.html
     components_library/
       manifest.json
       README.txt
       (your .fcl/.flc/.zip component files)
   netlify/
     functions/
       panelcraft-license.mjs

C. Create a GitHub repository for the production application (private is recommended).
D. Upload/commit the complete extracted folder to the repository root, including
   public/ and netlify/. For many library files, GitHub Desktop is convenient.
E. In Netlify, select Add new project / Import an existing project, choose GitHub,
   authorize Netlify, then select the repository and production branch.
F. Build settings are already in netlify.toml. Confirm these values in Netlify:
      Base directory: leave blank (repository root)
      Build command: npm run build (configured in netlify.toml)
      Publish directory: public
      Functions directory: netlify/functions
   netlify.toml is the source of truth and overrides conflicting UI settings.
G. Start the deploy and confirm it finishes successfully. Netlify installs
   @netlify/blobs from package.json and deploys the server-side licensing function.

Do not deploy only the public/ folder as a static drag-and-drop site. That would
omit the licensing function. Use Git-connected deployment or Netlify CLI so the
function is built and deployed. The function source remains outside the publish
directory as recommended for Netlify functions.

4. ADD THE TWO SERVER ENVIRONMENT SECRETS
-----------------------------------------
Open Netlify > your site > Project configuration > Environment variables. Add
these variables for the production deploy context:

   PANELCRAFT_AUTH_SECRET
   PANELCRAFT_ADMIN_SECRET

Generate two different random values, each at least 32 random bytes. For example,
run this command TWICE in a trusted terminal (use a different output each time):

   openssl rand -base64 48

Paste one result into PANELCRAFT_AUTH_SECRET and the other into
PANELCRAFT_ADMIN_SECRET. Do not use the same value. Do not put either value in
HTML, the admin page, GitHub files, package.json or manifest.json. Set the variables
for Production (and staging/Deploy Preview contexts only if you use them).

Then trigger a fresh deploy: Deploys > Trigger deploy > Deploy site. Environment
variable changes are applied to functions by a new deploy.

5. VERIFY THE PUBLIC LIBRARY AFTER DEPLOYMENT
---------------------------------------------
Replace YOUR-SITE with your Netlify hostname and open:

   https://YOUR-SITE.netlify.app/components_library/manifest.json
   https://YOUR-SITE.netlify.app/components_library/MCB_1P.fcl

The first URL should show the JSON manifest. The second should return the exact
file you added. A 404 means the file was not committed/deployed at that path or
the path/case in manifest.json is incorrect.

Next open https://YOUR-SITE.netlify.app/, activate a valid license, and wait for
the component drawer to populate. Settings should show the hosted library count.
To reload after correcting a file path or publishing an updated catalogue, click
Settings > Refresh online library.

6. LICENSE ADMIN / KEY GENERATOR
--------------------------------
Open:
   https://YOUR-SITE.netlify.app/panel-craft-license-admin.html

The API URL should be:
   /.netlify/functions/panelcraft-license

Enter PANELCRAFT_ADMIN_SECRET and click CONNECT / REFRESH. Generate keys by
entering a customer/user ID, quantity and validity, then click GENERATE & REGISTER.
The server stores records in Netlify Blobs. Key format:
   PC21-CUSTOMERID-XXXXXXXX-XXXXXXXX

The admin page can list/search/copy keys, reset phone binding, revoke/restore/delete
licenses, register an existing key, copy available keys and export CSV. The full
phone number is not returned to the admin page; only its last four digits are shown.

7. CUSTOMER ACTIVATION / PHONE BINDING
--------------------------------------
1. Customer opens the main Panel Craft URL.
2. Customer enters the issued license key and their 10-digit Indian mobile number.
3. First successful activation binds the license to the entered number.
4. Later activations must use the same number. Three mismatches lock the license.
5. If locked, the administrator uses RESET in the License Manager; the customer
   can activate again with the correct bound number.
6. Sessions are signed by the server, expire after 30 days and are rechecked while
   the app is open. Revocation/expiry is applied at the next check.

8. RECOMMENDED RELEASE TEST
---------------------------
Before sending the URL to customers:
  • Check the public manifest and at least one FCL file URL returns successfully.
  • Generate one temporary license in the admin dashboard.
  • Activate it in a fresh browser profile with the intended phone number.
  • Reload and confirm the session verifies and hosted components load.
  • Test Import library with one personal .fcl/.flc file and one ZIP.
  • Create one custom component, save it to a connected local folder, then
    reconnect/import it to verify personal save/import remains available.
  • Revoke the temporary license and confirm the app blocks it on the next check.

9. MAINTAINING THE PUBLIC LIBRARY
--------------------------------
To publish new or updated public components:
  1. Add the .fcl/.flc/.zip asset under public/components_library/.
  2. Commit and push the asset (the manifest is generated during the build).
  3. Let Netlify deploy. Open users can click Refresh online library; new users get
     the latest catalogue on startup.

To remove a public component, delete its file from public/components_library/ and redeploy. The build script removes its path from the generated manifest.
Personal imports already stored by customers remain separate from this public list.

10. SECURITY NOTES
------------------
• Netlify admin/auth secrets must remain server-side and never be committed.
• Phone binding is based on the number the customer enters. This package does not
  send SMS OTP and therefore does not independently verify phone ownership.
• It binds to a phone number, not physical handset identity.
• The app is browser-delivered HTML/JavaScript. Licensing is access control, not
  source-code encryption or absolute DRM.
• The public components_library is intentionally public/read-only. Put only
  components you are permitted to distribute to all licensed customers there.
• Panel Craft's license store is separate from Radilux Shadow Art Generator.
