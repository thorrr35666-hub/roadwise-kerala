# RoadWise Kerala — Expo + Supabase starter

A cross-platform React Native starter continuing the HTML prototype. It includes:
- Native responsive app UI for Android and iOS via Expo
- Signs and markings library with search and category filters
- Learning quiz
- Supabase email sign-up/sign-in
- Photo selection and GPS capture for road defect reports
- Supabase database and private photo storage schema with RLS
- Starter SQL seed content
- Demo library fallback if Supabase isn't configured

## Important: current implementation status
This is a **starter codebase**, not a deployed production service. The backend must be created and configured in your own accounts. Admin content management screens, review workflow, push notifications, full automated tests, app-store submission, and formal verification of all technical sign dimensions still need implementation before public release. Never treat the starter content as an authoritative engineering design.

## Easiest cloud setup (GitHub Codespaces)
1. Create a GitHub account if needed.
2. Create a new empty repository named `roadwise-kerala`.
3. Upload/extract this project into the repository and commit it.
4. On GitHub, click **Code → Codespaces → Create codespace on main**.
5. In the Codespaces terminal run:
   ```bash
   npm install
   npx expo start --tunnel
   ```
6. Install **Expo Go** on your Android phone and scan the QR code. For iOS, install Expo Go where available and scan the QR code with the camera. A cloud tunnel is usually the easiest route through Codespaces networking.
7. When you change code, Expo reloads the app.

## Create Supabase backend
1. Open https://supabase.com/dashboard and create a new project. Choose a region near your users (for Kerala, a suitable Asia-Pacific region is usually preferable); the project region cannot be changed later.
2. Wait for the database to finish provisioning.
3. Open **SQL Editor → New query**.
4. Paste and run `supabase/migrations/0001_roadwise.sql`.
5. Open **Project Connect / API Keys** and copy the Project URL and publishable key.
6. In Codespaces create `.env` from `.env.example`, then set:
   ```env
   EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```
7. Restart Expo after setting variables: stop it with Ctrl+C, then run `npx expo start --tunnel`.
8. In Supabase **Authentication → Providers**, configure Email. Decide whether email confirmation is required and configure your allowed redirect URLs before public launch.
9. Create your first account in the app. To grant admin access, use the Supabase SQL Editor while signed in as the project owner, replacing the email:
   ```sql
   update public.profiles
   set role = 'admin'
   where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL');
   ```
   Only trusted project owners should run this. Never allow normal users to set their own role.
10. Check **Authentication**, **Table Editor**, **Storage**, and **Logs** in Supabase to verify records and upload permissions.

## Production safeguards before launch
- Use the publishable key only in the client; never embed a Supabase secret/service-role key in the app.
- Review RLS policies with test accounts for anonymous, regular-user, and admin access.
- Add admin UI for creating/updating/publishing content and moderating reports.
- Use secure signed URLs for private photos; do not make the report photo bucket public.
- Add privacy policy, location/photo consent, data retention/deletion, rate limiting and abuse reporting.
- Test Android and iOS permissions, network failures, upload limits, accessibility and offline states.
- Verify current IRC editions/amendments and applicable MoRTH/Kerala PWD guidance before publishing dimensions or placement rules.

## Build installable binaries
For development, Expo Go is enough for this starter. For release builds, configure an Expo account and EAS:
```bash
npm install -g eas-cli
eas login
eas build:configure
eas build --platform android
eas build --platform ios
```
An Apple Developer account is required for normal iOS App Store distribution. Follow current Expo EAS and store requirements.


## Uploaded IRC reference documents
This project has been aligned to the following user-supplied reference PDFs:
- `IRC:35-2015`, Code of Practice for Road Markings, Second Revision. Use its classification of longitudinal, transverse, hazard, block, arrow, directional and facility markings; relevant application sections; and Sections 15–16 for performance assessment, inspection, defect categories, maintenance and records.
- `IRC:67-2001`, Code of Practice for Road Signs. This is the edition in the supplied PDF. Do not describe it as current without checking applicable current IRC publications/amendments.

The in-app **IRC reference desk** summarises the scope of these supplied documents. Exact dimensions, placement rules, and acceptance/defect thresholds must be verified clause-by-clause against the current applicable standards before the app treats them as authoritative. The app should not reproduce the full copyrighted standards; store original educational summaries and cite clause/table references as appropriate.
