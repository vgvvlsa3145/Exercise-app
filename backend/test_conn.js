const { MongoClient } = require('mongodb');
const dotenv = require('dotenv');

dotenv.config();

const testConnection = async () => {
    const client = new MongoClient(process.env.MONGODB_URI);
    try {
        console.log("Attempting to connect with standard MongoClient...");
        await client.connect();
        console.log("Connected successfully!");
        const db = client.db();
        const collections = await db.listCollections().toArray();
        console.log("Collections:", collections.map(c => c.name));
        process.exit(0);
    } catch (err) {
        console.error("Connection failed:", err);
        process.exit(1);
    }
};

testConnection();
