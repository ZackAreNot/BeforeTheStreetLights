# Post-Process Shader Stack

Semua map produksi memakai scene reusable:

`res://scenes/visual/post_process_stack.tscn`

## Cara memilih shader

1. Buka scene map.
2. Pilih node `CozyPostProcess`.
3. Di Inspector, buka kategori **Pilih Shader**.
4. Centang dua atau tiga shader yang ingin dipakai.
5. Atur intensitasnya pada kategori **Kekuatan Shader**.

`Effects Enabled` adalah sakelar utama. Mematikannya tidak menghapus pilihan shader lain.

## Efek

- **Cozy Grade**: shader lama; warna lebih hangat, shadow sedikit dingin, glow dan vignette tipis.
- **Soft Bloom**: melembutkan area terang seperti lampu dan langit.
- **Filmic Tone**: mengangkat shadow serta menahan highlight dengan kurva yang halus.
- **Ambient Haze**: menambah kedalaman udara tipis di sekitar horizon.
- **Subtle Grain**: memberi tekstur sangat ringan agar vector tidak terasa steril.
- **Soft Vignette**: mengarahkan fokus ke tengah layar.
- **OLED Color**: menaikkan color volume dan kontras dengan highlight tetap lembut.
- **AMOLED Punch**: menghasilkan hitam lebih dalam dan warna yang lebih tegas.
- **Atmospheric Wind**: refraksi udara bergerak sangat tipis, terutama pada area atas layar.

Untuk Atmospheric Wind, kekuatan `0.5-1.0` terasa realistis. Nilai di atas `1.5` lebih cocok untuk momen bergaya atau cuaca kuat.

## Kombinasi aman

- **Default bersih**: Cozy Grade.
- **Cozy lembut**: Cozy Grade + Soft Bloom.
- **Sore sinematik**: Cozy Grade + Filmic Tone + Soft Bloom.
- **Udara kota**: Filmic Tone + Ambient Haze + Soft Vignette.
- **Tekstur organik**: Cozy Grade + Subtle Grain.
- **OLED nyaman**: OLED Color + Soft Bloom + Subtle Grain.
- **AMOLED malam**: AMOLED Punch + Soft Bloom + Soft Vignette.
- **Lingkungan hidup**: Cozy Grade + Ambient Haze + Atmospheric Wind.

Gunakan dua atau tiga efek untuk gameplay. Menyalakan seluruh efek cocok untuk eksperimen, tetapi menambah biaya render karena setiap efek membaca layar kembali.
Pilih salah satu antara OLED Color atau AMOLED Punch untuk hasil paling terkontrol.
