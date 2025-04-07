if wishlist.environmentType == "browser"
    window.npmWishlist = wishlist
if wishlist.moduleSystem == "commonjs"
    module.exports = wishlist
