<%
Option Explicit
Response.CodePage = 65001
Response.Charset = "UTF-8"
Response.Buffer = True
Response.CacheControl = "no-cache"
Response.AddHeader "Cache-Control", "no-cache, no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"
Response.Expires = -1
%><!--#include file="config.asp"--><%

Dim formError, formSuccess, formNotice
formError = ""
formSuccess = False
formNotice = ""

If SMTP_USERNAME = "YOUR_SES_SMTP_USERNAME" Or RECAPTCHA_SITE_KEY = "YOUR_RECAPTCHA_SITE_KEY" Then
  formError = "Feedback is not configured yet. Edit feedback/config.asp with your AWS SES SMTP and Google reCAPTCHA keys (see config.example.asp)."
End If

If formError = "" And UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
  Call ProcessFeedback()
End If

Sub ProcessFeedback()
  Dim honeypot, feedbackType, message, emailAddr, displayName, appVersion
  Dim captchaToken, captchaOk, i, shotCount, tmpFolder, mailBody
  Dim fieldName, fieldData, fieldType, bytes, fileName, savePath
  Dim attachments, attachCount

  honeypot = Trim(Request.Form("company_website"))
  If Len(honeypot) > 0 Then
    formSuccess = True
    formNotice = "Thanks - your feedback was sent."
    Exit Sub
  End If

  feedbackType = SanitizeOneLine(Request.Form("feedback_type"))
  message = Trim(CStr(Request.Form("message") & ""))
  emailAddr = SanitizeOneLine(Request.Form("email"))
  displayName = SanitizeOneLine(Request.Form("name"))
  appVersion = SanitizeOneLine(Request.Form("app_version"))
  captchaToken = Trim(CStr(Request.Form("g-recaptcha-response") & ""))

  If feedbackType = "" Then feedbackType = "other"
  If Len(message) < 10 Then
    formError = "Please enter a bit more detail (at least a sentence)."
    Exit Sub
  End If
  If Len(message) > 8000 Then
    formError = "Message is too long. Please keep it under 8000 characters."
    Exit Sub
  End If
  If emailAddr <> "" And InStr(emailAddr, "@") < 2 Then
    formError = "That email address does not look valid."
    Exit Sub
  End If

  captchaOk = VerifyRecaptcha(captchaToken)
  If Not captchaOk Then
    formError = "Please complete the CAPTCHA and try again."
    Exit Sub
  End If

  tmpFolder = Server.MapPath("tmp")
  EnsureFolder tmpFolder

  attachCount = 0
  ReDim attachments(MAX_SCREENSHOTS)

  For i = 0 To MAX_SCREENSHOTS - 1
    fieldName = Trim(CStr(Request.Form("shot_name_" & i) & ""))
    fieldData = Trim(CStr(Request.Form("shot_data_" & i) & ""))
    fieldType = LCase(Trim(CStr(Request.Form("shot_type_" & i) & "")))
    If fieldData <> "" And fieldName <> "" Then
      If InStr("," & ALLOWED_SCREENSHOT_TYPES & ",", "," & fieldType & ",") = 0 Then
        formError = "Screenshots must be JPEG, PNG, WebP, or GIF."
        Call CleanupAttachments(attachments, attachCount)
        Exit Sub
      End If
      bytes = Base64ToBytes(StripDataUrl(fieldData))
      If IsEmpty(bytes) Then
        formError = "One screenshot could not be read. Try another image."
        Call CleanupAttachments(attachments, attachCount)
        Exit Sub
      End If
      If UBound(bytes) + 1 > MAX_SCREENSHOT_BYTES Then
        formError = "Each screenshot must be under 5 MB."
        Call CleanupAttachments(attachments, attachCount)
        Exit Sub
      End If
      fileName = SafeFileName(fieldName, fieldType, i)
      savePath = tmpFolder & "\" & fileName
      If Not SaveBytesToFile(bytes, savePath) Then
        formError = "Could not save an uploaded screenshot. Please try again."
        Call CleanupAttachments(attachments, attachCount)
        Exit Sub
      End If
      attachments(attachCount) = savePath
      attachCount = attachCount + 1
    End If
  Next

  mailBody = BuildMailBody(feedbackType, message, emailAddr, displayName, appVersion, attachCount)

  On Error Resume Next
  Call SendFeedbackMail(feedbackType, mailBody, emailAddr, displayName, attachments, attachCount)
  If Err.Number <> 0 Then
    formError = "Could not send email right now (" & Server.HTMLEncode(Err.Description) & "). Please email support@dozealert.app instead."
    Err.Clear
    Call CleanupAttachments(attachments, attachCount)
    On Error GoTo 0
    Exit Sub
  End If
  On Error GoTo 0

  Call CleanupAttachments(attachments, attachCount)
  formSuccess = True
  formNotice = "Thanks - your feedback was sent to the DozeAlert team."
