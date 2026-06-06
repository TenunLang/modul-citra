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

Modul memuat gambar **mentah tanpa kompresi**: **PGM** (P2, grayscale) dan **PPM** (P3, RGB). Foto JPG/PNG harus dikonversi dahulu, mis. dengan ImageMagick:

```
magick ktp.jpg ktp.pgm
```

> Decode JPG/PNG langsung belum tersedia di compiler — perlu builtin `bacaGambar` (rencana). Sampai itu ada, konversi ke PGM/PPM dulu.

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

`examples/ocr_gambar.tenun` memuat PGM berisi deretan digit, mensegmentasi tiap karakter, mengubah ukuran ke 7x5, lalu mengenalinya dengan MLP dari `modul-belajar`:

```
$ tenun run examples/ocr_gambar.tenun
jumlah karakter terdeteksi:
3
teks terbaca:
357
```

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
    ocr_gambar.tenun       OCR digit dari gambar (citra + belajar)
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
