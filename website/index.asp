<%
Response.CodePage = 65001
Response.Charset = "UTF-8"
Response.CacheControl = "no-cache"
Response.AddHeader "Cache-Control", "no-cache, no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"
Response.Expires = -1
%><!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">
  <meta name="description" content="DozeAlert wakes you before you reach your destination. On Google Play for Android, iPhone TestFlight beta, Wear OS, and Apple Watch. Sleep peacefully. Arrive confidently.">
  <meta name="theme-color" content="#0D1B2A">
  <title>DozeAlert &mdash; Sleep peacefully. Arrive confidently.</title>
  <link rel="icon" type="image/png" href="assets/icon-512.png?v=77">
  <link rel="stylesheet" href="assets/brand.css?v=77">
  <style>
    :root {
      --midnight: #0D1B2A;
      --midnight-light: #152536;
      --cyan: #4CC9F0;
      --cyan-dim: #3aa8cc;
      --white: #FFFFFF;
      --muted: #94a3b8;
      --card: #1B3147;
      --radius: 16px;
      --max-width: 720px;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: var(--midnight);
      color: var(--white);
      line-height: 1.6;
      min-height: 100vh;
    }

    .glow {
      position: fixed;
      inset: 0;
      pointer-events: none;
      background:
        radial-gradient(ellipse 80% 50% at 50% -20%, rgba(76, 201, 240, 0.18), transparent),
        radial-gradient(ellipse 60% 40% at 100% 100%, rgba(76, 201, 240, 0.08), transparent);
      z-index: 0;
    }

    .wrap {
      position: relative;
      z-index: 1;
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 2.5rem 1.25rem 4rem;
    }

    header {
      text-align: center;
      margin-bottom: 2.5rem;
    }

    .logo {
      height: 120px;
      width: auto;
      max-width: 100%;
      border-radius: 0;
      box-shadow: none;
      margin-bottom: 1.25rem;
    }

    h1 {
      font-size: 2rem;
      font-weight: 700;
      letter-spacing: -0.02em;
      margin-bottom: 0.35rem;
    }

    .tagline {
      font-size: 1.125rem;
      color: var(--cyan);
      font-weight: 500;
    }

    .card {
      background: var(--card);
      border: 1px solid rgba(76, 201, 240, 0.12);
      border-radius: var(--radius);
      padding: 1.5rem;
      margin-bottom: 1.25rem;
    }

    .card h2 {
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
      color: var(--cyan);
    }

    .card p,
    .card li {
      color: #cbd5e1;
      font-size: 0.95rem;
    }

    .card ul {
      padding-left: 1.25rem;
      margin-top: 0.5rem;
    }

    .card li + li {
      margin-top: 0.35rem;
    }

    .download-block {
      text-align: center;
      padding: 2rem 1.5rem;
    }

    .download-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.6rem;
      background: var(--cyan);
      color: var(--midnight) !important;
      font-size: 1.0625rem;
      font-weight: 700;
      text-decoration: none;
      padding: 1rem 2rem;
      border-radius: 999px;
      transition: background 0.15s, transform 0.15s, color 0.15s;
      box-shadow: 0 4px 20px rgba(76, 201, 240, 0.35);
    }

    .download-btn:hover {
      background: var(--cyan-dim);
      color: var(--midnight) !important;
      transform: translateY(-1px);
    }

    .download-btn svg {
      width: 22px;
      height: 22px;
      flex-shrink: 0;
    }

    .download-btn-secondary {
      background: transparent;
      color: var(--cyan) !important;
      border: 2px solid rgba(76, 201, 240, 0.55);
      box-shadow: none;
    }

    .download-btn-secondary:hover {
      background: rgba(76, 201, 240, 0.1);
      color: var(--white) !important;
    }

    .download-grid {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.75rem;
    }

    .play-badge {
      display: inline-block;
      line-height: 0;
      transition: transform 0.15s, opacity 0.15s;
    }

    .play-badge:hover {
      transform: translateY(-1px);
      opacity: 0.92;
    }

    .play-badge img {
      display: block;
      height: 80px;
      width: auto;
    }

    .watch-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 1rem;
      margin-top: 1rem;
    }

    @media (min-width: 600px) {
      .watch-grid {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }
    }

    .watch-card {
      text-align: center;
    }

    .watch-shot {
      width: 140px;
      height: 140px;
      max-width: 140px;
      aspect-ratio: 1 / 1;
      object-fit: cover;
      object-position: center center;
      margin: 0 auto 0.5rem;
      border-radius: 50%;
      border: 2px solid rgba(76, 201, 240, 0.2);
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.4);
      display: block;
      flex-shrink: 0;
    }

    .watch-card figcaption {
      font-size: 0.8125rem;
      color: var(--muted);
      line-height: 1.35;
    }

    .watch-card strong {
      display: block;
      color: var(--white);
      margin-bottom: 0.15rem;
    }

    .apple-watch-shot {
      width: 120px;
      height: auto;
      max-width: 120px;
      aspect-ratio: 416 / 496;
      object-fit: cover;
      object-position: center top;
      margin: 0 auto 0.5rem;
      border-radius: 1.35rem;
      border: 2px solid rgba(76, 201, 240, 0.2);
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.4);
      display: block;
      flex-shrink: 0;
      background: #000;
    }

    @media (min-width: 600px) {
      .apple-watch-shot {
        width: 140px;
        max-width: 140px;
      }
    }

    .meta {
      margin-top: 1rem;
      font-size: 0.8125rem;
      color: var(--muted);
    }

    .meta code {
      background: rgba(0, 0, 0, 0.25);
      padding: 0.15rem 0.4rem;
      border-radius: 4px;
      font-size: 0.75rem;
    }

    .steps {
      counter-reset: step;
      list-style: none;
      padding-left: 0;
    }

    .steps li {
      counter-increment: step;
      position: relative;
      padding-left: 2.5rem;
      margin-bottom: 1rem;
    }

    .steps li::before {
      content: counter(step);
      position: absolute;
      left: 0;
      top: 0.1rem;
      width: 1.75rem;
      height: 1.75rem;
      background: rgba(76, 201, 240, 0.15);
      color: var(--cyan);
      border-radius: 50%;
      font-size: 0.875rem;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .note {
      background: rgba(76, 201, 240, 0.08);
      border-left: 3px solid var(--cyan);
      padding: 0.875rem 1rem;
      border-radius: 0 8px 8px 0;
      margin-top: 1rem;
      font-size: 0.875rem;
      color: #cbd5e1;
    }

    .note strong {
      color: var(--white);
    }

    details {
      margin-top: 0.75rem;
    }

    summary {
      cursor: pointer;
      color: var(--cyan);
      font-weight: 500;
      font-size: 0.9rem;
      user-select: none;
    }

    details[open] summary {
      margin-bottom: 0.75rem;
    }

    details p {
      font-size: 0.875rem;
      color: var(--muted);
      margin-bottom: 0.5rem;
    }

    footer {
      position: relative;
      z-index: 2;
      text-align: center;
      margin-top: 2.5rem;
      padding: 1.5rem 0 2.5rem;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      font-size: 0.8125rem;
      color: var(--muted);
    }

    footer a,
    .text-link {
      color: var(--cyan);
      text-decoration: underline;
      text-underline-offset: 3px;
      padding: 0.35rem 0.15rem;
      display: inline-block;
      min-height: 44px;
      line-height: 1.4;
    }

    footer a:hover,
    .text-link:hover {
      color: var(--white);
    }

    .card a:not(.download-btn) {
      color: var(--cyan);
      text-decoration: underline;
      text-underline-offset: 2px;
    }

    .card a:not(.download-btn):hover {
      color: var(--white);
    }

    @media (min-width: 600px) {
      h1 { font-size: 2.5rem; }
      .wrap { padding-top: 3.5rem; }
    }
  </style>
</head>
<body>
  <div class="glow" aria-hidden="true"></div>

  <div class="wrap">
    <header>
      <img class="logo" src="assets/logo.png" height="120" alt="DozeAlert logo">
      <h1><span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span></h1>
      <p class="tagline">Sleep peacefully. Arrive confidently.</p>
    </header>

    <section class="card download-block" id="android">
      <h2 style="margin-bottom: 0.75rem;">Get DozeAlert on Android</h2>
      <p class="meta" style="margin-top: 0; margin-bottom: 1.25rem;">
        DozeAlert is available on the <strong>Google Play Store</strong> &mdash;
        install on your phone and get automatic updates. The Wear OS companion
        installs to a paired watch from Play.
      </p>
      <div class="download-grid">
        <a class="play-badge" href="https://play.google.com/store/apps/details?id=app.dozealert" target="_blank" rel="noopener">
          <img src="assets/google-play-badge.png" width="215" height="83" alt="Get it on Google Play">
        </a>
        <a class="download-btn download-btn-secondary" href="screenshots/index.asp#android">
          Android app tour
        </a>
      </div>
      <p class="meta" style="margin-top: 1rem;">
        Open the Play Store listing on your Android phone, tap <strong>Install</strong>,
        then pick your stop and start a trip. Requires Android 8.0+.
      </p>
      <p class="meta">
        Phone <span id="app-version">1.1.0+77</span> &middot; Wear <span id="wear-version">1.1.0+100106</span>
        &middot; Android 8.0+ &middot; Package <code>app.dozealert</code>
      </p>
    </section>

    <section class="card download-block" id="ios">
      <h2 style="margin-bottom: 0.75rem;">Try DozeAlert on iPhone</h2>
      <p class="meta" style="margin-top: 0; margin-bottom: 1.25rem;">
        DozeAlert is in <strong>public TestFlight beta</strong> for iPhone, with an
        <strong>Apple Watch companion</strong> included in the same build.
        Install Apple&rsquo;s free TestFlight app, then join with the link below &mdash;
        no App Store listing required while we prepare the public release.
      </p>
      <div class="download-grid">
        <a class="download-btn" href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">
          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M12 2a7 7 0 0 0-7 7c0 2.6 1.4 4.9 3.5 6.1L7 21h10l-1.5-5.9A7 7 0 0 0 12 2zm0 2a5 5 0 1 1 0 10A5 5 0 0 1 12 4z"/>
          </svg>
          Join iOS beta on TestFlight
        </a>
        <a class="download-btn download-btn-secondary" href="screenshots/index.asp#ios">
          iPhone app tour
        </a>
      </div>
      <p class="meta" style="margin-top: 1rem; text-align: left;">
        <strong>How it works:</strong> On your iPhone, open the invite link (or tap the
        button above). Install <strong>TestFlight</strong> from the App Store if you
        don&rsquo;t have it, accept the DozeAlert beta, then install the app. You&rsquo;ll
        get updates through TestFlight as we ship new builds.
      </p>
      <ol class="steps" style="text-align: left; margin-top: 1.25rem;">
        <li>Open <a href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">the TestFlight invite</a> on your iPhone.</li>
        <li>Install TestFlight if prompted, then accept DozeAlert.</li>
        <li>Grant <strong>Location &rarr; Always</strong> and Notifications when you start a trip.</li>
        <li>Pick a stop or map pin, tap Start, and try locking the screen.</li>
        <li>Optional: install the Watch app from the iPhone <strong>Watch</strong> app &rarr; My Watch &rarr; DozeAlert.</li>
      </ol>
      <div class="note">
        <strong>Feedback welcome:</strong> Use TestFlight&rsquo;s screenshot feedback,
        or email <a href="mailto:support@dozealert.app">support@dozealert.app</a>.
        See the <a class="text-link" href="#apple-watch">Apple Watch companion</a> section
        for install and testing tips.
      </div>
      <p class="meta" style="margin-top: 1rem;">
        iOS beta &middot; iPhone + Apple Watch &middot; Bundle ID <code>app.dozealert</code>
        &middot; Phone build <span id="ios-app-version">1.1.0+68</span>
        &middot; <a class="text-link" href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">testflight.apple.com/join/QhMZbJvR</a>
      </p>
    </section>

    <section class="card">
      <h2>About</h2>
      <p>
        DozeAlert helps commuters sleep peacefully and arrive confidently.
        Whether you&rsquo;re on a train, bus, taxi, Uber, or another rideshare,
        DozeAlert monitors your trip and wakes you before you miss where you need to get off.
      </p>
      <p style="margin-top: 0.75rem;">
        <a class="text-link" href="screenshots/index.asp">Android app tour &rarr;</a>
        &nbsp;&middot;&nbsp;
        <a class="text-link" href="screenshots/index.asp#ios">iPhone app tour &rarr;</a>
        &nbsp;&middot;&nbsp;
        <a class="text-link" href="screenshots/index.asp#apple-watch">Apple Watch &rarr;</a>
        &nbsp;&middot;&nbsp;
        <a class="text-link" href="screenshots/index.asp#wear">Wear OS &rarr;</a>
      </p>
      <ul>
        <li>Trip-first Home: pick your stop or map destination, set wake timing, tap Start</li>
        <li>Transit Mode with stop countdown for supported public transit agencies</li>
        <li>Distance-only wake-ups when Transit Mode is off &mdash; taxi, Uber, Lyft, and more</li>
        <li>Pick a stop on your route, search the map, or jump to saved stops and saved lines</li>
        <li>Three-step onboarding: welcome, pick transit (multi-agency), guided permissions</li>
        <li>Three-step Home tour plus &ldquo;Ready to sleep?&rdquo; before monitoring begins</li>
        <li><strong>My Trips</strong> tab for saved stops, saved lines, and recents</li>
        <li>Background monitoring with voice, vibration, and full-screen wake alerts</li>
        <li>Download agency stop lists for offline search (Settings &rarr; Transit)</li>
        <li><strong>Trip history</strong> and missed-trip review in Settings</li>
        <li>Transit wake timing tuned per vehicle type (bus, train, subway, and more)</li>
        <li><strong>Wear OS companion</strong> &mdash; trip status, start/stop, and dismiss alarms from your wrist (phone runs GPS and monitoring)</li>
        <li><strong>Apple Watch companion</strong> &mdash; same wrist remote on iPhone TestFlight: start/stop, dismiss, and glance status (phone runs GPS)</li>
        <li><strong>Watch face complication</strong> &mdash; glance status like RDY, stop count, or OFF without opening the watch app (Wear OS and Apple Watch)</li>
        <li>Watch connection indicator shows live link status when the companion watch app is installed</li>
        <li>No account required &mdash; trip data stays on your device</li>
      </ul>
    </section>

    <section class="card">
      <h2>Wear OS companion</h2>
      <p>
        Pair a Wear OS watch with DozeAlert on your phone for at-a-glance trip status
        on your wrist &mdash; including a <strong>watch face complication</strong> that updates
        when you start or stop a trip on your phone. Start and stop controls and GET READY
        wake alerts live in the Wear app. Your phone keeps location, permissions, and
        background monitoring; the watch is a remote control and glance display.
      </p>
      <div class="watch-grid" aria-label="Wear OS app and complication screenshots">
        <figure class="watch-card">
          <img class="watch-shot" src="assets/screens/w_shot_splash.png?v=75" width="512" height="512" alt="Wear branded splash screen with DozeAlert sleepy-pin icon on black.">
          <figcaption><strong>Branded splash</strong>Cold start shows the DozeAlert pin on true black.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="watch-shot" src="assets/screens/w_shot_ready_scroll.png?v=75" width="512" height="512" alt="Wear Ready screen with Start trip and visible scrollbar.">
          <figcaption><strong>Ready + scroll</strong>Destination, Start trip, and a Wear scrollbar for more actions.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="watch-shot" src="assets/screens/w_shot7.png" width="512" height="512" alt="Minimal analog watch face with DozeAlert sleepy-pin complication showing RDY.">
          <figcaption><strong>Complication: ready</strong>Add DozeAlert to your watch face &mdash; see RDY when a destination is set.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="watch-shot" src="assets/screens/w_shot4.png" width="512" height="512" alt="Wear app GET READY wake alert screen.">
          <figcaption><strong>GET READY</strong>Vibration repeats until you dismiss on watch or phone.</figcaption>
        </figure>
      </div>
      <p style="margin-top: 1rem;">
        <a class="text-link" href="screenshots/index.asp#wear">Wear app tour &rarr;</a>
        &nbsp;&middot;&nbsp;
        <a class="text-link" href="screenshots/index.asp#wear-complication">Complication &rarr;</a>
      </p>
      <div class="note" style="margin-top: 1rem;">
        <strong>Install:</strong> Install DozeAlert from
        <a class="text-link" href="https://play.google.com/store/apps/details?id=app.dozealert" target="_blank" rel="noopener">Google Play</a>
        on your phone first (same Google account, Bluetooth connected). The Wear OS
        companion can then install to your paired watch from Play.
      </div>
    </section>

    <section class="card" id="apple-watch">
      <h2>Apple Watch companion</h2>
      <p>
        The iPhone TestFlight build includes an <strong>Apple Watch</strong> companion &mdash;
        the same product model as Wear OS. Your iPhone keeps GPS, transit data, and wake logic;
        the Watch is a <strong>remote + glance surface</strong>: trip status, Start / Stop,
        dismiss alarm, Open on phone, optional face complication, and haptic wake alerts.
      </p>
      <div class="watch-grid" aria-label="Apple Watch companion screenshots" style="margin-top: 1.25rem;">
        <figure class="watch-card">
          <img class="apple-watch-shot" src="assets/screens/watch/02-ready-start-trip.png?v=71" width="416" height="496" alt="Apple Watch Ready screen for Bronte GO with Start trip button.">
          <figcaption><strong>Ready</strong>Destination set &mdash; start monitoring from your wrist.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="apple-watch-shot" src="assets/screens/watch/03-watching.png?v=71" width="416" height="496" alt="Apple Watch Watching screen with distance remaining and Stop trip.">
          <figcaption><strong>Watching</strong>Live trip status while the iPhone monitors in the background.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="apple-watch-shot" src="assets/screens/watch/01-idle-set-up-on-phone.png?v=71" width="416" height="496" alt="Apple Watch Idle screen prompting set up on phone.">
          <figcaption><strong>Idle</strong>No destination yet &mdash; open the phone to pick your stop.</figcaption>
        </figure>
        <figure class="watch-card">
          <img class="apple-watch-shot" src="assets/screens/ios/07-home-watch-connected.jpg?v=71" width="390" height="844" alt="iPhone Home showing Watch connected with Pick your stop." style="aspect-ratio: 390 / 844; border-radius: 1.1rem; width: 110px; max-width: 110px;">
          <figcaption><strong>Phone link</strong>iPhone Home shows Watch connected when the companion is installed.</figcaption>
        </figure>
      </div>
      <ul style="margin-top: 1.25rem;">
        <li>Start or stop monitoring from your wrist</li>
        <li>See stops remaining or distance while the phone monitors in the background</li>
        <li>Dismiss GET READY on Watch or iPhone</li>
        <li>Optional complication for RDY / stop count / WAKE at a glance</li>
        <li>Settings on iPhone &rarr; <strong>Apple Watch</strong> for connection status and
          &ldquo;Open watch app when trip starts&rdquo;</li>
      </ul>
      <ol class="steps" style="margin-top: 1.25rem;">
        <li>Install or update DozeAlert from <a href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">TestFlight</a> on your iPhone.</li>
        <li>Open the iPhone <strong>Watch</strong> app &rarr; <strong>My Watch</strong>.</li>
        <li>Find <strong>DozeAlert</strong> under Available Apps and tap <strong>Install</strong>.</li>
        <li>Optional: edit a watch face and add the DozeAlert complication.</li>
        <li>Start a trip on phone or Watch, lock the phone, and confirm status + wake on your wrist.</li>
      </ol>
      <p style="margin-top: 1rem;">
        <a class="text-link" href="screenshots/index.asp#apple-watch">Apple Watch in the app tour &rarr;</a>
        &nbsp;&middot;&nbsp;
        <a class="text-link" href="#ios">iOS TestFlight install &rarr;</a>
      </p>
      <div class="note" style="margin-top: 1rem;">
        <strong>Requirements:</strong> Paired Apple Watch on <strong>watchOS 10+</strong>,
        same iPhone that has the TestFlight build. No separate Watch App Store listing &mdash;
        the companion ships inside the iPhone app.
      </div>
    </section>

    <section class="card">
      <h2>Permissions &amp; privacy</h2>
      <p>
        DozeAlert needs clear permission choices to monitor trips reliably. First-time setup
        walks you through a short welcome, picking the transit you ride (one or more),
        granting permissions, and a guided Home tour. For monitoring on Android, set:
      </p>
      <ul>
        <li><strong>Location:</strong> Allow <strong>all the time</strong> (not only while using the app)</li>
        <li><strong>Notifications:</strong> Allowed (ongoing trip notification and alerts)</li>
        <li><strong>GPS:</strong> Location services turned on</li>
        <li><strong>Battery:</strong> Unrestricted recommended on some phones</li>
      </ul>
      <p style="margin-top: 0.75rem;">
        We do not show ads, sell personal data, or require an account. Map search uses
        Google Maps Platform; optional transit stop list downloads use public open-data hosts.
        Read the full policy:
        <a class="text-link" href="privacy/index.asp">Privacy Policy</a>.
        Transit open data attributions and licence links:
        <a class="text-link" href="transit-licenses/index.asp">Transit Data Licenses</a>.
      </p>
    </section>

    <section class="card">
      <h2>Requirements</h2>
      <ul>
        <li>Android 8.0 (Oreo) or later on phone &mdash; install from Google Play</li>
        <li>iPhone with iOS 16+ for the TestFlight beta</li>
        <li>Apple Watch on watchOS 10+ for the iPhone companion (optional)</li>
        <li>Wear OS 3+ on watch for the Android companion (paired with the phone app from Play)</li>
        <li>GPS / location services enabled</li>
        <li>Internet for map search and optional transit stop list downloads</li>
        <li>Background location and notifications for trip monitoring</li>
      </ul>
    </section>

    <footer>
      <p class="footer-links">
        <a href="screenshots/index.asp">App tour</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="#android">Google Play</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="#ios">iOS TestFlight</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="privacy/index.asp">Privacy Policy</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="transit-licenses/index.asp">Transit Data Licenses</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="feedback/index.asp">Feedback</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="mailto:support@dozealert.app">support@dozealert.app</a>
      </p>
      <p style="margin-top: 0.75rem;">No ads &middot; No sale of personal data</p>
      <p style="margin-top: 0.5rem; font-size: 0.8125rem; color: var(--muted); max-width: 36rem; margin-left: auto; margin-right: auto;">
        DozeAlert is not affiliated with, endorsed by, or sponsored by any transit agency.
        Agency names on the <a href="transit-licenses/index.asp">Transit Data Licenses</a> page identify open data sources only.
      </p>
      <p style="margin-top: 0.5rem;">&copy; DozeAlert &middot; Developer: Riaz</p>
    </footer>
  </div>

  <script>
    fetch('app-version.json', { cache: 'no-store' })
      .then((response) => response.ok ? response.json() : null)
      .then((data) => {
        if (!data) {
          return;
        }
        const label = data.label || (data.build ? `${data.version}+${data.build}` : data.version);
        const versionEl = document.getElementById('app-version');
        if (versionEl) {
          versionEl.textContent = label;
        }
        const iosVersionEl = document.getElementById('ios-app-version');
        if (iosVersionEl) {
          iosVersionEl.textContent = label;
        }
      })
      .catch(() => {});

    fetch('wear-version.json', { cache: 'no-store' })
      .then((response) => response.ok ? response.json() : null)
      .then((data) => {
        if (!data) {
          return;
        }
        const label = data.label || `${data.version} (${data.build})`;
        const wearEl = document.getElementById('wear-version');
        if (wearEl) {
          wearEl.textContent = label;
        }
      })
      .catch(() => {});
  </script>
  <script src="assets/brand.js?v=77"></script>
</body>
</html>