End Sub

Function SanitizeOneLine(rawValue)
  Dim value
  value = Trim(CStr(rawValue & ""))
  value = Replace(value, vbCr, " ")
  value = Replace(value, vbLf, " ")
  If Len(value) > 200 Then value = Left(value, 200)
  SanitizeOneLine = value
End Function

Function StripDataUrl(dataUrl)
  Dim commaPos
  commaPos = InStr(dataUrl, ",")
  If commaPos > 0 Then
    StripDataUrl = Mid(dataUrl, commaPos + 1)
  Else
    StripDataUrl = dataUrl
  End If
End Function

Function SafeFileName(originalName, contentType, index)
  Dim ext, baseName, cleaned, ch, i
  ext = ExtForType(contentType)
  baseName = originalName
  If InStrRev(baseName, ".") > 0 Then
    baseName = Left(baseName, InStrRev(baseName, ".") - 1)
  End If
  cleaned = ""
  For i = 1 To Len(baseName)
    ch = Mid(baseName, i, 1)
    If (ch >= "a" And ch <= "z") Or (ch >= "A" And ch <= "Z") Or (ch >= "0" And ch <= "9") Or ch = "-" Or ch = "_" Then
      cleaned = cleaned & ch
    End If
  Next
  If cleaned = "" Then cleaned = "screenshot"
  If Len(cleaned) > 40 Then cleaned = Left(cleaned, 40)
  SafeFileName = "fb_" & Replace(CStr(Timer()), ".", "") & "_" & index & "_" & cleaned & ext
End Function

Function ExtForType(contentType)
  Select Case LCase(contentType)
    Case "image/png"
      ExtForType = ".png"
    Case "image/webp"
      ExtForType = ".webp"
    Case "image/gif"
      ExtForType = ".gif"
    Case Else
      ExtForType = ".jpg"
  End Select
End Function

Sub EnsureFolder(folderPath)
  Dim fs
  Set fs = Server.CreateObject("Scripting.FileSystemObject")
  If Not fs.FolderExists(folderPath) Then
    fs.CreateFolder folderPath
  End If
  Set fs = Nothing
End Sub

Function Base64ToBytes(base64Text)
  Dim xml, node
  On Error Resume Next
  Set xml = Server.CreateObject("MSXML2.DOMDocument.6.0")
  If Err.Number <> 0 Then
    Err.Clear
    Set xml = Server.CreateObject("MSXML2.DOMDocument")
  End If
  If Err.Number <> 0 Then
    Err.Clear
    Base64ToBytes = Empty
    Exit Function
  End If
  Set node = xml.createElement("b64")
  node.dataType = "bin.base64"
  node.text = base64Text
  Base64ToBytes = node.nodeTypedValue
  Set node = Nothing
  Set xml = Nothing
  On Error GoTo 0
End Function

Function SaveBytesToFile(bytes, filePath)
  Dim stream
  On Error Resume Next
  Set stream = Server.CreateObject("ADODB.Stream")
  stream.Type = 1
  stream.Open
  stream.Write bytes
  stream.SaveToFile filePath, 2
  stream.Close
  Set stream = Nothing
  If Err.Number <> 0 Then
    Err.Clear
    SaveBytesToFile = False
  Else
    SaveBytesToFile = True
  End If
  On Error GoTo 0
End Function

Sub CleanupAttachments(attachments, attachCount)
  Dim fs, i
  Set fs = Server.CreateObject("Scripting.FileSystemObject")
  For i = 0 To attachCount - 1
    If attachments(i) <> "" Then
      If fs.FileExists(attachments(i)) Then fs.DeleteFile attachments(i), True
    End If
  Next
  Set fs = Nothing
End Sub

