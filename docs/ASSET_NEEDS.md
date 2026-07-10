# Kebutuhan Aset Final

Prototype sudah memiliki placeholder vector yang bisa dimainkan. Daftar ini adalah urutan aset final yang paling berguna untuk mengganti placeholder tanpa mengubah flow atau script.

## 1. Nara

Berikan master vector asli dalam `.svg`, `.ai`, `.fig`, atau file layer lain yang masih terpisah. PNG gabungan tetap berguna sebagai referensi, tetapi animasi paling stabil membutuhkan bagian tubuh transparan dengan kanvas dan pivot konsisten.

Bagian minimum:

- kepala dan rambut;
- torso;
- lengan atas, lengan bawah, dan tangan kiri/kanan;
- paha, betis, kaus kaki, dan sepatu kiri/kanan;
- ekor;
- ekspresi mata dan mulut bila tersedia.

Pose/animasi sesuai GDD:

- `idle` dan `tired_idle`;
- `walk` dan `run`;
- `jump` dan `fall`;
- `talk`;
- `interact`;
- `shock` atau `flinch`;
- `overwhelmed`;
- `sitting`;
- `holding_item`.

Gunakan arah side-view yang sama untuk semua pose. Posisi telapak kaki harus berada pada baseline yang sama agar karakter tidak terlihat melayang.

## 2. NPC

Prioritas berikutnya adalah Bimo, Tara, Bu Rami, dr. Seno, dan Penjaga Toko. Untuk setiap NPC, idealnya tersedia:

- idle side-view;
- talk ringan;
- satu pose emosional yang khas;
- master vector atau PNG transparan minimal tinggi 900 px.

Placeholder saat ini berada di `assets/vector/characters/` dan dapat diganti satu per satu.

## 3. Lima Area Dunia

Setiap area saat ini memakai kanvas `3200x1120` dan baseline jalan pada `y = 980` di SVG, yang dipetakan ke lantai gameplay `y = 620`.

Area final:

- Halte Kota Ranting;
- Jalan Toko Listrik;
- Toko Kue Bu Rami dan Toko Bunga Tara;
- tanjakan menuju Klinik St. Ranting;
- Taman Festival sebelum dan sesudah lampu menyala.

Untuk parallax, pecah menjadi layer berikut:

- langit;
- bukit atau bangunan jauh;
- bangunan depan;
- kabel, tiang, papan toko, dan foliage;
- foreground opsional.

Detail Indonesia yang dibutuhkan antara lain atap genteng, warung, paving/trotoar, papan toko lokal, kabel udara, pot tanaman, bangku, spanduk lingkungan, dan lampion festival.

## 4. Props dan Minigame

- gulungan kabel dan panel listrik;
- kardus makanan;
- donat kentang, onde-onde, kue sus, dan lemper;
- formulir klinik, pulpen, kotak P3K, dan kartu bantuan;
- colokan/soket merah, hijau, dan biru;
- bangku festival, lampu jalan, lampion, serta dekor panggung.

Placeholder makanan dan kardus berada di `assets/vector/minigames/`.

## 5. UI

- logo final game;
- frame textbox dan choice bila ingin mengganti tema vector sederhana saat ini;
- ikon objective, inventory, interact, pause, dan loading;
- ilustrasi ending atau key art festival.

## 6. Audio

- ambience sore untuk area 1-4 dan ambience malam untuk festival;
- langkah kaki normal dan berlari;
- suara toko, jalan, klinik, dan keramaian festival;
- bunyi drag/drop makanan, formulir, kabel tersambung, serta lampu menyala;
- typing sound ringan per karakter;
- musik tema utama, tekanan saat kabel, dan resolusi saat ending.

## Format dan Penamaan

- Vector: SVG dengan semua font dikonversi ke path, atau sertakan fontnya.
- Raster transparan: PNG tanpa margin kosong berlebihan.
- Background: pertahankan rasio `3200x1120` atau berikan source yang bisa disesuaikan.
- Audio: WAV untuk SFX pendek, OGG untuk ambience dan musik.
- Contoh nama: `nara_walk_side.svg`, `tara_talk.png`, `area03_bakery_foreground.svg`, `sfx_cable_connect.wav`.

Jangan mengganti ukuran atau pivot aset langsung di banyak scene. Masukkan aset final ke scene karakter/area induknya agar seluruh instance tetap konsisten.
