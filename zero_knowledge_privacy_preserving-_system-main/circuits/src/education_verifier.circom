pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

/**
 * EducationVerifier Circuit
 * 
 * Verifies that a user possesses a degree matching requiredDegreeCode
 * and that their credential status is valid (1) without revealing student name,
 * university, exact degree, or credential ID.
 * Binds the proof to a single session via Poseidon(userSecretKey, sessionNonce)
 * to prevent replay attacks.
 */
template EducationVerifier() {
    // ------------------------------------------------------------------------
    // Inputs
    // ------------------------------------------------------------------------
    // Private Inputs (never revealed to verifier)
    signal input degreeCode;
    signal input credentialStatus; // 1 = VALID, 0 = REVOKED
    signal input userSecretKey;

    // Public Inputs (known to both prover and verifier)
    signal input requiredDegreeCode;
    signal input sessionNonce;

    // ------------------------------------------------------------------------
    // Outputs
    // ------------------------------------------------------------------------
    // Public Output: Nullifier linking identity to session nonce
    signal output nullifier;

    // ------------------------------------------------------------------------
    // Constraints & Logic
    // ------------------------------------------------------------------------
    // 1. Enforce degreeCode == requiredDegreeCode using IsEqual comparator
    component degreeCheck = IsEqual();
    degreeCheck.in[0] <== degreeCode;
    degreeCheck.in[1] <== requiredDegreeCode;
    degreeCheck.out === 1;

    // 2. Enforce credentialStatus == 1 (VALID)
    component statusCheck = IsEqual();
    statusCheck.in[0] <== credentialStatus;
    statusCheck.in[1] <== 1;
    statusCheck.out === 1;

    // 3. Compute session-bound nullifier = Poseidon(userSecretKey, sessionNonce)
    component poseidonHasher = Poseidon(2);
    poseidonHasher.inputs[0] <== userSecretKey;
    poseidonHasher.inputs[1] <== sessionNonce;

    nullifier <== poseidonHasher.out;
}

component main {public [requiredDegreeCode, sessionNonce]} = EducationVerifier();
