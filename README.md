# Ada

Çentiğin altında yaşayan dinamik ada (macOS 26+):
- Şu an çalan müzik (Spotify, Müzik) ve kontroller
- Çalışan yapay zekâ ajanlarının durumu (Claude Code, Qwen, Gemma, agent run, OpenCode)
- Dosyayı adaya bırak, biçim seç: PDF, DOCX, TXT, RTF, HTML, ODT, Markdown, görseller (PNG, JPEG, HEIC, TIFF), ses (M4A, WAV, AIFF, CAF, FLAC; ffmpeg varsa MP3), video (MP4, M4A). Çıktı kaynağın yanına kaydedilir.

```sh
swift run Ada
scripts/make-app.sh      # dist/Ada.app
scripts/check.sh         # derleme + testler
```

Vardiya Mimarisi ile geliştirildi: Claude iskeleti yazdı, Qwen 3.8 (local) dosyaları doldurdu, kontroller ve Gemma incelemesi doğruladı.
