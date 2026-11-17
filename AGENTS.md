# Ada

Çentiğin altında yaşayan dinamik ada (macOS 26+): şu an çalan müzik (Spotify, Müzik) ve kontrolleri, çalışan yapay zekâ ajanlarının durumu, üstüne bırakılan dosyayı başka biçime dönüştürüp yanına kaydetme. Swift 6.4 araç zinciri, Swift 5 dil modu, SwiftUI + AppKit. Dış bağımlılık yok; dönüştürmede makinedeki araçlar (textutil, cupsfilter, sips, afconvert, avconvert, PDFKit; varsa ffmpeg).

## Komutlar
- Kontrol: `scripts/check.sh` (derleme + bütün testler), tek grup: `scripts/check.sh CatalogTests`
- Çalıştır: `swift run Ada` · Paket: `scripts/make-app.sh` → `dist/Ada.app`
- Görsel kontrol: `.build/debug/Ada --snapshot ada.png [--file örnek.docx]`
- Komut çalıştıramıyorsan kontrolü kullanıcıya bırak; "geçti" deme.

## Klasörler
- `Sources/AdaCore/`: veri tipleri (`Models.swift`), Markdown, dönüştürme kataloğu, çıktı yolu, dönüştürücü, şu an çalan, ajan izleyici, `IslandStore`. Arayüz yok.
- `Sources/Ada/`: pencere (`IslandPanelController`), görünümler, tema.
- `Tests/AdaCoreTests/`: davranışı tanımlayan testler.
- Harita: `docs/map/ada.md`. Bir dosyaya dokunmadan önce oku.

## Kurallar
- Sadece görevin izin verdiği dosyaya dokun. Görev tek dosyaysa tek dosyaya.
- `Models.swift`'i ve dosyalardaki public imzaları değiştirme; gövdeleri doldur.
- Dış paket ekleme. Sadece Foundation, AppKit, SwiftUI, PDFKit, Observation.
- Uyarı ya da hata susturma yok; `try!` ve zorla unwrap ile kestirme yok.
- Süreç çalıştırırken `Process` + `executableURL` + `arguments` kullan; kabuk komutu (`sh -c`) kurma.
- Kullanıcının dosyasının üstüne asla yazma: çıktı yolu her zaman `OutputPath.make`.
- Testleri değiştirme.

## Test
Hızlı, deterministik, güvenilir. Tam politika: Vardiya `kurallar/test-politikasi.md`.
- Önce sadece değişikliğin etkilediği testleri çalıştır (`scripts/check.sh CatalogTests` gibi); bütün paket sadece teslimden önce ya da arayüz / çok modüllü değişiklikte.
- Testte keyfi bekleme (`sleep`, sabit gecikme) yok: zamanı enjekte et ya da koşul bekle. İstisna: gerçek donanım sayacı ölçen testler.
- Test gerçek saate, rastgeleliğe, çalışma sırasına, paylaşılan duruma ya da ağa bağlı olmasın; geçici klasör ve sabit veri kullan.
- Kararsız (flaky) test hata sayılır: geçsin diye yeniden çalıştırma, sebebini bul ve yaz.
- Test başarısızsa: hata satırını oku, sebep üründe mi testte mi ortamda mı belirle, kök sebebi düzelt, sadece etkilenen testleri yeniden çalıştır.
- Hız için asla: assertion silme, beklentiyi gevşetme, testi atlama ya da kapatma, hatayı gizleme, gerçek entegrasyon testini mock'la değiştirme.
- Testleri değiştirmen gerekiyorsa (görev açıkça istemediyse) dur ve sor.

## Teslim
- Bitince 1–3 cümle: ne yaptın, hangi dosya. Yapmadığın bir şeyi yaptım deme.

## Ajanlar için (Vardiya)
Vardiya Mimarisi: Claude iskeleti ve arayüzleri yazar, Qwen tek dosyalık görevleri doldurur, kontroller (`scripts/check.sh`) ve Gemma incelemesi doğrular.
