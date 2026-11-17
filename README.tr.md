# Islet

Çentiğin altında yaşayan dinamik ada (macOS 26+):
- Şu an çalan müzik (Spotify, Müzik) ve kontroller
- Çalışan yapay zekâ ajanlarının durumu (Claude Code, Qwen, Gemma, agent run, OpenCode)
- Dosyayı adaya bırak, biçim seç: PDF, DOCX, TXT, RTF, HTML, ODT, Markdown, görseller (PNG, JPEG, HEIC, TIFF), ses (M4A, WAV, AIFF, CAF, FLAC; ffmpeg varsa MP3), video (MP4, M4A). Çıktı kaynağın yanına kaydedilir.

```sh
swift run Islet
scripts/make-app.sh      # dist/Islet.app
scripts/check.sh         # derleme + testler
.build/debug/Islet --snapshot islet.png [--file örnek.docx] [--live]   # görsel kontrol
.build/debug/Islet --selftest   # adayı sahte fareyle açıp kapar, dosya bırakır; çökme ve pencere kontrolü
```

Vardiya Mimarisi ile geliştirildi: Claude iskeleti yazdı, Qwen 3.8 (local) dosyaları doldurdu, kontroller ve Gemma incelemesi doğruladı.

İlk açılışta Spotify ya da Müzik çalıyorsa macOS, Islet'in bu uygulamaları kontrol etmesi için izin ister (Sistem Ayarları → Gizlilik ve Güvenlik → Otomasyon).
