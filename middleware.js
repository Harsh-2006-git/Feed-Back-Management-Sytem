const Feedback = require("./models/feedback");

module.exports.isLoggedIn = (req, res, next) => {
  if (!req.isAuthenticated()) {
    req.session.returnTo = req.originalUrl;
    req.flash("error", "You must be signed in first!");
    return res.redirect("/login");
  }
  next();
};

module.exports.isAdmin = (req, res, next) => {
  if (!req.user.isAdmin) {
    req.flash("error", "Access denied. Admin privileges required.");
    return res.redirect("/feedback");
  }
  next();
};

module.exports.isFeedbackAuthor = async (req, res, next) => {
  const { id } = req.params;
  const feedback = await Feedback.findById(id);
  if (!feedback) {
    req.flash("error", "Feedback not found");
    return res.redirect("/feedback");
  }

  // Allow if user is feedback author or admin
  if (!feedback.author.equals(req.user._id) && !req.user.isAdmin) {
    req.flash("error", "You do not have permission to do that");
    return res.redirect("/feedback");
  }
  next();
};

module.exports.isAdminLoggedIn = (req, res, next) => {
  if (!req.isAuthenticated()) {
    req.session.returnTo = req.originalUrl;
    req.flash("error", "Admin login required!");
    return res.redirect("/admin/login");
  }
  if (!req.user.isAdmin) {
    req.flash("error", "You need admin privileges to access this page");
    return res.redirect("/");
  }
  next();
};
