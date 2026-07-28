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
  <meta name="description" content="DozeAlert transit open data attributions and licence links for supported transit systems.">
  <meta name="theme-color" content="#0D1B2A">
  <title>Transit Data Licenses &mdash; DozeAlert</title>
  <link rel="icon" type="image/png" href="../assets/icon-512.png?v=70">
  <link rel="stylesheet" href="../assets/brand.css?v=70">
  <style>
    :root {
      --midnight: #0D1B2A;
      --cyan: #4CC9F0;
      --white: #FFFFFF;
      --muted: #94a3b8;
      --card: #1B3147;
      --radius: 16px;
      --max-width: 720px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: var(--midnight);
      color: var(--white);
      line-height: 1.65;
      min-height: 100vh;
    }
    .glow {
      position: fixed;
      inset: 0;
      pointer-events: none;
      background: radial-gradient(ellipse 80% 50% at 50% -20%, rgba(76, 201, 240, 0.15), transparent);
      z-index: 0;
    }
    .wrap {
      position: relative;
      z-index: 1;
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 2rem 1.25rem 4rem;
    }
    .nav { margin-bottom: 1.5rem; font-size: 0.9rem; }
    .nav a { color: var(--cyan); text-decoration: none; }
    .nav a:hover { text-decoration: underline; }
    h1 { font-size: 2rem; margin-bottom: 0.5rem; }
    .meta { color: var(--muted); font-size: 0.875rem; margin-bottom: 2rem; }
    .card {
      background: var(--card);
      border: 1px solid rgba(76, 201, 240, 0.12);
      border-radius: var(--radius);
      padding: 1.5rem;
      margin-bottom: 1.25rem;
    }
    .card h2 {
      font-size: 1.125rem;
      color: var(--cyan);
      margin-bottom: 0.75rem;
    }
    .card p, .card li { color: #cbd5e1; font-size: 0.9375rem; }
    .card ul { padding-left: 1.25rem; margin-top: 0.5rem; }
    .card li + li { margin-top: 0.35rem; }
    .agency {
      padding: 1rem 0;
      border-bottom: 1px solid rgba(148, 163, 184, 0.2);
    }
    .agency:last-child { border-bottom: none; padding-bottom: 0; }
    .agency h3 {
      font-size: 1rem;
      margin-bottom: 0.35rem;
      color: var(--white);
    }
    .agency p { margin-bottom: 0.5rem; }
    .agency a {
      color: var(--cyan);
      text-decoration: underline;
      text-underline-offset: 2px;
      word-break: break-word;
    }
    .agency a:hover { color: var(--white); }
    .badge {
      display: inline-block;
      font-size: 0.75rem;
      color: var(--muted);
      margin-left: 0.35rem;
    }
    footer {
      margin-top: 2rem;
      text-align: center;
      color: var(--muted);
      font-size: 0.875rem;
    }
    footer a { color: var(--cyan); text-decoration: none; }
    footer a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="glow" aria-hidden="true"></div>
  <div class="wrap">
    <nav class="nav"><a href="../index.asp">&larr; dozealert.app</a></nav>

    <h1>Transit Data Licenses</h1>
    <p class="meta">Open data attributions for transit systems supported in <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span></p>

    <section class="card">
      <h2>Open data notice</h2>
      <p>
        <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span> uses public transit schedule and stop data
        (GTFS format) from transit agencies. Data is cached on your device for offline alarms.
        Where permitted, <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span> may host a mirror of a GTFS file on
        <a href="https://dozealert.app/gtfs-mirror/" rel="noopener noreferrer">dozealert.app</a>
        for in-app download; agency open data terms still apply. Review each agency&rsquo;s terms before
        downloading stop lists.
      </p>
      <p style="margin-top: 0.75rem;">
        <strong>DozeAlert is not affiliated with, endorsed by, or sponsored by any transit agency.</strong>
        Agency names and attributions below identify open data sources only.
      </p>
    </section>

    <section class="card">
      <h2>Stop lists in the app</h2>
      <p>
        During first-run setup, <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span> downloads stop lists
        in the background for the transit you pick when a direct agency download is available.
        You can also download or update stop lists anytime under
        <strong>Settings &rarr; Transit &rarr; Transit stops</strong>, or import a GTFS zip where
        an agency requires manual import.
      </p>
      <p style="margin-top: 0.75rem;">
        Choose country, region, transit, and line under
        <strong>Settings &rarr; Transit &rarr; Transit &amp; line</strong>.
      </p>
    </section>

    <section class="card">
      <h2>Catalog agencies with in-app download</h2>
      <p style="margin-bottom: 1rem;">Transit systems with stop lists you can download inside <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span>.</p>

      <div class="agency">
        <h3>BART</h3>
        <p>Contains data from Bay Area Rapid Transit (BART) under the BART Developer License Agreement.</p>
        <a href="https://www.bart.gov/schedules/developers/developer-license-agreement" rel="noopener noreferrer">BART Developer License Agreement</a>
      </div>
      <div class="agency">
        <h3>Caltrain</h3>
        <p>Contains data from Caltrain.</p>
        <a href="http://www.caltrain.com/developer.html" rel="noopener noreferrer">Caltrain Developer</a>
      </div>
      <div class="agency">
        <h3>CTA</h3>
        <p>Contains data from the Chicago Transit Authority (CTA).</p>
        <a href="http://www.transitchicago.com/downloads/sch_data/developers_license_agreement.htm" rel="noopener noreferrer">CTA Developer License Agreement</a>
      </div>
      <div class="agency">
        <h3>DART</h3>
        <p>Contains data from Dallas Area Rapid Transit (DART).</p>
        <a href="https://dart.org/about/about-dart/fixed-route-schedule" rel="noopener noreferrer">DART Fixed Route Schedule</a>
      </div>
      <div class="agency">
        <h3>LA Metro</h3>
        <p>Contains data from LA Metro (LACMTA) bus service.</p>
        <a href="https://developer.metro.net/gtfs-schedule-data/" rel="noopener noreferrer">Metro GTFS Schedule Data</a>
      </div>
      <div class="agency">
        <h3>LA Metro Rail</h3>
        <p>Contains data from LA Metro (LACMTA) rail service.</p>
        <a href="https://developer.metro.net/gtfs-schedule-data/" rel="noopener noreferrer">Metro GTFS Schedule Data</a>
      </div>
      <div class="agency">
        <h3>MARTA</h3>
        <p>Contains data from the Metropolitan Atlanta Rapid Transit Authority (MARTA).</p>
        <a href="https://itsmarta.com/app-developer-resources.aspx" rel="noopener noreferrer">MARTA Developer Resources</a>
      </div>
      <div class="agency">
        <h3>MBTA</h3>
        <p>Contains data from the Massachusetts Bay Transportation Authority (MBTA) under the MassDOT Developers License Agreement.</p>
        <a href="https://www.mass.gov/files/documents/2017/10/27/develop_license_agree_0.pdf" rel="noopener noreferrer">MassDOT Developers License Agreement</a>
      </div>
      <div class="agency">
        <h3>MTA</h3>
        <p>Contains data from MTA New York City Transit under the MTA Developer Terms and Conditions.</p>
        <a href="https://www.mta.info/developers/terms-and-conditions" rel="noopener noreferrer">MTA Developer Terms and Conditions</a>
      </div>
      <div class="agency">
        <h3>NJ Transit</h3>
        <p>Contains data from NJ Transit under the NJ Transit Developer Terms and Conditions.</p>
        <a href="https://developer.njtransit.com/terms/" rel="noopener noreferrer">NJ Transit Developer Terms</a>
      </div>
      <div class="agency">
        <h3>NJ Transit Rail</h3>
        <p>Contains data from NJ Transit under the NJ Transit Developer Terms and Conditions.</p>
        <a href="https://developer.njtransit.com/terms/" rel="noopener noreferrer">NJ Transit Developer Terms</a>
      </div>
      <div class="agency">
        <h3>SEPTA</h3>
        <p>Contains data from SEPTA under the SEPTA License Agreement.</p>
        <a href="https://www3.septa.org/developer/" rel="noopener noreferrer">SEPTA Developer Download</a>
      </div>
      <div class="agency">
        <h3>Sound Transit</h3>
        <p>Contains data from Sound Transit Open Transit Data.</p>
        <a href="https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/transit-data-terms-use" rel="noopener noreferrer">Sound Transit Transit Data Terms of Use</a>
      </div>
      <div class="agency">
        <h3>TriMet</h3>
        <p>Contains data from TriMet under the TriMet Terms of Use.</p>
        <a href="http://developer.trimet.org/terms_of_use.shtml" rel="noopener noreferrer">TriMet Terms of Use</a>
      </div>
      <div class="agency">
        <h3>VTA</h3>
        <p>Contains data from the Santa Clara Valley Transportation Authority (VTA).</p>
        <a href="https://gtfs.vta.org/" rel="noopener noreferrer">VTA GTFS Terms of Use</a>
      </div>
      <div class="agency">
        <h3>Barrie Transit</h3>
        <p>Contains data from Barrie Transit Open Data.</p>
        <a href="https://www.barrie.ca/services-payments/transportation-parking/barrie-transit/barrie-gtfs" rel="noopener noreferrer">Barrie GTFS terms</a>
      </div>
      <div class="agency">
        <h3>Brampton Transit</h3>
        <p>Contains data from Brampton Transit Open Data (CC BY 4.0).</p>
        <a href="https://creativecommons.org/licenses/by/4.0/" rel="noopener noreferrer">Creative Commons Attribution 4.0</a>
        <span class="badge">&middot;</span>
        <a href="https://geohub.brampton.ca/datasets/a355aabd5a8c490186bdce559c9c75fb" rel="noopener noreferrer">Brampton Transit GTFS dataset</a>
      </div>
      <div class="agency">
        <h3>Burlington Transit</h3>
        <p>Contains data from Burlington Transit Open Data.</p>
        <a href="https://opendata.burlington.ca/" rel="noopener noreferrer">Burlington Open Data</a>
      </div>
      <div class="agency">
        <h3>Durham Region Transit</h3>
        <p>Contains data from Durham Region Transit Open Data.</p>
        <a href="https://www.durham.ca/en/regional-government/open-data.aspx" rel="noopener noreferrer">Durham Region Open Data Licence</a>
      </div>
      <div class="agency">
        <h3>GO Transit</h3>
        <p>Contains data from GO Transit (Metrolinx) Open Data Catalogue.</p>
        <a href="https://www.gotransit.com/en/partner-with-us/software-developers" rel="noopener noreferrer">Metrolinx GTFS Access and Use Agreement</a>
      </div>
      <div class="agency">
        <h3>Grand River Transit</h3>
        <p>Contains data from Grand River Transit Open Data.</p>
        <a href="https://www.regionofwaterloo.ca/government-and-council/transparency-and-accountability/open-data/" rel="noopener noreferrer">Region of Waterloo Open Data Licence</a>
        <span class="badge">&middot;</span>
        <a href="https://www.regionofwaterloo.ca/opendatadownloads/GRT_GTFS.zip" rel="noopener noreferrer">GRT GTFS (agency source)</a>
      </div>
      <div class="agency">
        <h3>Guelph Transit</h3>
        <p>Contains data from Guelph Transit Open Data.</p>
        <a href="https://guelph.ca/city-government/plans-and-strategies/digital-innovation/open-data/" rel="noopener noreferrer">Guelph Open Data</a>
      </div>
      <div class="agency">
        <h3>Hamilton Street Railway</h3>
        <p>Contains data from Hamilton Street Railway Open Data.</p>
        <a href="https://opendata.hamilton.ca/GTFS-Static/" rel="noopener noreferrer">Hamilton Open Data GTFS</a>
      </div>
      <div class="agency">
        <h3>Kingston Transit</h3>
        <p>Contains data from Kingston Transit Open Data.</p>
        <a href="https://www.cityofkingston.ca/government/open-data/" rel="noopener noreferrer">City of Kingston Open Data</a>
      </div>
      <div class="agency">
        <h3>London Transit</h3>
        <p>Contains data from London Transit Commission Open Data.</p>
        <a href="https://www.londontransit.ca/open-data/ltcs-open-data-terms-of-use/" rel="noopener noreferrer">LTC Open Data Terms</a>
      </div>
      <div class="agency">
        <h3>MiWay</h3>
        <p>Contains data from MiWay Open GTFS.</p>
        <a href="https://www.mississauga.ca/miway-transit/developer-download/" rel="noopener noreferrer">MiWay Developer Download</a>
      </div>
      <div class="agency">
        <h3>Milton Transit</h3>
        <p>Contains data from Milton Transit GTFS (Metrolinx host).</p>
        <a href="https://www.gotransit.com/en/partner-with-us/software-developers" rel="noopener noreferrer">Metrolinx GTFS Access and Use Agreement</a>
      </div>
      <div class="agency">
        <h3>OC Transpo</h3>
        <p>Contains data provided by OC Transpo, licensed under the City of Ottawa Open Government Licence.</p>
        <a href="https://www.octranspo.com/en/plan-your-trip/travel-tools/developers/dev-terms" rel="noopener noreferrer">OC Transpo API Terms of Use</a>
        <span class="badge">&middot;</span>
        <a href="https://ottawa.ca/en/city-hall/get-know-your-city/open-data" rel="noopener noreferrer">City of Ottawa Open Data</a>
      </div>
      <div class="agency">
        <h3>Sault Ste. Marie Transit</h3>
        <p>Contains data from Sault Ste. Marie Transit GTFS (Metrolinx host).</p>
        <a href="https://www.gotransit.com/en/partner-with-us/software-developers" rel="noopener noreferrer">Metrolinx GTFS Access and Use Agreement</a>
      </div>
      <div class="agency">
        <h3>Thunder Bay Transit</h3>
        <p>Contains data from Thunder Bay Transit Open Data.</p>
        <a href="https://www.thunderbay.ca/en/city-services/developers---open-data.aspx" rel="noopener noreferrer">Thunder Bay Open Data</a>
      </div>
      <div class="agency">
        <h3>TTC</h3>
        <p>Contains data licensed under the City of Toronto Open Data License.</p>
        <a href="https://open.toronto.ca/open-data-licence/" rel="noopener noreferrer">Open Government Licence &ndash; Toronto</a>
      </div>
      <div class="agency">
        <h3>York Region Transit</h3>
        <p>Contains data from York Region Transit Open Data. GTFS mirrored on dozealert.app under YRT open data terms.</p>
        <a href="https://www.yrt.ca/en/about-us/open-data.aspx" rel="noopener noreferrer">YRT Open Data terms</a>
        <span class="badge">&middot;</span>
        <a href="https://dozealert.app/gtfs-mirror/gtfs_yrt.zip" rel="noopener noreferrer">DozeAlert YRT GTFS mirror</a>
      </div>
    </section>

    <section class="card">
      <h2>Listed transit without in-app download</h2>
      <p style="margin-bottom: 1rem;">
        Line names are listed for convenience. Schedule and stop data is subject to
        agency open data terms when you import a stop list file.
      </p>

      <div class="agency">
        <h3>Amtrak</h3>
        <a href="https://www.amtrak.com/developer-resources" rel="noopener noreferrer">Amtrak developer resources</a>
      </div>
      <div class="agency">
        <h3>Exo</h3>
        <a href="https://exo.quebec/fr/a-propos/donnees-ouvertes" rel="noopener noreferrer">Exo open data</a>
      </div>
      <div class="agency">
        <h3>STM Montreal</h3>
        <a href="https://www.stm.info/en/about/developers" rel="noopener noreferrer">STM developers</a>
      </div>
      <div class="agency">
        <h3>TransLink Vancouver</h3>
        <a href="https://www.translink.ca/about-us/doing-business-with-translink/app-developer-resources/gtfs/gtfs-data" rel="noopener noreferrer">TransLink GTFS static data</a>
      </div>
    </section>

    <section class="card">
      <h2>In the app</h2>
      <p>
        The same attributions and licence links are available in <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span> under
        <strong>Settings &rarr; About &rarr; Open Data</strong>.
      </p>
    </section>

    <footer>
      <p>
        <a href="../index.asp">dozealert.app</a>
        &middot; <a href="../privacy/index.asp">Privacy Policy</a>
        &middot; &copy; <span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span>
      </p>
    </footer>
  </div>
  <script src="../assets/brand.js?v=70"></script>
</body>
</html>
