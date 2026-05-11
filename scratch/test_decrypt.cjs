const crypto = require('crypto');
const Database = require('better-sqlite3');

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const KEY_LENGTH = 32;
const PREFIX = 'enc:v1:';
const STATIC_SALT = 'omniroute-field-encryption-v1';

function decrypt(ciphertext, secret) {
  if (!ciphertext || !ciphertext.startsWith(PREFIX)) return ciphertext;
  
  const body = ciphertext.slice(PREFIX.length);
  const [ivHex, encryptedHex, authTagHex] = body.split(':');
  
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');

  // Try Static Salt (New)
  try {
    const key = crypto.scryptSync(secret, STATIC_SALT, KEY_LENGTH);
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return { success: true, method: 'static', value: decrypted };
  } catch (e) {}

  // Try Dynamic Salt (Legacy)
  try {
    const dynamicSalt = crypto.createHash('sha256').update(secret).digest().slice(0, 16);
    const key = crypto.scryptSync(secret, dynamicSalt, KEY_LENGTH);
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return { success: true, method: 'legacy', value: decrypted };
  } catch (e) {}

  return { success: false };
}

const secret = 'd451a42f4808fce63801aa30815b712e76ad244dbcdc24327ef39ab81c1df009';
const db = new Database('/mnt/storage.sqlite');
const rows = db.prepare('SELECT access_token FROM provider_connections WHERE access_token IS NOT NULL').all();

console.log(`Found ${rows.length} rows with tokens.`);
for (const row of rows) {
  const result = decrypt(row.access_token, secret);
  if (result.success) {
    console.log(`SUCCESS with ${result.method} derivation!`);
    process.exit(0);
  }
}
console.log('FAILURE for all rows and methods.');
