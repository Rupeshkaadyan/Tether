# Hosting the privacy policy (free)

Apple requires a **public URL** to your privacy policy before you can submit.
You cannot host it inside the app. Two free options — pick one.

## Before you host: replace the email

Open `docs/privacy.html` and replace **both** occurrences of
`REPLACE_WITH_YOUR_EMAIL` with your real contact address (e.g.
`privacy@yourdomain.com`). There are two: the `mailto:` link and the visible
text. Do the same in `docs/PRIVACY_POLICY.md` if you publish that too.

---

## Option A — GitHub Pages (recommended, permanent)

1. Create a free GitHub account if you don't have one.
2. Create a new **public** repository, e.g. `tether-legal`.
3. Upload `docs/privacy.html` and **rename it to `index.html`**.
4. In the repo: **Settings → Pages → Source → Deploy from branch → `main`
   → folder `/ (root)`** → Save.
5. After a minute your URL is live:
   `https://<your-username>.github.io/tether-legal/`

Optional: buy a domain and point it at GitHub Pages for a nicer URL.

## Option B — Netlify Drop (fastest, ~30 seconds, no account needed)

1. Put `privacy.html` in an empty folder and rename it to `index.html`.
2. Go to **https://app.netlify.com/drop** and drag that folder onto the page.
3. You immediately get a URL like `https://random-name-12345.netlify.app`.
4. (Optional) Rename the site in Netlify settings for a tidier URL.

## Option C — Cloudflare Pages

1. **https://pages.cloudflare.com** → Create a project → Upload assets.
2. Upload the folder containing `index.html` (renamed from `privacy.html`).

---

## Then paste the URL into App Store Connect

1. **App Store Connect → My Apps → Tether → App Information**
2. **Privacy Policy URL** → paste your live URL.
3. Save. Also fill in the **Privacy Policy** field on the App Store tab if
   prompted, and complete the **App Privacy** questionnaire — for Tether the
   honest answer is **"We do not collect data"**, which matches
   `Tether/PrivacyInfo.xcprivacy`.

## Verify before submitting

Open the URL in a browser and confirm:
- it renders,
- the contact email is yours and is clickable,
- the "Last updated" date is current.
