# Before The Streetlights

Vertical slice game naratif 2D side-scrolling tentang Nara yang kembali ke Kota Ranting dan membantu persiapan Festival Lampu Jalan.

Dokumen utama untuk GDD, konteks implementasi, status Map 1, keputusan desain, dan handoff agent tersedia di [`GDD_AND_AI_HANDOFF.md`](GDD_AND_AI_HANDOFF.md). Baca dokumen tersebut sebelum melanjutkan pengembangan.

Semua visual prototype dunia dibuat orisinal sebagai SVG yang mudah diganti. Arah visual memakai bentuk flat vector yang ekspresif dan detail kota kecil Indonesia, tanpa menyalin aset game referensi.

## Menjalankan Proyek

1. Gunakan Godot `4.6.2` atau versi `4.6.x` yang kompatibel.
2. Import folder proyek ini dari Godot Project Manager.
3. Pastikan `Project > Project Settings > Plugins > Dialogic` berstatus `Enabled`.
4. Tekan `F6` pada `res://scenes/main.tscn` atau tekan `F5` untuk menjalankan game.

Dialogic 2 Alpha 19 sudah disertakan di `addons/dialogic`, jadi tidak perlu mengunduh addon lagi setelah clone.

Versi vendored ini membawa patch kompatibilitas lokal untuk cleanup subsystem pada Godot 4.6. Setelah mengganti atau memperbarui folder addon, jalankan kembali smoke test dialog dan shutdown.

## Kontrol

- `A/D` atau panah kiri/kanan: berjalan.
- `Shift`: berlari.
- `Space`: melompat; pada minigame napas digunakan untuk tarik dan buang napas.
- `E`: berinteraksi dengan NPC, objek, dan pintu keluar area.
- `Enter` atau `Space`: melanjutkan dialog.
- Mouse atau keyboard: memilih respons dialog.
- `Esc`: pause saat eksplorasi atau minigame.

## Flow Game

Tombol `MULAI` sekarang membuka production Map 1 di `scenes/new_maps/map1/map1_layering_test.tscn`. Map ini menjadi awal flow utama dan memuat opening taxi, guide kontrol, interaksi lingkungan, serta pertemuan dengan Bimo.

Transisi dari menu menutup layar dengan shutter hitam miring, menampilkan siluet putih Nara, mengganti scene saat layar tertutup, lalu membuka Map 1 dari tengah. Lima area vector lama dan empat minigame tetap disimpan sebagai vertical slice legacy sampai production map berikutnya selesai dimigrasikan.

## Dialogic

- Karakter: `dialogic/characters/*.dch`
- Timeline: `dialogic/timelines/*.dtl`
- Tema textbox dan choice: `dialogic/styles/streetlights_style.tres`
- Integrasi quest, kontrol pemain, animasi, dan follow-up minigame: `scripts/core/dialogue_bridge.gd`

Untuk mengedit dialog, buka tab `Dialogic` di editor lalu pilih timeline. File `.dtl` juga bisa diedit sebagai teks. Jangan menghapus autoload `Dialogic` atau `DialogueBridge` dari `project.godot`.

## Struktur Utama

- `scenes/areas/`: lima area dunia.
- `scenes/new_maps/map1/`: production Map 1 yang menjadi scene awal game.
- `scenes/player/`: scene player dan cutout rig Nara.
- `scenes/minigames/`: bakery, klinik, kabel, dan napas.
- `scenes/components/`: interaction zone dan komponen dunia yang dapat dipakai ulang.
- `scenes/ui/`: HUD, loading, pause, dan ending.
- `assets/vector/world/`: background SVG 3200x1120 per area.
- `assets/vector/characters/`: NPC vector placeholder.
- `scripts/core/game_flow.gd`: state quest, inventory, loading, dan perpindahan scene.
- `scenes/qa/`: smoke test timeline, flow, visual capture, dan logika minigame.
- `GDD_AND_AI_HANDOFF.md`: living GDD, status implementasi, dan konteks handoff.

## QA

Jalankan dari root proyek dengan executable Godot tersedia sebagai `godot`:

```powershell
godot --headless --path . res://scenes/qa/flow_smoke.tscn
godot --headless --path . res://scenes/qa/minigame_logic_smoke.tscn
```

Smoke test dialog memakai renderer karena juga membuat screenshot:

```powershell
godot --path . res://scenes/qa/dialogue_smoke.tscn
```

## Export Windows

1. Dari Godot pilih `Editor > Manage Export Templates` dan pasang template `4.6.2` bila belum ada.
2. Buka `Project > Export`.
3. Pilih preset `Windows Desktop` yang sudah tersedia.
4. Export ke `builds/BeforeTheStreetlights.exe`; preset sudah memakai `x86_64` dan PCK tertanam.
5. Commit source proyeknya, bukan file `.exe` atau `.pck`; keduanya sudah diabaikan `.gitignore`.

Game saat ini sudah dapat dimainkan dari menu sampai ending sebagai vertical slice. SVG dunia dan NPC masih berfungsi sebagai aset produksi sementara sampai ilustrasi final tersedia.
