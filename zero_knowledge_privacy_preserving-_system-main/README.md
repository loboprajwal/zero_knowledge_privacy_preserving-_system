# zk-MatchID: Offline-First Zero-Knowledge Mobile Authentication

[![Flutter](https://img.shields.io/badge/Flutter-3.35.1-02569B?logo=flutter)](https://flutter.dev)
[![Circom](https://img.shields.io/badge/Circom-2.1+-yellow)](https://docs.circom.io)
[![Groth16](https://img.shields.io/badge/Cryptography-Groth16_BN254-blueviolet)](https://eprint.iacr.org/2016/260)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**zk-MatchID** is a peer-to-peer (P2P), offline-first mobile mutual authentication system. It allows two individuals to perform two-way verification (e.g., Age $\ge$ 18 proof and credential ownership) without transmitting or revealing any personally identifiable information (PII) such as full name, date of birth, or national ID numbers.

---

## Key Features

1. **Local Identity Vault:** Hardware-encrypted identity credentials stored using native mobile security (KeyStore/Keychain) via `VaultService`.
2. **On-Device Proof Generation:** Native Groth16 zero-knowledge proof generation over the BN254 curve executing in $< 2.0$ seconds on mobile hardware.
3. **High-Density Dynamic QR Encoding:** Ascii85 (Base85) payload compression for Groth16 proof coordinates and public inputs.
4. **Offline QR Verification:** Instant local cryptographic evaluation without cellular data or internet connectivity.
5. **Anti-Replay Handshake Protocol:** Challenge-response session nonce validation preventing camera recording replay attacks.
6. **Automated Research Benchmarking Suite:** 50-cycle benchmark runner logging witness time, proof latency, verification time, payload sizes, and RAM usage with direct export to `benchmark_results.csv`.

---

## Project Structure

```
zk-MatchID/
├── circuits/                         # Phase 1: Circom 2.1 ZK Circuit Layer
│   ├── src/
│   │   └── age_verifier.circom       # Core Circom circuit (birthYear, ageLimit, Poseidon nullifier)
│   ├── scripts/
│   │   ├── compile_circuit.sh        # Bash compilation & Powers of Tau trusted setup
│   │   └── compile_circuit.ps1       # PowerShell compilation helper for Windows
│   ├── tests/
│   │   └── age_verifier.test.js      # Circuit constraint and nullifier test suite
│   ├── package.json                  # snarkjs, circomlib dependencies
│   └── .gitignore
│
├── mopro/                            # Phase 2: Mopro Native Proving Engine (Rust)
│   ├── Cargo.toml                    # Cargo manifest with mopro-ffi & arkworks
│   ├── mopro.toml                    # Mopro target config for Android (NDK) & iOS
│   ├── src/
│   │   ├── lib.rs                    # UniFFI and C-ABI exports for Dart FFI
│   │   ├── prover.rs                 # Native Groth16 witness & proof generation (< 2.0s)
│   │   └── verifier.rs               # Offline Groth16 pairing verifier
│   ├── assets/                       # Output directory for compiled r1cs, zkey, and vkey
│   │   └── .gitkeep
│   ├── scripts/
│   │   ├── build_mobile.sh           # Shell script to compile Android .so & iOS framework
│   │   └── build_mobile.ps1          # Windows build helper
│   └── .gitignore
│
├── mobile/                           # Phase 3 & 4: Mobile Application (Flutter)
│   ├── lib/
│   │   ├── main.dart                 # Application entrypoint with navigation tabs
│   │   ├── core/
│   │   │   ├── native_bridge.dart    # Dart FFI bridge to Mopro Rust shared library
│   │   │   ├── qr_codec.dart         # Base85 Groth16 proof & public input compression
│   │   │   ├── nonce_manager.dart    # Interactive anti-replay session nonce manager
│   │   │   └── vault_service.dart    # Biometric / encrypted credential vault
│   │   ├── screens/
│   │   │   ├── vault_screen.dart     # Identity Vault (biometric setup & mock DOB)
│   │   │   ├── prover_screen.dart    # Age >= 18 prover & high-density QR generator
│   │   │   ├── verifier_screen.dart  # Dynamic nonce QR & offline camera scanner
│   │   │   └── benchmark_dashboard.dart # Performance dashboard with real-time graphs
│   │   ├── widgets/
│   │   │   ├── qr_display.dart       # High-density dynamic QR renderer
│   │   │   ├── qr_scanner_view.dart  # Offline camera scanner view
│   │   │   └── verification_badge.dart # Verification success/failure result card
│   │   ├── benchmark/
│   │   │   ├── benchmark_runner.dart # 50-cycle automated benchmark runner
│   │   │   └── metrics_exporter.dart # CSV export to mobile device storage
│   │   └── models/
│   │       ├── proof_payload.dart    # Groth16 proof & public input data structures
│   │       └── benchmark_metric.dart # Metric data point model
│   ├── pubspec.yaml                  # Flutter dependencies (qr_flutter, mobile_scanner, ffi, etc.)
│   └── test/
│       └── widget_test.dart          # Widget integration tests
│
├── docs/                             # System Documentation
│   ├── architecture.md               # Cryptographic design & Groth16 pairing specs
│   └── handshake_protocol.md         # Interactive anti-replay QR handshake specs
│
├── PRD.md                            # Product Requirements Document
├── AI Vibe-Coding Execution Prompts  # Multi-phase execution prompt specs
├── System Verification Checklist     # Acceptance test checklist
└── .gitignore                        # Global repository gitignore
```

---

## Quickstart Guide

### 1. Circuit Layer (`circuits/`)
```bash
cd circuits
npm install

# Compile circuit and run trusted setup:
npm run compile           # Linux / macOS / WSL
# OR:
npm run compile:windows   # Windows PowerShell
```

### 2. Mopro Engine Layer (`mopro/`)
```bash
cd mopro

# Compile mobile native libraries:
bash scripts/build_mobile.sh
# OR:
powershell -ExecutionPolicy Bypass -File scripts/build_mobile.ps1
```

### 3. Mobile Application (`mobile/`)
```bash
cd mobile
flutter pub get
flutter test
flutter run
```

---

## Verification & Acceptance Checklist

Refer to [System Verification Checklist](file:///c:/Users/lobop/OneDrive/Desktop/PRAJWAL/SEM7/MP/System%20Verification%20Checklist):
- [x] **Circuit Design:** Circom 2.1 circuit with `GreaterEqThan(16)` and `Poseidon` nullifier.
- [x] **Mopro Engine:** Configured with iOS & Android targets and C-ABI / Dart FFI bindings.
- [x] **Offline Operation:** Zero network dependency; local proving and local verification.
- [x] **Verification Test:** Real-time Groth16 proof calculation in $< 2.0$ seconds.
- [x] **Anti-Replay Test:** Nonce expiration and single-use enforcement in `NonceManager`.
- [x] **Zero-Knowledge Test:** QR payload contains only elliptic curve points and public outputs—no `birthYear` or PII.
