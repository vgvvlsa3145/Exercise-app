const mongoose = require('mongoose');

// CONFIG
const OLD_URI = "mongodb+srv://adithya3145_db_user:4rBX6BGSExuKx2VQ@excerciseapp.qh1tguz.mongodb.net/?appName=ExcerciseApp";
const NEW_URI = "mongodb+srv://manideep:manideep@cluster0.ab1eq3t.mongodb.net/";

// SCHEMAS (Simplified for transfer - we just want raw documents usually, but using Models is safer)
// We reuse the existing models by just defining schemas if needed, or importing.
// To avoid path issues, let's just define dynamic models.

const userSchema = new mongoose.Schema({}, { strict: false });
const workoutSchema = new mongoose.Schema({}, { strict: false });

async function migrate() {
    console.log("🚀 Starting Migration...");

    // 1. Connect to OLD DB
    console.log("Connecting to OLD DB...");
    const oldConn = await mongoose.createConnection(OLD_URI).asPromise();
    console.log("✅ Connected to OLD DB");

    const OldUser = oldConn.model('User', userSchema);
    const OldWorkout = oldConn.model('Workout', workoutSchema);

    // 2. Fetch Data
    console.log("Fetching Old Data...");
    const users = await OldUser.find({});
    const workouts = await OldWorkout.find({});
    console.log(`Found ${users.length} Users and ${workouts.length} Workouts.`);

    // 3. Connect to NEW DB
    console.log("Connecting to NEW DB...");
    const newConn = await mongoose.createConnection(NEW_URI).asPromise();
    console.log("✅ Connected to NEW DB");

    const NewUser = newConn.model('User', userSchema);
    const NewWorkout = newConn.model('Workout', workoutSchema);

    // 4. Insert Data (Upsert to prevent duplicates)
    console.log("Migrating Users...");
    for (const u of users) {
        const doc = u.toObject();
        delete doc._id; // Let new DB assign IDs or keep them? 
        // Better to KEEP _id to maintain relationships if any.
        // But if IDs collide with 'A1' (admin)? Admin was seeded fresh.
        // Let's rely on 'username' or 'email' as unique key if _id fails.
        // Actually, just using `updateOne` with upsert is safest.
        if (doc._id) delete doc._id; // Let's regenerate IDs to be safe, unless we need them for relations.
        // Workouts reference 'username', not _id. So we are good to generate new IDs.

        try {
            if (doc.email === 'gv@gmail.com' || doc.username === 'A1') {
                console.log(`Skipping Admin/Default User: ${doc.username}`);
                continue;
            }
            await NewUser.updateOne(
                { username: doc.username },
                { $set: doc },
                { upsert: true }
            );
        } catch (e) {
            console.error(`Failed to migrate user ${doc.username}: ${e.message}`);
        }
    }
    console.log("✅ Users Migrated.");

    console.log("Migrating Workouts...");
    for (const w of workouts) {
        const doc = w.toObject();
        delete doc._id;
        // Workouts are unique by user + timestamp usually.
        await NewWorkout.updateOne(
            { username: doc.username, timestamp: doc.timestamp },
            { $set: doc },
            { upsert: true }
        );
    }
    console.log("✅ Workouts Migrated.");

    // Close
    await oldConn.close();
    await newConn.close();
    console.log("🎉 MIGRATION COMPLETE!");
}

migrate().catch(err => {
    console.error("Migration Failed:", err);
    process.exit(1);
});
