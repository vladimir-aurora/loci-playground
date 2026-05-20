/*
 * demo/main.c
 *
 * Tiny main() — the ELF exists for /memory-report, not to run.
 *
 * Each `extern` declaration plus the address taken in _references[]
 * forces the corresponding library object into the link, so the memory
 * report reflects a realistic cross-section of each library's footprint.
 * TI's tiarmlnk does not support GNU `--whole-archive`; symbol references
 * are the portable equivalent.
 *
 * TI's default linker command file is used (via the auto-injected
 * --rom_model), so section placement reflects how a real TI Cortex-M4
 * project would be laid out by their toolchain.
 */

/* micro-ecc */
extern int  uECC_sign(void);
extern int  uECC_verify(void);
extern int  uECC_shared_secret(void);
extern int  uECC_make_key(void);
extern int  uECC_valid_public_key(void);
extern int  uECC_sign_with_k(void);

/* littlefs */
extern int  lfs_mount(void);
extern int  lfs_file_write(void);
extern int  lfs_dir_read(void);

/* tinycrypt — one symbol per .o file so each unit is represented */
extern int  tc_aes_encrypt(void);
extern int  tc_aes_decrypt(void);
extern int  tc_cbc_mode_encrypt(void);
extern int  tc_ccm_generation_encryption(void);
extern int  tc_cmac_init(void);
extern int  tc_ctr_mode(void);
extern int  tc_ctr_prng_init(void);
extern int  tc_hmac_init(void);
extern int  tc_hmac_prng_init(void);
extern int  tc_sha256_init(void);

/* printf */
extern int  snprintf_(void);

/* cJSON */
extern int  cJSON_Parse(void);
extern int  cJSON_Print(void);

__attribute__((used))
static int (* const _references[])(void) = {
    uECC_sign, uECC_verify, uECC_shared_secret,
    uECC_make_key, uECC_valid_public_key, uECC_sign_with_k,
    lfs_mount, lfs_file_write, lfs_dir_read,
    tc_aes_encrypt, tc_aes_decrypt, tc_cbc_mode_encrypt,
    tc_ccm_generation_encryption, tc_cmac_init, tc_ctr_mode,
    tc_ctr_prng_init, tc_hmac_init, tc_hmac_prng_init,
    tc_sha256_init,
    snprintf_,
    cJSON_Parse, cJSON_Print,
};

int main(void)
{
    for (;;) {}
    return 0;
}
