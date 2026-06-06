# tools — penyiapan dataset & model

Tenun berperan sebagai **engine inferensi**: model dilatih di luar (dataset
terpercaya / font asli), lalu dimuat Tenun via `jar_muat_bobot`/`jar_muat_bias`.

## buat_dataset.ps1 — dataset digit cetak multi-font

Render digit 0-9 dari 19 font Windows (Arial, Calibri, Times, Consolas, dst.) ×
ukuran × gaya, bounding-box crop, resize nearest ke 12x16. Pra-pemrosesan SAMA
dengan `examples/ocr_baca.tenun` sehingga latih = inferensi.

```
powershell -ExecutionPolicy Bypass -File tools/buat_dataset.ps1
```

Menghasilkan `digit_dataset.txt` (760 sampel). Untuk OCR teks **cetak** (mis.
KTP), korpus multi-font lebih tepat daripada MNIST (yang tulisan tangan).

Latih + simpan model di Tenun:

```
tenun run examples/ocr_latih_dataset.tenun     # -> model_font.txt
```

## latih_mnist.py — dataset MNIST (terpercaya) -> format Tenun

Bila ada koneksi & numpy: latih MLP pada MNIST, ekspor ke format model Tenun.
Tenun cukup memuat hasilnya.

```
python tools/latih_mnist.py <dir_mnist> model_mnist.txt 64 20
tenun run examples/ocr_baca.tenun <gambar.png>   # pakai model hasil
```

Unduh MNIST IDX dari http://yann.lecun.com/exdb/mnist/ (atau mirror).

## Format model Tenun

Berkas teks 3 baris yang dibaca `jar_muat_*`:

```
784,64,10                         <- arsitektur [masukan, tersembunyi, keluaran]
<semua bobot, koma>               <- bobot[l][o][i] row-major per lapisan
<semua bias, koma>                <- bias[l][o]
```

Model dari kerangka lain (Keras/PyTorch MLP dense) bisa diekspor ke format ini:
ratakan bobot tiap lapisan `[keluaran][masukan]` lalu bias `[keluaran]`,
gabung antar-lapisan, tulis tiga baris di atas.
