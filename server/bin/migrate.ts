import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import mysql from "mysql2/promise";

// Robuste dans tous les contextes (Docker, local)
const schema = path.resolve(process.cwd(), "database/schema.sql");

const { DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME } = process.env;

const migrate = async () => {
  try {
    const sql = fs.readFileSync(schema, "utf8");

    const database = await mysql.createConnection({
      host: DB_HOST,
      port: Number(DB_PORT),
      user: DB_USER,
      password: DB_PASSWORD,
      multipleStatements: true,
    });

    await database.query(`DROP DATABASE IF EXISTS \`${DB_NAME}\``);
    await database.query(`CREATE DATABASE \`${DB_NAME}\``);
    await database.query(`USE \`${DB_NAME}\``);
    await database.query(sql);

    await database.end();

    console.info(`✅ ${DB_NAME} updated from ${schema}`);
  } catch (err) {
    const { message, stack } = err as Error;
    console.error("❌ Error updating the database:", message, stack);
    process.exit(1); // important pour que CI échoue si erreur
  }
};

migrate();
