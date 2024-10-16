// db.js
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Create a new database object, or open an existing database
const db = new sqlite3.Database(path.join(__dirname, 'database.db'), (err) => {
  if (err) {
    console.error('Error opening database ' + err.message);
  } else {
    console.log('Connected to the SQLite database.');
  }
});

// Create a table if it doesn't exist
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    input TEXT NOT NULL
  )`);
});

module.exports = db;
