# ZK Identity Wallet

## Project Overview

This is a Flutter application for a privacy-preserving digital identity wallet.

The main idea is:

**Store digital credentials → select what to prove → generate a Zero-Knowledge Proof → share only the required information.**

For example, instead of sharing a complete date of birth, the application can prove:

**"Age ≥ 18"**

without revealing the exact date of birth.

The application will also support education verification, such as proving:

**"User holds a bachelor's degree"**

without unnecessarily sharing the complete credential.

---

## UI Reference

The project includes a UI reference file:

`zkid_app_all_frames.html`

This file contains 31 reference screens for the application.

The screens are divided into:

1. Onboarding and wallet setup
2. Credentials
3. Proof generation and sharing
4. Verifier flow
5. Settings and security
6. Benchmarking

The Flutter application should recreate these screens using Flutter widgets.

Do not copy the HTML directly into Flutter.

Use the HTML only as the visual and flow reference.

---

## Technology

The project uses:

- Flutter
- Dart
- Existing ZK / cryptography implementation
- Existing wallet implementation
- Existing blockchain implementation
- Existing native Rust/Mopro bridge where already present

Do not replace the existing architecture unnecessarily.

Do not delete existing working functionality.

---

# Important Development Rules

Before changing the project:

1. Inspect the existing project.
2. Understand the current folder structure.
3. Find the existing wallet implementation.
4. Find the existing age verification implementation.
5. Find the existing Zero-Knowledge Proof implementation.
6. Find the blockchain/revocation implementation.
7. Find the native Rust/Mopro bridge.
8. Find the current navigation and screens.
9. Check whether education/degree verification already exists.

Reuse existing code whenever possible.

Do not rewrite the whole project.

Do not create duplicate implementations of features that already exist.

If a feature does not exist yet, add it in a way that fits the existing architecture.

---

# Main Application Flow

The final application should support this general flow:

**Create wallet**
→ **Store credentials**
→ **View credentials**
→ **Select a fact to prove**
→ **Give consent**
→ **Generate ZK proof**
→ **Share proof**
→ **Verifier verifies proof**
→ **View verification history**
→ **Manage security settings**

---

# Screen List

## 1. Onboarding and Wallet Setup

### Screen 01 — Welcome

Elements:

- Create new wallet
- Restore from backup
- What is a wallet?

### Screen 02 — Phone Number

Elements:

- Phone number input
- Send OTP

### Screen 03 — OTP Verification

Elements:

- OTP input
- Verify
- Resend code
- Resend timer

### Screen 04 — Face Capture / Liveness

Elements:

- Camera area
- Face frame
- Liveness instructions
- Capture

### Screen 05 — Binding Success

Elements:

- Success icon
- Face and number verified
- Continue

### Screen 06 — Wallet Name and Device Lock

Elements:

- Wallet name
- Biometric toggle
- Continue

### Screen 07 — Backup Phrase

Elements:

- 12-word recovery phrase
- Copy
- I've saved it

### Screen 08 — Backup Verification

Elements:

- Select required words
- Word chips
- Verify

### Screen 09 — Restore Wallet

Elements:

- Recovery phrase input
- Restore
- Scan backup QR

---

# 2. Credentials

### Screen 10 — Credential Home

Show credentials such as:

- Age credential
- Degree credential
- Income credential
- Voter ID credential

Show status:

- Valid
- Revoked
- Pending

Bottom navigation:

- Wallet
- Prove
- Activity
- Settings

### Screen 11 — Credential Details

Show:

- Issuer
- Issue date
- Protected DOB claim
- Credential ID
- Reveal raw claims
- Delete credential

Do not expose private information unnecessarily.

### Screen 12 — Add Credential

Elements:

- QR scanner
- Manual issuer link

### Screen 13 — Credential Received

Show:

- Credential type
- Issuer
- Accept and store
- Decline

---

# 3. Proof Generation and Sharing

### Screen 14 — Predicate Selector

Allow the user to select:

- Age ≥ 18
- Bachelor's degree
- Income below a specified amount
- Custom predicate

The existing age verification flow must continue to work.

Education verification should use the same general credential and ZK architecture.

### Screen 15 — Consent

Clearly show:

What will be revealed:

- Example: Age is 18 or older

What will NOT be revealed:

- Exact date of birth
- Name
- Address
- Aadhaar number

The user must confirm before generating the proof.

### Screen 16 — Live Face Verification

Elements:

- Face camera
- Live face check
- Scan face

### Screen 17 — ZK Proof Generation

Show:

- Loading/progress indicator
- Generating zero-knowledge proof
- Local computation message
- Cancel option

Use the existing ZK implementation.

### Screen 18 — Share Proof

Show:

- QR code
- Proof statement
- Expiration
- NFC option
- Copy proof link

### Screen 19 — Cached Proofs

Show previously generated proofs.

Allow:

- Reuse proof

Do not reuse expired proofs.

---

# 4. Verifier Flow

### Screen 20 — Verifier Request Builder

Allow the verifier to select:

- Age ≥ 18
- Degree possession
- Trusted issuers

Generate request QR.

### Screen 21 — Scan Proof

Elements:

- QR scanner
- Requested predicate
- Verify

### Screen 22 — Verification Process

Check:

- Signature
- Face match
- Revocation status

### Screen 23 — Verification Successful

Show:

- Verified
- Proof valid
- Face matched
- Not revoked
- Verification time
- Network

### Screen 24 — Verification Failed

Show:

- Verification failed
- Failure reason
- Try again

### Screen 25 — Verification History

