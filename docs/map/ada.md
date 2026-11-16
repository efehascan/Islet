# Harita: Ada
son doğrulama: (ilk commit)

## Dosyalar
- `Sources/AdaCore/Models.swift`: `NowPlayingInfo`, `MediaCommand`, `AgentKind`, `AgentActivity`, `FileKind`, `ConversionTool`, `ConversionOption`, `ConversionStatus`, `ConversionError`. Değiştirilmez.
- `Markdown.swift`: `Markdown.html(_:title:)` → tam HTML belgesi.
- `ConversionCatalog.swift`: `kind(forExtension:)`, `options(for:ffmpegAvailable:)`.
- `OutputPath.swift`: `OutputPath.make(for:ext:)` → kaynağın klasöründe, çakışmayan ad ("Ad.pdf", "Ad (1).pdf", …).
- `Converter.swift`: `convert(_:option:) async throws -> URL`.
- `NowPlayingProvider.swift`: `current()`, `send(_:to:)`, `static parse(_:app:)`.
- `AgentMonitor.swift`: `sample() async`, `static parseProcesses(_:)`, `static parseProxyStats(_:now:)`.
- `IslandStore.swift`: `@MainActor @Observable`; medya, ajanlar, bırakılan dosya, seçenekler, durum.
- Arayüz (`Sources/Ada/`): `AdaApp` (AppDelegate), `IslandPanelController` (NSPanel, boyut isExpanded'a göre), `Theme` (renkler, ölçüler), `IslandView` (kapalı/açık ada), `MediaSection`, `AgentsSection`, `DropSection`, `Snapshot`.

## Dönüştürme kuralları
- Seçenek kimliği "<kaynak uzantısı küçük harf>-<hedef>", başlık hedefin büyük harfi ("PDF"), outputExtension hedef.
- Hedef sırası (kaynağın kendi uzantısı çıkarılır; jpg = jpeg sayılır):
  - document (docx, doc, rtf, odt, txt, html, htm): pdf (cupsfilter), docx, txt, rtf, html, odt (textutil)
  - pdf: txt (pdfText), png (pdfImages)
  - markdown (md, markdown): html, pdf, docx (hepsi .markdown)
  - image (png, jpg, jpeg, heic, tiff, tif, gif, bmp, webp): png, jpeg, heic, tiff, pdf (sips)
  - audio (mp3, wav, m4a, aiff, aif, caf, flac, aac): m4a, wav, aiff, caf, flac (afconvert); ffmpeg varsa ve kaynak mp3 değilse en sona mp3 (ffmpeg)
  - video (mov, mp4, m4v): mp4, m4a (avconvert)
- Araç komutları:
  - textutil: `/usr/bin/textutil -convert <hedef> <kaynak> -output <çıktı>`
  - cupsfilter: `/usr/sbin/cupsfilter <html ya da txt>` stdout'u PDF; docx/rtf/odt/doc önce textutil ile geçici html'e
  - sips: `/usr/bin/sips -s format <png|jpeg|heic|tiff|pdf> <kaynak> --out <çıktı>`
  - afconvert: m4a `-f m4af -d aac`, wav `-f WAVE -d LEI16`, aiff `-f AIFF -d BEI16`, caf `-f caff -d aac`, flac `-f flac -d flac`; `/usr/bin/afconvert <ayarlar> <kaynak> <çıktı>`
  - avconvert: `/usr/bin/avconvert --source <k> --output <ç> --preset PresetHighestQuality` (mp4) ya da `PresetAppleM4A` (m4a), `--replace`
  - markdown: html → `Markdown.html`; pdf → geçici html + cupsfilter; docx → geçici html + textutil
  - pdfText: `PDFDocument(url:)?.string`; pdfImages: her sayfa `"<ad> (sayfa N).png"`, ilk sayfanın URL'si döner
  - ffmpeg: `/opt/homebrew/bin/ffmpeg` ya da `/usr/local/bin/ffmpeg`, `-y -i <k> <ç>`
- Geçici dosyalar `FileManager.default.temporaryDirectory` altında, iş bitince silinir.
- Araç sıfır dışı çıkarsa `ConversionError.toolFailed(tool:message:)` (stderr'in son 300 karakteri).

## Medya ve ajanlar
- AppleScript: `NSAppleScript(source:)`; önce `application "Spotify" is running` kontrolü, sonra Music. Çıktı tek satır, alanlar "||".
- Ajanlar: `ps -axo pid=,etime=,command=` (Process), proxy `http://localhost:11435/stats` (URLSession, 1 sn zaman aşımı). Proxy kapalıysa sadece süreçler.

## Arayüz
- Ada siyah (çentikle birleşir), yazılar beyaz. Kapalı: ince hap (sol: çalan parça kapağı ya da ajan noktası, sağ: dalga ya da ajan sayısı). Açık: üst satır medya, altında ajanlar ve bırakma alanı.
- Fare üstüne gelince açılır, çıkınca kapanır (dönüştürme sürüyorsa kapanmaz). Dosya sürüklenince açılır.
