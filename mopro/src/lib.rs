pub mod prover;
pub mod verifier;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

// -----------------------------------------------------------------------------
// High-Level Rust API / UniFFI Interface
// -----------------------------------------------------------------------------

pub fn generate_age_proof(
    birth_year: u32,
    user_secret: String,
    current_year: u32,
    age_limit: u32,
    session_nonce: String,
) -> Result<String, String> {
    prover::generate_age_proof_internal(
        birth_year,
        &user_secret,
        current_year,
        age_limit,
        &session_nonce,
    )
}

pub fn verify_age_proof(proof_json: String, verification_key: String) -> Result<bool, String> {
    verifier::verify_age_proof_internal(&proof_json, &verification_key)
}

// -----------------------------------------------------------------------------
// C-ABI Exports for Flutter (Dart FFI)
// -----------------------------------------------------------------------------

#[no_mangle]
pub extern "C" fn ffi_generate_age_proof(
    birth_year: u32,
    user_secret: *const c_char,
    current_year: u32,
    age_limit: u32,
    session_nonce: *const c_char,
) -> *mut c_char {
    if user_secret.is_null() || session_nonce.is_null() {
        return CString::new("{\"error\": \"Null pointer provided\"}").unwrap().into_raw();
    }

    let secret_str = unsafe {
        match CStr::from_ptr(user_secret).to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"Invalid UTF-8 in secret\"}").unwrap().into_raw(),
        }
    };

    let nonce_str = unsafe {
        match CStr::from_ptr(session_nonce).to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"Invalid UTF-8 in nonce\"}").unwrap().into_raw(),
        }
    };

    match prover::generate_age_proof_internal(
        birth_year,
        secret_str,
        current_year,
        age_limit,
        nonce_str,
    ) {
        Ok(json) => CString::new(json).unwrap().into_raw(),
        Err(err) => {
            let err_json = format!("{{\"error\": \"{}\"}}", err);
            CString::new(err_json).unwrap().into_raw()
        }
    }
}

#[no_mangle]
pub extern "C" fn ffi_verify_age_proof(
    proof_json: *const c_char,
    verification_key: *const c_char,
) -> i32 {
    if proof_json.is_null() || verification_key.is_null() {
        return 0;
    }

    let proof_str = unsafe {
        match CStr::from_ptr(proof_json).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };

    let vkey_str = unsafe {
        match CStr::from_ptr(verification_key).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };

    match verifier::verify_age_proof_internal(proof_str, vkey_str) {
        Ok(true) => 1,
        _ => 0,
    }
}

#[no_mangle]
pub extern "C" fn ffi_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}
