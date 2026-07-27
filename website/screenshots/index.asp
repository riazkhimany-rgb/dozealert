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
  <meta name="description" content="App tour � iPhone TestFlight beta, Android phone, and Wear OS: pick your stop, map destinations, monitoring, and wake alerts.">
  <meta name="theme-color" content="#0D1B2A">
  <title>App Tour &mdash; DozeAlert</title>
  <link rel="icon" type="image/png" href="../assets/icon-512.png?v=62">
  <link rel="stylesheet" href="../assets/brand.css?v=62">
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
      --max-width: 960px;
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
      padding: 2rem 1.25rem 4rem;
    }

    .nav {
      margin-bottom: 1.5rem;
      font-size: 0.9rem;
    }

    .nav a {
      color: var(--cyan);
      text-decoration: none;
    }

    .nav a:hover {
      text-decoration: underline;
    }

    header {
      text-align: center;
      margin-bottom: 2.5rem;
    }

    header h1 {
      font-size: 2rem;
      font-weight: 700;
      letter-spacing: -0.02em;
      margin-bottom: 0.5rem;
    }

    header .tagline {
      font-size: 1.125rem;
      color: var(--cyan);
      font-weight: 500;
      margin-bottom: 1rem;
    }

    header .lead {
      color: #cbd5e1;
      font-size: 1rem;
      max-width: 40rem;
      margin: 0 auto;
    }

    .tour-jump {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      justify-content: center;
      margin: 1.25rem 0 0;
    }

    .tour-jump a {
      background: rgba(76, 201, 240, 0.12);
      color: var(--cyan);
      font-size: 0.8125rem;
      font-weight: 600;
      padding: 0.45rem 0.9rem;
      border-radius: 999px;
      border: 1px solid rgba(76, 201, 240, 0.25);
      text-decoration: none;
    }

    .tour-jump a:hover {
      background: rgba(76, 201, 240, 0.22);
      color: var(--white);
    }

    .card {
      background: var(--card);
      border: 1px solid rgba(76, 201, 240, 0.12);
      border-radius: var(--radius);
      padding: 1.5rem;
      margin-bottom: 1.25rem;
    }

    .card h2 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--cyan);
    }

    .card .section-lead {
      color: #cbd5e1;
      font-size: 0.95rem;
      margin-bottom: 1.25rem;
    }

    .showcase {
      display: grid;
      gap: 1.5rem;
    }

    @media (min-width: 720px) {
      .showcase.two-col {
        grid-template-columns: 1fr 1fr;
        align-items: center;
      }

      .showcase.two-col.reverse .shot-wrap {
        order: 2;
      }

      .showcase.two-col.reverse .copy {
        order: 1;
      }
    }

    .shot-wrap {
      display: flex;
      justify-content: center;
    }

    .shot {
      width: 100%;
      max-width: 280px;
      border-radius: 20px;
      border: 1px solid rgba(255, 255, 255, 0.1);
      box-shadow:
        0 20px 50px rgba(0, 0, 0, 0.45),
        0 0 0 1px rgba(76, 201, 240, 0.08);
      display: block;
    }

    .shot.hero-shot {
      max-width: 320px;
    }

    .shot.watch-shot {
      width: 220px;
      height: 220px;
      max-width: 220px;
      aspect-ratio: 1 / 1;
      object-fit: cover;
      object-position: center center;
      border-radius: 50%;
      border: 2px solid rgba(76, 201, 240, 0.2);
      box-shadow:
        0 20px 50px rgba(0, 0, 0, 0.45),
        0 0 0 1px rgba(76, 201, 240, 0.08);
    }

    .download-grid {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.75rem;
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

    .copy h3 {
      font-size: 1.0625rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--white);
    }

    .copy p {
      color: #cbd5e1;
      font-size: 0.9375rem;
    }

    .copy ul {
      margin-top: 0.75rem;
      padding-left: 1.25rem;
      color: #cbd5e1;
      font-size: 0.9375rem;
    }

    .copy li + li {
      margin-top: 0.35rem;
    }

    .pill-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-top: 1rem;
    }

    .pill {
      background: rgba(76, 201, 240, 0.12);
      color: var(--cyan);
      font-size: 0.75rem;
      font-weight: 600;
      padding: 0.35rem 0.75rem;
      border-radius: 999px;
      border: 1px solid rgba(76, 201, 240, 0.2);
    }

    .cta-block {
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
      transition: background 0.15s, transform 0.15s;
      box-shadow: 0 4px 20px rgba(76, 201, 240, 0.35);
    }

    .download-btn:hover {
      background: var(--cyan-dim);
      transform: translateY(-1px);
    }

    footer {
      text-align: center;
      margin-top: 2.5rem;
      padding-top: 1.5rem;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      font-size: 0.8125rem;
      color: var(--muted);
    }

    footer a {
      color: var(--cyan);
      text-decoration: underline;
      text-underline-offset: 3px;
    }

    footer a:hover {
      color: var(--white);
    }
  </style>
