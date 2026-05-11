const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('data/omniroute/storage.sqlite');

db.serialize(() => {
  db.each("SELECT count(*) as count FROM api_keys", (err, row) => {
    if (err) console.error(err);
    else console.log("API Keys count:", row.count);
  });
  db.each("SELECT count(*) as count FROM users", (err, row) => {
    if (err) console.error(err);
    else console.log("Users count:", row.count);
  });
  db.each("SELECT count(*) as count FROM accounts", (err, row) => {
    if (err) console.error(err);
    else console.log("Accounts count:", row.count);
  });
});

db.close();
