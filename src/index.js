const mysql = require('mysql2/promise');

const DB_HOST = process.env.DB_HOST;
const DB_USER = process.env.DB_USER;
const DB_PASS = process.env.DB_PASS;
const DB_NAME = process.env.DB_NAME;
const API_KEY = process.env.API_KEY;

// Simple API key check
function checkAuth(event) {
  const key = event.headers['x-api-key'];
  return key && key === API_KEY;
}

async function connectDb() {
  return await mysql.createConnection({
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASS,
    database: DB_NAME,
  });
}

// Generate short ID
function generateShortId(length = 6) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for(let i=0; i<length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

exports.handler = async (event) => {
  if (!checkAuth(event)) {
    return {
      statusCode: 401,
      body: JSON.stringify({ message: 'Unauthorized' }),
    };
  }

  const conn = await connectDb();

  const path = event.rawPath || event.path || "/";
  const method = event.requestContext.http.method;

  if (method === "POST" && path === "/shorten") {
    const body = JSON.parse(event.body);
    const originalUrl = body.url;
    if (!originalUrl) {
      return { statusCode: 400, body: JSON.stringify({ message: "Missing url field" }) };
    }

    const shortId = generateShortId();

    await conn.execute(
      'INSERT INTO urls (short_id, original_url) VALUES (?, ?)',
      [shortId, originalUrl]
    );

    return {
      statusCode: 201,
      body: JSON.stringify({ shortId }),
    };
  } else if (method === "GET") {
    const shortId = path.replace("/", "");
    if (!shortId) {
      return { statusCode: 400, body: JSON.stringify({ message: "Missing shortId in path" }) };
    }

    const [rows] = await conn.execute(
      'SELECT original_url FROM urls WHERE short_id = ?',
      [shortId]
    );

    if (rows.length === 0) {
      return { statusCode: 404, body: JSON.stringify({ message: "Not found" }) };
    }

    return {
      statusCode: 302,
      headers: {
        Location: rows[0].original_url,
      },
      body: "",
    };
  } else {
    return { statusCode: 405, body: JSON.stringify({ message: "Method not allowed" }) };
  }
};