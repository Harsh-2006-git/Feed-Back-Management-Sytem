const express = require("express");
const router = express.Router();
const passport = require("passport");
const User = require("../models/user");
const Feedback = require("../models/feedback");

// Middleware to check if user is admin
const isAdmin = (req, res, next) => {
  if (!req.isAuthenticated()) {
    req.session.returnTo = req.originalUrl;
    req.flash("error", "You must be signed in as admin!");
    return res.redirect("/admin/login");
  }

  if (!req.user || !req.user.isAdmin) {
    req.flash("error", "You need admin privileges to access this page");
    return res.redirect("/");
  }

  next();
};

router.get("/admin/login", (req, res) => {
  res.render("admin/login");
});
router.post(
  "/admin/login",
  passport.authenticate("local", {
    failureFlash: true,
    failureRedirect: "/admin/login",
  }),
  (req, res) => {
    // Check if the user is an admin
    if (!req.user.isAdmin) {
      req.logout(function (err) {
        if (err) return next(err);
        req.flash("error", "You need admin privileges to access this area");
        return res.redirect("/admin/login");
      });
    } else {
      const redirectUrl = req.session.returnTo || "/admin/dashboard";
      delete req.session.returnTo;
      req.flash("success", "Welcome to Admin Panel!");
      res.redirect(redirectUrl); // Changed from res.render() to res.redirect()
    }
  }
);

// Admin Dashboard
// In your admin.js routes file
// In your routes/admin.js file
router.get("/admin/dashboard", isAdmin, async (req, res) => {
  try {
    const feedbacks = await Feedback.find({}).populate("author");
    console.log("Fetched feedbacks:", feedbacks); // Debug log

    res.render("admin/dashboard", {
      feedbacks: feedbacks, // Make sure this is passed
      currentUser: req.user, // Also passing current user
    });
  } catch (err) {
    console.error("Error fetching feedbacks:", err);
    req.flash("error", "Unable to load feedback data");
    res.redirect("/");
  }
});

// Admin Logout route
router.get("/admin/logout", (req, res) => {
  req.logout(function (err) {
    if (err) {
      return next(err);
    }
    req.flash("success", "Admin logged out successfully!");
    res.redirect("/");
  });
});

module.exports = router;
