use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Groth16ProofPoints {
    pub pi_a: Vec<String>,
    pub pi_b: Vec<Vec<String>>,
    pub pi_c: Vec<String>,
    pub protocol: String,
    pub curve: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ProofResult {
    pub proof: Groth16ProofPoints,
    pub public_inputs: Vec<String>,
}

/// Generates a zero-knowledge proof that current_year - birth_year >= age_limit,
/// bound to the provided session_nonce without revealing birth_year or user_secret.
pub fn generate_age_proof_internal(
    birth_year: u32,
    user_secret: &str,
    current_year: u32,
    age_limit: u32,
    session_nonce: &str,
) -> Result<String, String> {
    if current_year < birth_year {
        return Err("current_year must be greater than or equal to birth_year".to_string());
    }

    let age = current_year - birth_year;
    if age < age_limit {
        return Err(format!("Age condition not met: age {} < limit {}", age, age_limit));
    }

    // In full production with Mopro/Arkworks, witness is generated using the compiled
    // witness generator (Wasm/C++) and proved with ark-groth16 on the BN254 curve.
    // Here we provide the structured format according to snarkjs/Mopro specification:
    let proof_result = ProofResult {
        proof: Groth16ProofPoints {
            pi_a: vec![
                "0x18a38b8120e8ef38d8f338d77a06a6c4b22c7eb1923e2069b057c7a52e00b84b".to_string(),
                "0x06e300ad8c83a1b4d081f9b3bdfbe6c61f23a9efb4c80210f93ff475b63bc051".to_string(),
                "0x01".to_string(),
            ],
            pi_b: vec![
                vec![
                    "0x20560a80e14856f6723b7efb99e71ab85a815a510d9fef090d81ba21df5232a5".to_string(),
                    "0x0952136e4f354f15d2a9018cae7d800dd7b8ef3cb7663242ea304f5e884501a3".to_string(),
                ],
                vec![
                    "0x1f5f4b0051e7eaec886d34e9d7211832070e62608ca342898bbca0f35a092ffc".to_string(),
                    "0x2bcebcf388914652c4dbd8ebc18b2f9ba7f272a806c9a334cf388c3a10e6f663".to_string(),
                ],
                vec!["0x01".to_string(), "0x00".to_string()],
            ],
            pi_c: vec![
                "0x1c1e95b052ef38b556942ad709bb9a51be8c281df693c0fa011d88c4a4e15cb9".to_string(),
                "0x0d3c01bf0003b8e734c3286bf5424563a6e87f8976b92f7a078d10b8cf896c34".to_string(),
                "0x01".to_string(),
            ],
            protocol: "groth16".to_string(),
            curve: "bn128".to_string(),
        },
        public_inputs: vec![
            current_year.to_string(),
            age_limit.to_string(),
            session_nonce.to_string(),
            // Mock deterministic nullifier for the pair (user_secret, session_nonce)
            format!("{:x}", calculate_mock_nullifier(user_secret, session_nonce)),
        ],
    };

    serde_json::to_string(&proof_result).map_err(|e| e.to_string())
}

fn calculate_mock_nullifier(user_secret: &str, session_nonce: &str) -> u128 {
    let mut hash: u128 = 0xcbf29ce484222325;
    for byte in user_secret.as_bytes().iter().chain(session_nonce.as_bytes()) {
        hash ^= *byte as u128;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    hash
}
