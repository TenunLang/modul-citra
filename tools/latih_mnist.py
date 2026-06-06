#!/usr/bin/env python3
"""Latih MLP pada dataset MNIST (terpercaya) lalu EKSPOR ke format model Tenun.

Tenun berperan sebagai engine inferensi: skrip ini hanya melatih di luar
(memakai numpy), hasilnya dimuat Tenun via jar_muat_bobot/jar_muat_bias.

Butuh: numpy + berkas MNIST IDX (train-images-idx3-ubyte, train-labels-idx1-ubyte).
Unduh dari http://yann.lecun.com/exdb/mnist/ (atau mirror) bila ada koneksi.

Pakai:
    python latih_mnist.py <dir_mnist> <model_keluar.txt> [hidden] [epoch]

Format model Tenun (3 baris teks):
    baris1: arsitektur, mis. "784,64,10"
    baris2: semua bobot (row-major, per-lapisan): bobot[l][o][i]
    baris3: semua bias: bias[l][o]
Catatan: MNIST 28x28 -> set masukan classifier Tenun ke 784 dan normalisasi
piksel 1 - gray/255 agar konsisten dengan pipeline citra (tinta = tinggi).
"""
import sys, struct, os
import numpy as np


def baca_idx_gambar(path):
    with open(path, "rb") as f:
        magic, n, r, c = struct.unpack(">IIII", f.read(16))
        data = np.frombuffer(f.read(), dtype=np.uint8).reshape(n, r * c)
    return data.astype(np.float64) / 255.0


def baca_idx_label(path):
    with open(path, "rb") as f:
        magic, n = struct.unpack(">II", f.read(8))
        return np.frombuffer(f.read(), dtype=np.uint8)


def sigmoid(z):
    return 1.0 / (1.0 + np.exp(-z))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return
    d = sys.argv[1]
    keluar = sys.argv[2]
    hidden = int(sys.argv[3]) if len(sys.argv) > 3 else 64
    epoch = int(sys.argv[4]) if len(sys.argv) > 4 else 20

    X = baca_idx_gambar(os.path.join(d, "train-images-idx3-ubyte"))
    y = baca_idx_label(os.path.join(d, "train-labels-idx1-ubyte"))
    # konsisten dgn pipeline Tenun: tinta = 1 - gray
    X = 1.0 - X
    Y = np.eye(10)[y]

    rng = np.random.default_rng(0)
    W1 = rng.uniform(-0.1, 0.1, (hidden, 784))
    b1 = np.zeros(hidden)
    W2 = rng.uniform(-0.1, 0.1, (10, hidden))
    b2 = np.zeros(10)
    laju = 0.5
    n = X.shape[0]
    batch = 64

    for e in range(epoch):
        idx = rng.permutation(n)
        for s in range(0, n, batch):
            bi = idx[s:s + batch]
            xb, yb = X[bi], Y[bi]
            a1 = sigmoid(xb @ W1.T + b1)
            a2 = sigmoid(a1 @ W2.T + b2)
            d2 = (a2 - yb) * a2 * (1 - a2)
            d1 = (d2 @ W2) * a1 * (1 - a1)
            m = xb.shape[0]
            W2 -= laju * d2.T @ a1 / m
            b2 -= laju * d2.mean(0)
            W1 -= laju * d1.T @ xb / m
            b1 -= laju * d1.mean(0)
        acc = (sigmoid(sigmoid(X @ W1.T + b1) @ W2.T + b2).argmax(1) == y).mean()
        print(f"epoch {e+1}/{epoch} akurasi {acc:.4f}")

    lap = [784, hidden, 10]
    bobot = list(W1.flatten()) + list(W2.flatten())
    bias = list(b1.flatten()) + list(b2.flatten())
    with open(keluar, "w") as f:
        f.write(",".join(str(v) for v in lap) + "\n")
        f.write(",".join(repr(v) for v in bobot) + "\n")
        f.write(",".join(repr(v) for v in bias))
    print("model Tenun ditulis:", keluar)


if __name__ == "__main__":
    main()
