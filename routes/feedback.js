const express = require("express");
const router = express.Router();
const Feedback = require("../models/feedback");
const { isLoggedIn, isFeedbackAuthor, isAdmin } = require("../middleware");

// Index - show all feedback that user has access to
router.get("/", isLoggedIn, async (req, res) => {
  let feedback;

  if (req.user.isAdmin) {
    // Admin sees all feedback
    feedback = await Feedback.find({}).populate("author");
  } else {
    // Regular user sees only their feedback
    feedback = await Feedback.find({ author: req.user._id }).populate("author");
  }

  res.render("feedback/index", { feedback });
});

// New feedback form
router.get("/new", isLoggedIn, (req, res) => {
  res.render("feedback/new");
});

// Create new feedback
router.post("/", isLoggedIn, async (req, res) => {
  const feedback = new Feedback(req.body.feedback);
  feedback.author = req.user._id;
  await feedback.save();
  req.flash("success", "Successfully created new feedback!");
  res.redirect(`/feedback/${feedback._id}`);
});

// Show feedback
router.get("/:id", isLoggedIn, async (req, res) => {
  const feedback = await Feedback.findById(req.params.id).populate("author");

  if (!feedback) {
    req.flash("error", "Cannot find that feedback!");
    return res.redirect("/feedback");
  }

  // Check if user is authorized to view this feedback
  if (!feedback.author.equals(req.user._id) && !req.user.isAdmin) {
    req.flash("error", "You do not have permission to view that feedback");
    return res.redirect("/feedback");
  }

  res.render("feedback/show", { feedback });
});

// Delete feedback
router.delete("/:id", isLoggedIn, isFeedbackAuthor, async (req, res) => {
  const { id } = req.params;
  await Feedback.findByIdAndDelete(id);
  req.flash("success", "Successfully deleted feedback");
  res.redirect("/feedback");
});

// Admin Dashboard
router.get("/admin/dashboard", isLoggedIn, isAdmin, async (req, res) => {
  // Get all feedback for stats
  const allFeedback = await Feedback.find({}).populate("author");

  // Calculate stats
  const totalFeedback = allFeedback.length;
  const totalRating = allFeedback.reduce((sum, item) => sum + item.rating, 0);
  const averageRating =
    totalFeedback > 0 ? (totalRating / totalFeedback).toFixed(1) : 0;

  // Get unique users who submitted feedback
  const uniqueUsers = new Set(allFeedback.map((f) => f.author.username));

  res.render("admin/dashboard", {
    feedback: allFeedback,
    stats: {
      totalFeedback,
      averageRating,
      uniqueUsers: uniqueUsers.size,
    },
  });
});

module.exports = router;
