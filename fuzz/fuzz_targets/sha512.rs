#![no_main]
use libfuzzer_sys::fuzz_target;
use fastcrypto::hash::*;

fuzz_target!(|value: &[u8]| {
    let digest1 = Sha512::digest(value);

    let mut hash_function = Sha512::default();
    hash_function.update(value);
    let digest2 = hash_function.finalize();

    assert_eq!(digest1, digest2);
});