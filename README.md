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

- Player dummy Nara dengan `CharacterBody2D` dan sprite sheet sementara.
- Movement side-scrolling: jalan, sprint ringan, lompat kecil, gravity.
- Kamera follow dengan batas level.
- Level linear Kota Ranting sudah berbasis scene:
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
- `scenes/maps/map_01_city_ranting.tscn`: scene map pertama. Background, collision, label lokasi, marker, spawn point, dan dekor utama ada di sini.
- `scenes/player/player.tscn`: scene player.
- `scenes/ui/hud.tscn`: scene HUD objective dan location label.
- `scripts/player_controller.gd`: movement player.
- `scripts/world/map_controller.gd`: wiring map, spawn player, marker lokasi, dan HUD.
- `scripts/world/location_marker.gd`: data lokasi dan objective untuk setiap marker.
- `scripts/ui/hud.gd`: fungsi update teks HUD.
- `docs/ASSET_NEEDS.md`: daftar asset yang dibutuhkan untuk fase awal.

## Cara Edit Map

Edit visual dan tatanan level dari `scenes/maps/map_01_city_ranting.tscn`.

- `Environment/BackgroundChunks`: layer background yang diulang sepanjang level.
- `Decor/LocationLabels`: label nama lokasi yang bisa digeser langsung di editor.
- `Decor/LampPosts`: dekor lampu jalan.
- `LevelGeometry`: collision ground dan step.
- `Markers`: area trigger objective.
- `SpawnPoints/PlayerSpawn`: posisi awal Nara.

## Next Step

1. Tambah interaction system untuk NPC/objek.
2. Setup Dialogic untuk dialog Bimo dan quest pertama.
3. Tambah quest manager ringan untuk objective dan item festival.
4. Mulai pecah interior toko/klinik menjadi scene terpisah.
5. Ganti asset dummy dengan asset original Before The Streetlights.