</head>
<body>
  <div class="glow" aria-hidden="true"></div>

  <div class="wrap">
    <nav class="nav" aria-label="Breadcrumb">
      <a href="../index.asp">&larr; DozeAlert home</a>
    </nav>

    <header>
      <h1>App tour</h1>
      <p class="tagline">Sleep peacefully. Arrive confidently.</p>
      <p class="lead">
        DozeAlert is a commute alarm for riders who want to rest without missing where
        they need to get off. Use Transit Mode on supported agencies with stop-by-stop
        progress, or turn it off and wake by distance for taxi, Uber, and other rides.
        Available on <strong>Android</strong> and as an <strong>iPhone TestFlight beta</strong>.
        No account required &mdash; trip data stays on your device.
      </p>
      <nav class="tour-jump" aria-label="Tour sections">
        <a href="#ios">iPhone</a>
        <a href="#android">Android</a>
        <a href="#wear">Wear OS</a>
        <a href="#wear-complication">Complication</a>
      </nav>
    </header>

    <section class="card" id="ios">
      <h2>iPhone (TestFlight beta)</h2>
      <p class="section-lead">
        The same trip-first experience on iOS &mdash; pick a transit stop or map pin,
        start monitoring, and wake before you arrive. Join the public TestFlight beta
        while we prepare the App Store release.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot hero-shot" src="../assets/screens/ios/01-home-pick-stop.jpg" width="390" height="844" alt="DozeAlert iPhone Home with Pick your stop and wake timing.">
        </div>
        <div class="copy">
          <h3>Pick your stop on Home</h3>
          <p>
            Choose where you get off, confirm your line, set how many stops early to wake,
            then tap Start. Lock your phone &mdash; DozeAlert keeps watching in the background.
          </p>
          <div class="pill-row">
            <span class="pill">iPhone</span>
            <span class="pill">TestFlight</span>
            <span class="pill">No account</span>
          </div>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/ios/02-pick-stop-stations.jpg" width="280" height="606" alt="iPhone station picker for GO Transit Lakeshore West.">
        </div>
        <div class="copy">
          <h3>Station lists on your route</h3>
          <p>
            Browse or filter stations for the line you selected. Switch agencies or lines
            anytime with Change line.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/ios/03-monitoring-transit.jpg" width="280" height="606" alt="iPhone watching a transit trip with distance remaining.">
        </div>
        <div class="copy">
          <h3>Watching your trip</h3>
          <p>
            See your stop, remaining distance, and wake timing while DozeAlert monitors.
            You can lock the phone and keep riding.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/ios/04-wake-alert-settings.jpg" width="280" height="606" alt="iPhone wake alert sheet with wake by stops options.">
        </div>
        <div class="copy">
          <h3>Wake by stops</h3>
          <p>
            Choose at destination, 1 stop before, or 2 stops before &mdash; tuned for how
            early you want to get ready.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/ios/05-map-destination.jpg" width="280" height="606" alt="iPhone map picker setting Yorkdale Shopping Centre as destination.">
        </div>
        <div class="copy">
          <h3>Map pin destinations</h3>
          <p>
            Not on transit? Search the map, drop a pin, and wake by distance for taxi,
            rideshare, or walking trips.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/ios/06-monitoring-map-pin.jpg" width="280" height="606" alt="iPhone watching a map-pin trip with kilometers remaining.">
        </div>
        <div class="copy">
          <h3>Distance wake-ups</h3>
          <p>
            When Transit Mode isn&rsquo;t in play, DozeAlert tracks GPS distance to your pin
            and alerts you as you approach.
          </p>
        </div>
      </div>
      <div class="cta-block" style="padding: 1.5rem 0 0; text-align: center;">
        <p style="color: #cbd5e1; margin-bottom: 1rem; font-size: 0.95rem;">
          Join the public iOS beta &mdash; install via Apple TestFlight on your iPhone.
        </p>
        <div class="download-grid">
          <a class="download-btn" href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">
            Join iOS beta on TestFlight
          </a>
          <a class="download-btn download-btn-secondary" href="../index.asp#ios">
            How to join (on home)
          </a>
        </div>
        <p style="margin-top: 0.85rem; font-size: 0.8125rem; color: var(--muted);">
          Phone-only for now &mdash; no Apple Watch companion yet.
        </p>
      </div>
    </section>

    <section class="card" id="android">
      <h2>Your commute alarm</h2>
      <p class="section-lead">
        A focused Home screen keeps your stop, wake timing, and Start button in one place.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot hero-shot" src="../assets/screens/shot4.jpg" width="320" height="693" alt="DozeAlert splash screen with logo and tagline Sleep peacefully. Arrive confidently.">
        </div>
        <div class="copy">
          <h3>Wake up before your stop</h3>
          <p>
            DozeAlert monitors your trip in the background and alerts you as you approach
            your destination &mdash; on transit with stop countdown, or by GPS distance
            for taxi, rideshare, and other trips.
          </p>
          <div class="pill-row">
            <span class="pill">No account</span>
            <span class="pill">On-device data</span>
            <span class="pill">Voice &amp; vibration</span>
          </div>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Quick first-time setup</h2>
      <p class="section-lead">
        Three short steps: welcome, pick the transit you ride (one or more), then grant
        permissions with guided prompts. Stop lists download in the background for each
        agency you select.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot3.jpg" width="280" height="606" alt="Welcome screen explaining wake alerts and the three-step setup flow.">
        </div>
        <div class="copy">
          <h3>Welcome</h3>
          <p>
            A brief intro explains what DozeAlert does and what comes next &mdash; selecting
            transit, granting permissions, then picking your stop on Home and tapping Start.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot5.jpg" width="280" height="606" alt="Multi-agency picker with two transit agencies selected.">
        </div>
        <div class="copy">
          <h3>Pick your transit</h3>
          <p>
            Select all agencies you ride &mdash; for example more than one on the same day.
            Your default shows on Home first; change transit or line anytime from
            <strong>Pick your stop</strong>.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot9.jpg" width="280" height="606" alt="Permissions checklist complete with You're ready message.">
        </div>
        <div class="copy">
          <h3>Guided permissions</h3>
          <p>
            A step-by-step checklist walks through GPS, location (while using + all the time),
            notifications, and battery. Plain-language prompts tell you exactly what to tap
            on each Android screen. Optional activity detection helps tell riding from waiting
            at a platform &mdash; off by default.
          </p>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Pick your stop</h2>
      <p class="section-lead">
        Home is trip-first: pick where you get off, confirm transit and line if needed, then
        tap Start. A short three-step tour highlights the essentials on first visit.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot10.jpg" width="280" height="606" alt="Home tour step 1 highlighting Pick your stop button.">
        </div>
        <div class="copy">
          <h3>Guided Home tour</h3>
          <p>
            After setup, a three-step tour on Home shows where to pick your stop or
            destination, adjust wake timing, and start monitoring. Replay anytime from
            <strong>Settings &rarr; Show app tour</strong>.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot11.jpg" width="280" height="606" alt="Home screen with Pick your stop card and selected transit line.">
        </div>
        <div class="copy">
          <h3>Home</h3>
          <p>
            <strong>Pick your stop</strong> opens the route picker. <strong>Quick picks</strong>
            opens recent and saved stops. Your current transit and line show at the
            bottom of the card. A paired watch shows <strong>Watch connected</strong> when synced.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot13.jpg" width="280" height="606" alt="Choose transit and line sheet with route search and bus or train filters.">
        </div>
        <div class="copy">
          <h3>Transit &amp; line</h3>
          <p>
            Confirm or change agency and route before picking a stop. Filter by bus or train
            and search by number or name from downloaded stop lists.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot12.jpg" width="280" height="606" alt="Pick your stop sheet listing stations on the selected route.">
        </div>
        <div class="copy">
          <h3>Pick a stop</h3>
          <p>
            Search and filter stops on your selected route, or browse all routes at a station.
            Downloaded GTFS data powers offline stop search and Transit Mode progress.
          </p>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Start monitoring</h2>
      <p class="section-lead">
        Review wake timing, confirm &ldquo;Ready to sleep?&rdquo;, then relax.
        DozeAlert tracks your trip and shows progress on Home and in your notification shade.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot16.jpg" width="280" height="606" alt="Ready to sleep confirmation before starting trip monitoring.">
        </div>
        <div class="copy">
          <h3>Ready to sleep?</h3>
          <p>
            Before monitoring begins, a short confirmation reminds you to keep volume on and
            your phone charged. Tap <strong>Start my trip</strong> when you are settled.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot28.jpg" width="280" height="606" alt="Home screen monitoring a trip with stop-by-stop progress on a transit route.">
        </div>
        <div class="copy">
          <h3>Stop-by-stop progress</h3>
          <p>
            With Transit Mode on, Home shows stops remaining, your next stop, and distance
            along the route. Wake timing uses stops when you are on your line, and falls back
            to your alert distance when GPS is the better signal. A wrong-direction banner gives
            a heads-up if your line may not match your trip.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot18.jpg" width="280" height="606" alt="Lock screen notification showing trip monitoring with destination and distance remaining.">
        </div>
        <div class="copy">
          <h3>Background monitoring</h3>
          <p>
            An ongoing notification keeps you informed while the phone is locked &mdash;
            destination name and distance remaining at a glance. Lock your phone and rest.
          </p>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Rideshare &amp; any commute</h2>
      <p class="section-lead">
        Not every trip needs stop counting. Turn Transit Mode off and DozeAlert wakes you
        by straight-line distance to a map pin or searched address &mdash; ideal for taxi,
        Uber, Lyft, airport shuttles, and other rides where GPS is the signal.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot31.jpg" width="280" height="606" alt="Pick destination screen with map search for Highway 7 in Markham.">
        </div>
        <div class="copy">
          <h3>Pick any destination</h3>
          <p>
            Search an address or landmark, fine-tune the pin on the map, and set your
            destination. Save frequent drop-offs to <strong>My Trips</strong> for one-tap
            restarts on your next ride.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot32.jpg" width="280" height="606" alt="Transit Mode settings with Transit Mode off and 500m alert distance.">
        </div>
        <div class="copy">
          <h3>Wake by distance</h3>
          <p>
            In <strong>Settings &rarr; Transit &rarr; Transit Mode</strong>, turn Transit Mode
            off when you do not need stop countdown. Choose your alert distance &mdash; for
            example 500&nbsp;m before you arrive.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot30.jpg" width="280" height="606" alt="Home screen monitoring a trip to Highway 7 with distance remaining and wake by 500m.">
        </div>
        <div class="copy">
          <h3>Distance on Home</h3>
          <p>
            While monitoring, Home shows how far you are from your destination and your
            wake distance. Lock your phone and rest &mdash; the same voice, vibration, and
            GET READY alerts work for every mode of commute.
          </p>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>My Trips</h2>
      <p class="section-lead">
        Saved stops and saved lines stay one tap away on the My Trips tab.
        Recent stops appear automatically for fast restarts.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot20.jpg" width="280" height="606" alt="My Trips tab with saved stops, saved lines, and recent stops.">
        </div>
        <div class="copy">
          <h3>Saved stops &amp; lines</h3>
          <p>
            Save favorite stops and line pairs for quick access. Tap play on any item to set
            it and jump back to Home. Recent stops update as you ride.
          </p>
          <ul>
            <li>Saved stops with transit badges</li>
            <li>Saved lines for quick switching during transfers</li>
            <li>Recent stops for one-tap restarts</li>
          </ul>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Settings</h2>
      <p class="section-lead">
        Transit stop downloads, Transit Mode timing, trip history, and alarm controls live
        in Settings. No ads, no data sale.
      </p>
      <div class="showcase two-col reverse">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot21.jpg" width="280" height="606" alt="Settings hub with permissions, transit, location, and alarm sections.">
        </div>
        <div class="copy">
          <h3>Settings hub</h3>
          <p>
            Theme, permissions, transit mode, location accuracy, and alarm sound all
            live under Settings. Trip history and missed trips are at the bottom under
            <strong>Trip history</strong>.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot24.jpg" width="280" height="606" alt="Transit Mode settings with wake-by-stops timing.">
        </div>
        <div class="copy">
          <h3>Transit Mode</h3>
          <p>
            Wake by stops when you are on your transit route. Choose at destination,
            1 stop before, or 2 stops before. A distance fallback handles map-pin
            destinations or rides off the route.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot22.jpg" width="280" height="606" alt="Alarm settings with voice approach alert and speaker volume controls.">
        </div>
        <div class="copy">
          <h3>Approach alerts</h3>
          <p>
            A spoken &ldquo;Heads up! Approaching destination.&rdquo; plays with vibration until
            you dismiss. Adjust speaker volume during the alert and control voice and tone levels
            separately. Optionally force the alarm sound even when the phone is on silent.
          </p>
        </div>
      </div>
    </section>

    <section class="card" id="wear">
      <h2>Wear OS companion</h2>
      <p class="section-lead">
        A paired watch shows live trip status, lets you start or stop monitoring, and repeats
        vibration until you dismiss a wake-up alert. Add a <strong>watch face complication</strong>
        for RDY, stop count, or OFF at a glance. GPS and permissions stay on your phone.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot1.png" width="512" height="512" alt="Wear app idle screen with Open on phone button.">
        </div>
        <div class="copy">
          <h3>Set up on phone</h3>
          <p>
            When no destination is selected, the watch shows <strong>Phone connected</strong> and
            an <strong>Open on phone</strong> shortcut. Pick a stop on the phone first
            &mdash; the watch syncs over Bluetooth.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot2_new.png" width="512" height="512" alt="Wear app ready screen with Phone connected, Bronte GO destination, and Start trip.">
        </div>
        <div class="copy">
          <h3>Ready when you are</h3>
          <p>
            With a destination set, the watch shows <strong>Phone connected</strong>,
            <strong>Ready</strong>, and your stop or line. Tap <strong>Start trip</strong>
            on your wrist or phone &mdash; either starts monitoring on the phone.
          </p>
        </div>
      </div>
      <div class="showcase two-col" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot3.png" width="512" height="512" alt="Wear app monitoring with stop countdown and Stop trip.">
        </div>
        <div class="copy">
          <h3>Watching your trip</h3>
          <p>
            While monitoring, see stops remaining or distance (Transit Mode). Tap
            <strong>Stop trip</strong> to end early. Prefer the watch face? Use the
            <a class="text-link" href="#wear-complication">DozeAlert complication</a>
            for status without opening the app.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot4.png" width="512" height="512" alt="Wear app GET READY wake alert with Dismiss alarm button.">
        </div>
        <div class="copy">
          <h3>GET READY on your wrist</h3>
          <p>
            When you approach your stop, the watch shows <strong>GET READY</strong> with your
            destination and vibrates until you tap <strong>Dismiss alarm</strong>
            on the watch or phone.
          </p>
        </div>
      </div>
    </section>

    <section class="card" id="wear-complication">
      <h2>Watch face complication</h2>
      <p class="section-lead">
        Add DozeAlert to a supported watch face. When you start a trip on your phone, the
        complication updates on your wrist &mdash; no need to open the Wear app for a quick status check.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot7.png" width="512" height="512" alt="Minimal analog watch face with DozeAlert sleepy-pin complication showing RDY.">
        </div>
        <div class="copy">
          <h3>Ready on the dial</h3>
          <p>
            With a destination set (not yet monitoring), the complication shows the
            DozeAlert pin and <strong>RDY</strong>. Customize your watch face and pick
            <strong>DozeAlert</strong> for a SHORT_TEXT slot.
          </p>
        </div>
      </div>
      <div class="showcase two-col reverse" style="margin-top: 1.5rem;">
        <div class="shot-wrap">
          <img class="shot watch-shot" src="../assets/screens/w_shot6.png" width="512" height="512" alt="Minimal analog watch face with DozeAlert complication showing 4 stp while monitoring.">
        </div>
        <div class="copy">
          <h3>Stops at a glance</h3>
          <p>
            While DozeAlert is watching your trip, see stop count
            (for example <strong>4 stp</strong>) or remaining distance. Status also covers
            <strong>OFF</strong>, <strong>ON</strong>, <strong>WAKE</strong>, and more
            as your trip progresses.
          </p>
        </div>
      </div>
    </section>

    <section class="card">
      <h2>Reliable wake alerts</h2>
      <p class="section-lead">
        Voice, vibration, and optional alarm tone wake you before you miss your stop.
        Volume is boosted during the alert, then restored when you dismiss.
      </p>
      <div class="showcase two-col">
        <div class="shot-wrap">
          <img class="shot" src="../assets/screens/shot1.jpg" width="280" height="606" alt="GET READY full-screen wake alert with stop name and dismiss button.">
        </div>
        <div class="copy">
          <h3>GET READY</h3>
          <p>
            A full-screen wake alert shows your stop, how many stops remain, and where you are
            now. The alarm continues until you dismiss &mdash; on phone or watch.
          </p>
        </div>
      </div>
    </section>

    <section class="card cta-block">
      <h2 style="margin-bottom: 0.75rem;">Ready to try it?</h2>
      <p style="color: #cbd5e1; margin-bottom: 1.25rem; font-size: 0.95rem;">
        Join the iPhone TestFlight beta or the Google Play closed test and set your first
        destination in under a minute.
      </p>
      <div class="download-grid">
        <a class="download-btn" href="https://testflight.apple.com/join/QhMZbJvR" target="_blank" rel="noopener">
          Join iOS beta on TestFlight
        </a>
        <a class="download-btn download-btn-secondary" href="https://play.google.com/store/apps/details?id=app.dozealert" target="_blank" rel="noopener">
          Join on Android (Play Store)
        </a>
        <a class="download-btn download-btn-secondary" href="../downloads/dozealert-latest.apk" download="dozealert.apk">
          Download phone APK
        </a>
        <a class="download-btn download-btn-secondary" href="../downloads/dozealert-wear-latest.apk" download="dozealert-wear.apk">
          Download Wear OS APK
        </a>
      </div>
      <p style="margin-top: 1rem; font-size: 0.8125rem; color: var(--muted);">
        Wear builds are on a separate Play closed-testing track when sideloading.
      </p>
    </section>

    <footer>
      <p>
        <a href="../index.asp">Home</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="../index.asp#ios">iOS TestFlight</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="../privacy/index.asp">Privacy Policy</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="../feedback/index.asp">Feedback</a>
        <span aria-hidden="true"> &middot; </span>
        <a href="mailto:support@dozealert.app">support@dozealert.app</a>
      </p>
      <p style="margin-top: 0.75rem;">&copy; DozeAlert</p>
    </footer>
  </div>
  <script src="../assets/brand.js?v=62"></script>
</body>
</html>