Function VerifyRecaptcha(token)
  Dim http, postData, responseText
  If Len(token) = 0 Then
    VerifyRecaptcha = False
    Exit Function
  End If
  If RECAPTCHA_SECRET_KEY = "YOUR_RECAPTCHA_SECRET_KEY" Or Len(RECAPTCHA_SECRET_KEY) = 0 Then
    VerifyRecaptcha = False
    Exit Function
  End If

  postData = "secret=" & Server.URLEncode(RECAPTCHA_SECRET_KEY) & _
             "&response=" & Server.URLEncode(token) & _
             "&remoteip=" & Server.URLEncode(Request.ServerVariables("REMOTE_ADDR"))

  On Error Resume Next
  Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
  If Err.Number <> 0 Then
    Err.Clear
    Set http = Server.CreateObject("MSXML2.ServerXMLHTTP")
  End If
  http.Open "POST", "https://www.google.com/recaptcha/api/siteverify", False
  http.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
  http.Send postData
  If Err.Number <> 0 Then
    Err.Clear
    VerifyRecaptcha = False
    Set http = Nothing
    On Error GoTo 0
    Exit Function
  End If
  responseText = CStr(http.responseText & "")
  Set http = Nothing
  On Error GoTo 0

  VerifyRecaptcha = (InStr(1, responseText, """success"": true", vbTextCompare) > 0) Or _
                    (InStr(1, responseText, """success"":true", vbTextCompare) > 0)
End Function

Function BuildMailBody(feedbackType, message, emailAddr, displayName, appVersion, shotCount)
  Dim lines
  lines = ""
  lines = lines & "Type: " & feedbackType & vbCrLf
  If displayName <> "" Then lines = lines & "Name: " & displayName & vbCrLf
  If emailAddr <> "" Then lines = lines & "Reply-To: " & emailAddr & vbCrLf
  If appVersion <> "" Then lines = lines & "App version: " & appVersion & vbCrLf
  lines = lines & "Screenshots: " & shotCount & vbCrLf
  lines = lines & "IP: " & Request.ServerVariables("REMOTE_ADDR") & vbCrLf
  lines = lines & "User-Agent: " & Request.ServerVariables("HTTP_USER_AGENT") & vbCrLf
  lines = lines & String(40, "-") & vbCrLf & vbCrLf
  lines = lines & message & vbCrLf
  BuildMailBody = lines
End Function

Sub SendFeedbackMail(feedbackType, bodyText, replyEmail, displayName, attachments, attachCount)
  Dim msg, cfg, schema, i, subjectLine
  schema = "http://schemas.microsoft.com/cdo/configuration/"
  subjectLine = MAIL_SUBJECT_PREFIX & " " & UCase(Left(feedbackType, 1)) & Mid(feedbackType, 2)

  Set cfg = Server.CreateObject("CDO.Configuration")
  With cfg.Fields
    .Item(schema & "sendusing") = 2
    .Item(schema & "smtpserver") = SMTP_HOST
    .Item(schema & "smtpserverport") = SMTP_PORT
    .Item(schema & "smtpauthenticate") = 1
    .Item(schema & "sendusername") = SMTP_USERNAME
    .Item(schema & "sendpassword") = SMTP_PASSWORD
    .Item(schema & "smtpusessl") = SMTP_USE_SSL
    .Item(schema & "smtpconnectiontimeout") = SMTP_TIMEOUT_SECONDS
    .Update
  End With

  Set msg = Server.CreateObject("CDO.Message")
  Set msg.Configuration = cfg
  msg.From = """" & MAIL_FROM_NAME & """ <" & MAIL_FROM & ">"
  msg.To = MAIL_TO
  msg.Subject = subjectLine
  msg.TextBody = bodyText
  If replyEmail <> "" Then
    If displayName <> "" Then
      msg.ReplyTo = """" & displayName & """ <" & replyEmail & ">"
    Else
      msg.ReplyTo = replyEmail
    End If
  End If

  For i = 0 To attachCount - 1
    If attachments(i) <> "" Then
      msg.AddAttachment attachments(i)
    End If
  Next

  msg.Send
  Set msg = Nothing
  Set cfg = Nothing
End Sub

Function H(value)
  H = Server.HTMLEncode(CStr(value & ""))
End Function

Function Prefill(fieldName)
  Dim value
  value = Trim(CStr(Request.Form(fieldName) & ""))
  If value = "" Then value = Trim(CStr(Request.QueryString(fieldName) & ""))
  Prefill = value
End Function

Dim selectedType, prefillMessage, prefillEmail, prefillName, prefillAppVersion
selectedType = SanitizeOneLine(Prefill("feedback_type"))
If selectedType = "" Then selectedType = "bug"
prefillMessage = Prefill("message")
prefillEmail = Prefill("email")
prefillName = Prefill("name")
prefillAppVersion = Prefill("app_version")
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Send feedback, bug reports, or ideas to the DozeAlert team.">
  <meta name="theme-color" content="#0D1B2A">
  <title>Feedback &mdash; DozeAlert</title>
  <link rel="icon" type="image/png" href="../assets/icon-512.png?v=46">
  <link rel="stylesheet" href="../assets/brand.css">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    :root {
      --midnight: #0D1B2A;
      --cyan: #4CC9F0;
      --white: #FFFFFF;
      --muted: #94a3b8;
      --card: #1B3147;
      --radius: 16px;
      --max-width: 640px;
      --danger: #f87171;
      --ok: #4ade80;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
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
      background: radial-gradient(ellipse 80% 50% at 50% -20%, rgba(76, 201, 240, 0.16), transparent);
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
    h1 { font-size: 2rem; margin-bottom: 0.4rem; letter-spacing: -0.02em; }
    .lead { color: var(--muted); margin-bottom: 1.5rem; }
    .card {
      background: var(--card);
      border: 1px solid rgba(76, 201, 240, 0.12);
      border-radius: var(--radius);
      padding: 1.5rem;
      margin-bottom: 1.25rem;
    }
    label {
      display: block;
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 0.4rem;
      color: #e2e8f0;
    }
    .hint { font-weight: 400; color: var(--muted); }
    .field { margin-bottom: 1.15rem; }
    input[type="text"],
    input[type="email"],
    select,
    textarea {
      width: 100%;
      border-radius: 12px;
      border: 1px solid rgba(148, 163, 184, 0.35);
      background: rgba(13, 27, 42, 0.55);
      color: var(--white);
      padding: 0.75rem 0.9rem;
      font: inherit;
    }
    input:focus,
    select:focus,
    textarea:focus {
      outline: 2px solid rgba(76, 201, 240, 0.45);
      border-color: var(--cyan);
    }
    textarea { min-height: 160px; resize: vertical; }
    .type-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 0.6rem;
    }
    @media (min-width: 520px) {
      .type-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
    }
    .type-option {
      position: relative;
    }
    .type-option input {
      position: absolute;
      opacity: 0;
      pointer-events: none;
    }
    .type-option span {
      display: block;
      text-align: center;
      padding: 0.7rem 0.5rem;
      border-radius: 12px;
      border: 1px solid rgba(148, 163, 184, 0.35);
      background: rgba(13, 27, 42, 0.45);
      font-size: 0.875rem;
      font-weight: 600;
      cursor: pointer;
    }
    .type-option input:checked + span {
      border-color: var(--cyan);
      box-shadow: 0 0 0 1px rgba(76, 201, 240, 0.35);
      color: var(--cyan);
    }
    .dropzone {
      border: 1.5px dashed rgba(76, 201, 240, 0.35);
      border-radius: 14px;
      padding: 1.25rem;
      text-align: center;
      color: var(--muted);
      background: rgba(13, 27, 42, 0.35);
      transition: border-color 0.15s ease, background 0.15s ease;
      cursor: pointer;
    }
    .dropzone.dragover {
      border-color: var(--cyan);
      background: rgba(76, 201, 240, 0.08);
      color: var(--white);
    }
    .dropzone strong { color: var(--cyan); font-weight: 600; }
    .previews {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 0.75rem;
      margin-top: 0.9rem;
    }
    .preview {
      position: relative;
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid rgba(148, 163, 184, 0.25);
      background: #0b1724;
      aspect-ratio: 1;
    }
    .preview img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    .preview button {
      position: absolute;
      top: 6px;
      right: 6px;
      border: 0;
      border-radius: 999px;
      width: 28px;
      height: 28px;
      background: rgba(13, 27, 42, 0.85);
      color: var(--white);
      cursor: pointer;
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      align-items: center;
      margin-top: 0.5rem;
    }
    .btn {
      appearance: none;
      border: 0;
      border-radius: 999px;
      padding: 0.85rem 1.4rem;
      font: inherit;
      font-weight: 700;
      cursor: pointer;
      background: var(--cyan);
      color: var(--midnight);
    }
    .btn:disabled {
      opacity: 0.55;
      cursor: not-allowed;
    }
    .btn-secondary {
      background: transparent;
      color: var(--cyan);
      border: 1px solid rgba(76, 201, 240, 0.45);
      text-decoration: none;
      display: inline-flex;
      align-items: center;
    }
    .alert {
      border-radius: 12px;
      padding: 0.9rem 1rem;
      margin-bottom: 1rem;
      font-size: 0.95rem;
    }
    .alert-error {
      background: rgba(248, 113, 113, 0.12);
      border: 1px solid rgba(248, 113, 113, 0.35);
      color: #fecaca;
    }
    .alert-ok {
      background: rgba(74, 222, 128, 0.12);
      border: 1px solid rgba(74, 222, 128, 0.35);
      color: #bbf7d0;
    }
    .hp {
      position: absolute;
      left: -10000px;
      top: auto;
      width: 1px;
      height: 1px;
      overflow: hidden;
    }
    .footer-note {
      color: var(--muted);
      font-size: 0.85rem;
      margin-top: 1rem;
    }
    .footer-note a { color: var(--cyan); }
    .recaptcha-wrap { margin: 1rem 0; }
  </style>
</head>
<body>
  <div class="glow" aria-hidden="true"></div>
  <div class="wrap">
    <p class="nav"><a href="../index.asp">&larr; Back to DozeAlert</a></p>
    <h1>Send feedback</h1>
    <p class="lead">Bugs, ideas, or a quick thank-you &mdash; we read every message.</p>

    <section class="card">
      <% If formSuccess Then %>
        <div class="alert alert-ok"><%= H(formNotice) %></div>
        <div class="actions">
          <a class="btn-secondary" href="index.asp">Send another</a>
          <a class="btn-secondary" href="../index.asp">Back home</a>
        </div>
      <% Else %>
        <% If formError <> "" Then %>
          <div class="alert alert-error"><%= H(formError) %></div>
        <% End If %>

        <form id="feedback-form" method="post" action="index.asp" novalidate>
          <div class="hp" aria-hidden="true">
            <label for="company_website">Company website</label>
            <input type="text" id="company_website" name="company_website" tabindex="-1" autocomplete="off">
          </div>

          <div class="field">
            <label>What is this about?</label>
            <div class="type-grid">
              <label class="type-option">
                <input type="radio" name="feedback_type" value="bug" <% If selectedType = "bug" Then Response.Write "checked" %>>
                <span>Bug</span>
              </label>
              <label class="type-option">
                <input type="radio" name="feedback_type" value="idea" <% If selectedType = "idea" Then Response.Write "checked" %>>
                <span>Idea</span>
              </label>
              <label class="type-option">
                <input type="radio" name="feedback_type" value="praise" <% If selectedType = "praise" Then Response.Write "checked" %>>
                <span>Praise</span>
              </label>
              <label class="type-option">
                <input type="radio" name="feedback_type" value="other" <% If selectedType = "other" Then Response.Write "checked" %>>
                <span>Other</span>
              </label>
            </div>
          </div>

          <div class="field">
            <label for="message">Message</label>
            <textarea id="message" name="message" required maxlength="8000" placeholder="What happened, what you expected, or what you'd like to see..."><%= H(prefillMessage) %></textarea>
          </div>

          <div class="field">
            <label for="email">Email <span class="hint">(optional, for a reply)</span></label>
            <input type="email" id="email" name="email" value="<%= H(prefillEmail) %>" autocomplete="email" placeholder="you@example.com">
          </div>

          <div class="field">
            <label for="name">Name <span class="hint">(optional)</span></label>
            <input type="text" id="name" name="name" value="<%= H(prefillName) %>" autocomplete="name" maxlength="120">
          </div>

          <div class="field">
            <label for="app_version">App version <span class="hint">(optional)</span></label>
            <input type="text" id="app_version" name="app_version" value="<%= H(prefillAppVersion) %>" placeholder="e.g. 1.1.0+45" maxlength="40">
          </div>

          <div class="field">
            <label>Screenshots <span class="hint">(optional, up to 3)</span></label>
            <div class="dropzone" id="dropzone" role="button" tabindex="0" aria-label="Add screenshots">
              <p><strong>Drag &amp; drop</strong> images here, or click to browse</p>
              <p style="margin-top:0.35rem;font-size:0.85rem;">JPEG, PNG, WebP, or GIF &middot; max 5&nbsp;MB each</p>
            </div>
            <input type="file" id="file-input" accept="image/jpeg,image/png,image/webp,image/gif" multiple hidden>
            <div class="previews" id="previews" hidden></div>
            <div id="shot-fields"></div>
          </div>

          <% If formError = "" Or InStr(formError, "configured") = 0 Then %>
          <div class="recaptcha-wrap">
            <div class="g-recaptcha" data-sitekey="<%= H(RECAPTCHA_SITE_KEY) %>"></div>
          </div>
          <% End If %>

          <div class="actions">
            <button class="btn" type="submit" id="submit-btn">Send feedback</button>
            <a class="btn-secondary" href="mailto:support@dozealert.app">Or email support</a>
          </div>
        </form>
      <% End If %>
    </section>

    <p class="footer-note">
      Screenshots and your message are emailed to the DozeAlert team only.
      Google reCAPTCHA is used to reduce spam &mdash;
      see <a href="../privacy/index.asp">Privacy Policy</a>.
    </p>
  </div>

  <script>
    (function () {
      var MAX = <%= MAX_SCREENSHOTS %>;
      var MAX_BYTES = <%= MAX_SCREENSHOT_BYTES %>;
      var allowed = {
        "image/jpeg": true,
        "image/png": true,
        "image/webp": true,
        "image/gif": true
      };
      var dropzone = document.getElementById("dropzone");
      var fileInput = document.getElementById("file-input");
      var previews = document.getElementById("previews");
      var shotFields = document.getElementById("shot-fields");
      var form = document.getElementById("feedback-form");
      var files = [];

      if (!dropzone || !form) return;

      function openPicker() { fileInput.click(); }
      dropzone.addEventListener("click", openPicker);
      dropzone.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          openPicker();
        }
      });
      fileInput.addEventListener("change", function () {
        addFiles(fileInput.files);
        fileInput.value = "";
      });

      ["dragenter", "dragover"].forEach(function (evt) {
        dropzone.addEventListener(evt, function (e) {
          e.preventDefault();
          e.stopPropagation();
          dropzone.classList.add("dragover");
        });
      });
      ["dragleave", "drop"].forEach(function (evt) {
        dropzone.addEventListener(evt, function (e) {
          e.preventDefault();
          e.stopPropagation();
          dropzone.classList.remove("dragover");
        });
      });
      dropzone.addEventListener("drop", function (e) {
        addFiles(e.dataTransfer.files);
      });

      function addFiles(list) {
        Array.prototype.forEach.call(list, function (file) {
          if (files.length >= MAX) return;
          if (!allowed[file.type]) {
            alert("Only JPEG, PNG, WebP, or GIF images are allowed.");
            return;
          }
          if (file.size > MAX_BYTES) {
            alert("Each screenshot must be under 5 MB.");
            return;
          }
          var reader = new FileReader();
          reader.onload = function () {
            files.push({
              name: file.name,
              type: file.type,
              dataUrl: reader.result
            });
            render();
          };
          reader.readAsDataURL(file);
        });
      }

      function render() {
        previews.hidden = files.length === 0;
        previews.innerHTML = "";
        shotFields.innerHTML = "";
        files.forEach(function (file, index) {
          var card = document.createElement("div");
          card.className = "preview";
          var img = document.createElement("img");
          img.src = file.dataUrl;
          img.alt = file.name;
          var remove = document.createElement("button");
          remove.type = "button";
          remove.setAttribute("aria-label", "Remove screenshot");
          remove.textContent = "x";
          remove.addEventListener("click", function () {
            files.splice(index, 1);
            render();
          });
          card.appendChild(img);
          card.appendChild(remove);
          previews.appendChild(card);

          appendHidden("shot_name_" + index, file.name);
          appendHidden("shot_type_" + index, file.type);
          appendHidden("shot_data_" + index, file.dataUrl);
        });
      }

      function appendHidden(name, value) {
        var input = document.createElement("input");
        input.type = "hidden";
        input.name = name;
        input.value = value;
        shotFields.appendChild(input);
      }

      form.addEventListener("submit", function () {
        var btn = document.getElementById("submit-btn");
        if (btn) {
          btn.disabled = true;
          btn.textContent = "Sending...";
        }
      });
    })();
  </script>
</body>
</html>
