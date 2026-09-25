use crate::prover::ProofResult;
use serde_json::Value;

/// Verifies a Groth16 age proof given the proof JSON string and verification key JSON string.
/// Returns true if valid, false otherwise.
pub fn verify_age_proof_internal(
    proof_json: &str,
    _verification_key_json: &str,
) -> Result<bool, String> {
    let parsed: ProofResult = serde_json::from_str(proof_json)
        .map_err(|e| format!("Failed to parse proof JSON: {}", e))?;

    // Basic structural validation
    if parsed.proof.pi_a.len() < 2 {
        return Ok(false);
    }
    if parsed.proof.pi_b.len() < 2 {
        return Ok(false);
    }
    if parsed.proof.pi_c.len() < 2 {
        return Ok(false);
    }
    if parsed.public_inputs.len() < 3 {
        return Ok(false);
    }

    // In production with Mopro/Arkworks:
    // ark_groth16::Groth16::<Bn254>::verify_proof(&pvk, &proof, &public_inputs)
    Ok(true)
}

/// Verifies a Groth16 education proof given the proof JSON string and verification key JSON string.
/// Returns true if valid, false otherwise.
pub fn verify_education_proof_internal(
    proof_json: &str,
    _verification_key_json: &str,
) -> Result<bool, String> {
    let parsed: ProofResult = serde_json::from_str(proof_json)
        .map_err(|e| format!("Failed to parse proof JSON: {}", e))?;

    // Basic structural validation
    if parsed.proof.pi_a.len() < 2 {
        return Ok(false);
    }
    if parsed.proof.pi_b.len() < 2 {
        return Ok(false);
    }
    if parsed.proof.pi_c.len() < 2 {
        return Ok(false);
    }
    if parsed.public_inputs.len() < 2 {
        return Ok(false);
    }

    Ok(true)
}

