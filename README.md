# modul-citra

Pemrosesan **citra** untuk bahasa [Tenun](https://github.com/TenunLang/Tenun) — muat gambar mentah, pra-pemrosesan, dan segmentasi. Dipadukan dengan [`modul-belajar`](https://github.com/TenunLang/modul-belajar) menjadi pipeline **OCR** end-to-end, murni Tenun.

## Pasang

```
tenun add citra
```

```tenun
impor "citra";
```

## Format gambar

- **PNG** 8-bit (grayscale/RGB/RGBA/palette) — via `citra_png`, memakai builtin compiler `bacaGambar` (decode PNG bawaan: zlib inflate + unfilter).
- **PGM** (P2) & **PPM** (P3) mentah — via `citra_muat_pgm` / `citra_muat_ppm`.

> Decode **JPG** belum ada. Konversi ke PNG dulu: `magick ktp.jpg ktp.png`.

## Representasi

Citra adalah `[]desimal`: `c[0]` = lebar, `c[1]` = tinggi, `c[2..]` = piksel (0.0–1.0) row-major. Larik bertipe rujukan, jadi `citra_set` mengubah di tempat.

## Contoh

```tenun
impor "citra";

biar g: []desimal = citra_muat_pgm("angka.pgm");
biar b: []desimal = citra_ambang(g, 0.5);        // binarisasi
citra_tampil(b);                                  // pratinjau ASCII

biar kotak: []desimal = segmen_kolom(b);          // batas-x tiap karakter
biar potongan: []desimal = citra_potong(b, 0, 0, 5, citra_tinggi(b));
biar kecil: []desimal = citra_ubah_ukuran(potongan, 5, 7);
biar vektor: []desimal = citra_ke_vektor(kecil);  // -> masukan classifier
```

## OCR end-to-end (citra + belajar)

Pipeline: PNG -> grayscale -> balik -> ambang -> segmentasi kolom -> per-glyph
bounding-box -> resize 12x16 -> classifier MLP (`modul-belajar`).

Model dilatih pada **dataset digit cetak multi-font** (19 font Windows, lihat
`tools/`). Tenun berperan sebagai engine: latih sekali, simpan, muat, inferensi.

```
# 1. buat dataset + latih (sekali) -> model_font.txt
powershell -ExecutionPolicy Bypass -File tools/latih.ps1 -Dataset

# 2. baca digit dari PNG mana pun
$ tenun run examples/ocr_baca.tenun nik.png
nik.png
terbaca: 3674072257025006
```

Contoh `examples/ocr_nik.tenun` membaca NIK 16-digit dari `nik.png` (font asli,
anti-alias) dengan benar. `examples/ocr_gambar.tenun` versi PGM/bitmap toy.

> Catatan: training berjalan di VM dan mengalokasi banyak larik sementara
> (Tenun belum punya GC), jadi jaga ukuran dataset×epok wajar (mis. 380 sampel
> × 140 epok). Untuk model besar (MNIST), latih di luar lalu muat — lihat `tools/`.

## Struktur folder

```
modul-citra/
  tenun.json
  README.md
  src/
    citra.tenun            titik masuk; mengimpor seluruh bagian
    core/
      citra.tenun          representasi & akses piksel, citra_baru, ke_vektor, tampil
      muat.tenun           muat PGM (P2) / PPM (P3), simpan PGM
      proses.tenun         ambang, ambang_auto, balik, ubah_ukuran, potong
      segmen.tenun         proyeksi x/y, segmen_kolom, segmen_baris
  examples/
    ocr_baca.tenun         OCR generik: baca digit dari PNG (path via argumen)
    ocr_nik.tenun          baca NIK 16-digit dari nik.png
    ocr_latih_dataset.tenun latih classifier dari dataset multi-font
    ocr_gambar.tenun       OCR digit dari PGM/bitmap toy
  tools/
    buat_dataset.ps1       render dataset digit cetak 19 font -> digit_dataset.txt
    latih.ps1              regen dataset + latih + uji baca
    latih_mnist.py         (opsional) latih MNIST -> format model Tenun
  digit_dataset.txt        dataset digit cetak (380 sampel, 19 font)
  model_font.txt           model terlatih (siap pakai)
  nik.png                  contoh gambar NIK
  angka.pgm                contoh gambar "357"
```

## Acuan API

### Memuat (`core/muat.tenun`)
`citra_muat_pgm(path)` · `citra_muat_ppm(path)` · `citra_simpan_pgm(c, path)`

### Akses (`core/citra.tenun`)
`citra_lebar`, `citra_tinggi`, `citra_piksel(c,x,y)`, `citra_set(c,x,y,v)`, `citra_baru(l,t,isi)`, `citra_ke_vektor(c)`, `citra_tampil(c)`

### Pra-pemrosesan (`core/proses.tenun`)
`citra_ambang(c, t)`, `citra_ambang_auto(c)`, `citra_balik(c)`, `citra_ubah_ukuran(c, l, t)`, `citra_potong(c, x0, y0, w, h)`

### Segmentasi (`core/segmen.tenun`)
`citra_proyeksi_x(c)`, `citra_proyeksi_y(c)`, `segmen_kolom(c)`, `segmen_baris(c)`

## Catatan

- Untuk teks gelap di latar terang, pakai `citra_balik` setelah `citra_ambang` agar teks bernilai 1.0 (sesuai harapan classifier).
- Berjalan pada VM (`tenun run`).

## Lisensi

MIT.
