const express = require("express");
const app = express();
const mongoose = require("mongoose");
const path = require("path");
const methodOverride = require("method-override");
const MongoStore = require("connect-mongo");
const flash = require("connect-flash");
const passport = require("passport");
const LocalStrategy = require("passport-local");
const session = require("express-session");
const ejsMate = require("ejs-mate"); // For layout functionality

const User = require("./models/user.js");
const Feedback = require("./models/feedback.js");

// EJS configuration
app.engine("ejs", ejsMate);
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(methodOverride("_method"));
app.use(express.static(path.join(__dirname, "public")));

// Session configuration
const store = MongoStore.create({
  mongoUrl: "mongodb://127.0.0.1:27017/feedback",
  crypto: {
    secret: "your-secret-key",
  },
  touchAfter: 24 * 60 * 60,
});

store.on("error", (err) => {
  console.log("Session store error:", err);
});

const sessionOptions = {
  store,
  name: "feedback_session", // Name of the cookie
  secret: "your-secret-key", // Change this to a secure random string
  resave: false,
  saveUninitialized: true,
  cookie: {
    httpOnly: true,
    expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // 1 week
    maxAge: 1000 * 60 * 60 * 24 * 7,
  },
};

app.use(session(sessionOptions));
app.use(flash());

// Passport configuration
app.use(passport.initialize());
app.use(passport.session());
passport.use(new LocalStrategy(User.authenticate()));

// Serialize and deserialize users
passport.serializeUser(User.serializeUser());
passport.deserializeUser(User.deserializeUser());

// Make flash messages and current user available to all templates
app.use((req, res, next) => {
  res.locals.success = req.flash("success");
  res.locals.error = req.flash("error");
  res.locals.currentUser = req.user;
  next();
});

// Import routes after Passport setup
const authRoutes = require("./routes/auth");
const feedbackRoutes = require("./routes/feedback");
const adminRoutes = require("./routes/admin");

// Routes
app.use("/", authRoutes);
app.use("/feedback", feedbackRoutes);
app.use("/", adminRoutes);

app.get("/", (req, res) => {
  res.render("home");
});

async function main() {
  try {
    await mongoose.connect("mongodb://127.0.0.1:27017/feedback");
    console.log("✅ Database connected successfully");
  } catch (err) {
    console.error("❌ Database connection failed:", err);
    process.exit(1);
  }
}
main();

const PORT = 8080;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
