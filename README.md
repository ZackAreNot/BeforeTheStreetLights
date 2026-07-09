# Before The Streetlights

Prototype awal untuk game narrative 2D side-scrolling tentang Nara dan Kota Ranting.

## Cara Jalanin

1. Buka folder ini dari Godot 4.x.
2. Jalankan scene utama `res://scenes/main.tscn` atau tekan Play.
3. Kontrol prototype:
   - `A/D` atau arrow key: jalan.
   - `Shift`: jalan cepat ringan.
   - `Space`: lompat kecil.
   - `E`: disiapkan untuk interaksi berikutnya.

## Isi Prototype Sekarang

- Player placeholder Nara dengan `CharacterBody2D`.
- Movement side-scrolling: jalan, sprint ringan, lompat kecil, gravity.
- Kamera follow dengan batas level.
- Level linear Kota Ranting placeholder:
  - Taxi Stop
  - Jalan Utama
  - Toko Listrik
  - Toko Kue Bu Rami
  - Toko Bunga Tara
  - Klinik St. Ranting
  - Taman Festival
- HUD objective sederhana yang berubah saat Nara masuk area lokasi.

## Struktur Folder

- `scenes/main.tscn`: entry point prototype.
- `scenes/player/player.tscn`: scene player.
- `scripts/player_controller.gd`: movement player.
- `scripts/prototype_level.gd`: generator level placeholder dan HUD.
- `docs/ASSET_NEEDS.md`: daftar asset yang dibutuhkan untuk fase awal.

## Next Step

1. Ganti placeholder player dengan sprite Nara.
2. Pecah level procedural menjadi scene lokasi yang lebih mudah diedit.
3. Tambah interaction system untuk NPC/objek.
4. Setup Dialogic untuk dialog Bimo dan quest pertama.
5. Tambah quest manager ringan untuk objective dan item festival.