Show previous verification results, for example:

- Age verification
- Degree verification
- Income verification

Show pass/fail status.

---

# 5. Settings and Security

### Screen 26 — Settings

Options:

- Biometric app lock
- Face binding for proofs
- Linked phone number
- Network
- Export recovery phrase
- Wipe wallet

### Screen 27 — Linked Phone Number

Show:

- Linked number
- Verification date
- Change number
- Re-verification

### Screen 28 — Biometric Lock

Show:

- Unlock wallet
- Fingerprint / biometric authentication
- Passcode fallback

### Screen 29 — Wipe Wallet

This is a destructive action.

Require:

`DELETE`

before allowing wallet deletion.

Show:

- Warning
- Wipe wallet
- Cancel

---

# 6. Benchmarking

### Screen 30 — Benchmark Dashboard

Show:

- Average proof generation time
- Average verification time
- Average gas
- Number of exposed fields

Buttons:

- Export CSV
- Run new benchmark

Do not display benchmark numbers as real measurements unless they are actually measured by the application.

### Screen 31 — Comparison

Provide a comparison view.

Show the methodology clearly.

Do not make unsupported claims.

---

# Implementation Order

Do not implement all 31 screens at once.

Implement them in phases.

## Phase 1 — Main Navigation and Core Screens

Implement:

1. Main application navigation
2. Wallet Home
3. Credential Details
4. Prove screen
5. Activity screen
6. Settings screen

## Phase 2 — Onboarding

Implement:

1. Phone number
2. OTP
3. Face capture
4. Wallet creation
5. Backup phrase
6. Restore wallet

## Phase 3 — Credentials

Implement:

1. Age credential
2. Education/Degree credential
3. Add credential
4. Credential acceptance

## Phase 4 — Proof Generation

Implement:

1. Predicate selection
2. Consent
3. Face verification
4. ZK proof generation
5. QR proof sharing
6. Cached proofs

## Phase 5 — Verifier

Implement:

1. Request builder
2. QR scanning
3. Proof verification
4. Verification result
5. Verification history

## Phase 6 — Security and Benchmarking

Implement:

1. Settings
2. Biometric lock
3. Wipe wallet
4. Benchmark dashboard
5. Comparison screen

---

# Age Verification

Age verification is an important existing feature.

Target flow:

**Age credential**
→ **Select Age ≥ 18**
→ **Consent**
→ **Face verification if required**
→ **Generate ZK proof**
→ **Display proof QR**
→ **Verifier scans QR**
→ **Verify proof**
→ **Check credential status**
→ **Show result**

The normal verification flow should not reveal the user's exact date of birth.

Do not break the existing age verification implementation.

---

# Education Verification

Add education verification using the same general architecture.

Example credential:

**Bachelor's Degree**

Example issuer:

**Mumbai University**

Example proof:

**"User holds a bachelor's degree."**

The verifier should receive the required proof without unnecessarily exposing unrelated personal information.

Reuse the existing credential and ZK architecture.

Do not create a completely separate identity system for education verification.

---

# Privacy Rules

Never display or transmit sensitive credential data unnecessarily.

The UI should clearly communicate privacy.

Examples:

- "Your credentials stay on this device."
- "Exact date of birth is not revealed."
- "Your identity data is not shared unnecessarily."
- "Only the required fact is proved."

Do not log:

- Recovery phrases
- Private keys
- Sensitive credential data
- Biometric data

---

# UI Guidelines

The UI should follow the provided HTML reference.

Important characteristics:

- Mobile-first interface
- Clean layout
- Dark purple primary color
- White cards
- Rounded corners
- Simple typography
- Bottom navigation
- Status badges
- Clear buttons
- Privacy-focused messages

Create reusable Flutter widgets for common UI elements such as:

- App bars
- Buttons
- Cards
- Credential cards
- Status badges
- Bottom navigation
- Loading states
- Success states
- Failure states

---

# Project Structure

Follow the existing project architecture.

If the current architecture allows it, use a structure similar to:

```text
lib/
├── screens/
├── widgets/
├── models/
├── services/
├── navigation/
└── theme/
```

Do not create duplicate folders or duplicate services if equivalent structures already exist.

---

# Existing Code Rule

Before modifying any file:

1. Read the file.
2. Understand what it does.
3. Check whether another file already provides the same functionality.
4. Reuse existing services/models.
5. Make the smallest necessary change.

If the project already implements:

- Age verification
- Wallet
- Credentials
- ZK proof generation
- Blockchain verification
- Revocation
- Face verification

reuse those implementations.

Do not create a second version.

---

# Testing

After every major phase, run:

```bash
flutter analyze
```

Then:

```bash
flutter test
```

If possible, run the application on the connected Android device.

Check:

- Navigation
- UI
- Existing age verification
- Credential flow
- ZK functionality
- Error handling

Fix errors before moving to the next phase.

---

# Codex Instructions

When working on this project:

1. First inspect the existing code.
2. Read this README.
3. Read `zkid_app_all_frames.html` as the UI reference.
4. Do not rewrite the entire project.
5. Do not delete existing working features.
6. Do not replace real ZK functionality with fake functionality.
7. Reuse existing services and models.
8. Implement one phase at a time.
9. Run Flutter analysis after changes.
10. Fix errors before continuing.
11. Clearly report which files were changed.
12. Clearly mention if any feature is currently a mock/demo implementation.

The main goal is to create a clean, working Flutter privacy-preserving identity wallet while keeping the existing ZK, wallet, and blockchain functionality intact.
