# Panel Craft — local-first development and iPhone testing

Use this workflow while making changes. It runs the app and Netlify Functions on your own computer. It does **not** publish a production deployment to Netlify.

## Requirements

- Windows 10/11
- Node.js 22.12 or newer
- npm (installed with Node.js)
- The project folder, including `public/components_library`
- For iPhone PWA testing: Cloudflare `cloudflared.exe`

## 1. Start the local development server

1. Download the ZIP for the `local-testing` branch from GitHub and extract it.
2. Open the extracted project folder.
3. Open Command Prompt in that folder.
4. Run:

```bat
npm install
npm run dev:build
```

The build step regenerates `public/components_library/manifest.json`. Netlify Dev then starts the static site and the local Functions proxy on port 8888.

Open this address on the laptop:

```
http://localhost:8888
```

Do not use `file://` to open `index.html`. The app needs the local server for the service worker and Functions.

## 2. Local test login

On localhost, private LAN IP addresses, and the temporary Cloudflare test address, Panel Craft selects the isolated local mock-license function.

Use only these dummy credentials:

- License key: `PC21-LOCAL-TEST`
- Phone: `9999999999`

This local mock does not contact Netlify Blobs, create a customer license, bind a real phone, lock a real license, or change production licensing records.

The mock endpoint rejects public production hostnames. Do not add real customer information or customer project files to a temporary test tunnel.

## 3. Test on the iPhone over HTTPS

A plain LAN address such as `http://192.168.x.x` is useful for checking basic layout and touch behavior, but it is not a secure origin for service workers and PWA notifications. Use the temporary HTTPS tunnel for the full iPhone/PWA test.

1. Download the Windows 64-bit `cloudflared` executable from Cloudflare's official downloads page and put `cloudflared.exe` in the project folder (or add it to PATH).
2. Keep the local Panel Craft server running in Command Prompt window 1.
3. Open a second Command Prompt window in the same project folder and run:

```bat
cloudflared tunnel --url http://localhost:8888
```

4. Cloudflare prints a temporary HTTPS address ending in `trycloudflare.com`. Open that exact address on the iPhone.
5. Sign in with the local test key and phone above.
6. To test installation, open the address in Safari, tap Share, choose **Add to Home Screen**, and launch the installed icon.
7. Test touch gestures, double-tap component actions, Undo/Redo, offline shell behavior, and the local notification permission/test message.

The Quick Tunnel is temporary and public to anyone who has its URL. Do not share it. Stop it with Ctrl+C when finished. The address changes when you start a new tunnel.

## 4. Normal development cycle

- Edit files in the extracted local project folder.
- Keep `npm run dev` running and refresh the local browser to test changes.
- Re-run `npm run build` after changing component library files or the manifest generator.
- Re-test on the iPhone through the HTTPS tunnel.
- Only after the changes are accepted should they be merged into `main` and published to the production Netlify site.

A Git push to the production-connected `main` branch can trigger a production deploy. Local editing and `netlify dev` do not publish a production deployment. Keep experimental work on `local-testing` until it is approved.

## Notes

- Local browser data (IndexedDB, project autosave, local login token, and service-worker cache) is kept per origin and per browser. The laptop's localhost data and the iPhone's temporary tunnel origin are separate.
- The current notification button tests permission and local notification display. Remote push delivery still needs a push subscription store and a server-side sender.
- Netlify CLI emulates the Netlify development environment, including Functions. Some production-only services or environment values may still need their own local configuration; the mock login deliberately avoids the production Blobs license registry.
