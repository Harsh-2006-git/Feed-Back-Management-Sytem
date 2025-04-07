# How to compile

```bash
npm update && node_modules/coffee-script/bin/coffee -p -c src/*.coffee > /dev/null && awk 'FNR==1{print ""}1' src/*.coffee | node_modules/coffee-script/bin/coffee -cs > mate.js && node_modules/js-bundler/bin/bundle mate.js | awk 'FNR==1{print ""}1' src/license.txt - > mate.b.js && node_modules/uglify-js/bin/uglifyjs mate.b.js -o mate.b.min.js -m --screw-ie8 --comments && node_modules/coffee-script/bin/coffee -p -c test/*.coffee > /dev/null && awk 'FNR==1{print ""}1' test/*.coffee | node_modules/coffee-script/bin/coffee -cs > test/compiled.js
```

# How to Test

After compiling, run "test/compiled.js" (Node) or visit "test/page.html" (browser).

# How to publish

This section is for the author only, so other contributors can just ignore it.

The compiled .js files should ONLY be included in the tagged commits. To achieve this goal, we put the release version into a new branch and then delete the branch. This approach makes sense because Git's gc does not delete tagged commits, regardless of whether a branch refers to it. Detailed steps:

First, make sure all changes are recorded in master branch. Then, compile. Then:

```bash
git checkout -b release && git add -f mate.js mate.b.js mate.b.min.js test/compiled.js
```

Then commit it and tag it and push it and push tags. Then:

```bash
npm publish . && git checkout master && git branch -D release
```
