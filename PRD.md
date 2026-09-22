# Product Requirements Document: zk-MatchID

## 1. Project Goal
zk-MatchID is a peer-to-peer (P2P), offline-first mobile mutual authentication application. It allows two individuals to perform two-way verification (e.g., Age >= 18 check and Property Ownership proof) without sharing personally identifiable information (PII) like full name, date of birth, or national ID numbers.

## 2. Key Features
1. **Local Identity Vault:** Store cryptographically signed identity credentials encrypted using native biometric hardware (KeyStore/Keychain).
2. **On-Device Proof Generation:** Execute zero-knowledge proofs (Groth16 over BN254) natively on mobile hardware under 2 seconds.
3. **High-Density Dynamic QR Encoding:** Pack compressed proof payload, public inputs, and a time-bound session nonce into a high-density QR code.
4. **Offline QR Verification:** Instant local proof evaluation without an internet connection.
5. **Anti-Replay Handshake Protocol:** Interactive nonce exchange prevents replay attacks via camera recording.

## 3. Tech Stack Requirements
- **Circuit Layer:** Circom 2.1+
- **Mobile Native Proving:** Mopro CLI (Rust binding generator targeting UniFFI)
- **Mobile Framework:** React Native (Expo Bare Workflow) or Flutter
- **Cryptography:** Groth16, BN254 Curve, Poseidon Hash Function
- **Encoding:** Protobuf / Base85 for compact QR payloads

## 4. Definition of Done
- Prover can select "Prove Age > 18".
- App compiles witness and proof on-device in <2.0s.
- Verifier camera scans QR code offline and displays "VERIFIED: Age >= 18" with zero PII disclosed.