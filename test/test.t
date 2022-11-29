Repo setup
  $ export OPAMNOENVNOTICE=1
  $ export OPAMYES=1
  $ export OPAMROOT=$PWD/OPAMROOT
  $ mkdir -p REPO/packages/foo/foo.1
  $ cat > REPO/repo << EOF
  > opam-version: "2.0"
  > EOF
  $ cat > REPO/packages/foo/foo.1/opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "repo" ]
  > EOF
  $ cat > c-install << EOF
  > set -eux
  > echo "succesfully c-installed \$1!" > c-installed
  > EOF
Opam setup
  $ mkdir $OPAMROOT
  $ opam init --bare ./REPO --no-setup --bypass-checks
  No configuration file found, using built-in defaults.
  
  <><> Fetching repository information ><><><><><><><><><><><><><><><><><><><><><>
  [default] Initialised
  $ opam switch create one --empty
==============
=== Test 1 ===
With repo & no local opam file
  $ mkdir foo
  $ cd foo
  $ opam-custom-install foo -- sh -x ../c-install 'test#1'
  Registering foo as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  -> installed foo.1
  Done.
  $ cat c-installed
  succesfully c-installed test#1!
  $ opam pin
  foo.1    local definition
  $ opam show foo --raw
  opam-version: "2.0"
  name: "foo"
  version: "1"
  build: ["false" "repo"]
  $ rm c-installed
  $ opam reinstall foo 2>&1 | grep -v "#"
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  [ERROR] The compilation of foo.1 failed at "false repo".
  
  
  
  
  <><> Error report <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  +- The following actions failed
  | - build foo 1
  +- 
  - No changes have been performed
  $ opam unpin foo
  Ok, foo is no longer pinned locally (version 1)
  Nothing to do.
  $ opam remove foo
  The following actions will be performed:
  === remove 1 package
    - remove foo 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  Done.
=== Test 2 ===
With repo & local opam file
  $ cat > foo.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > EOF
  $ opam-custom-install foo -- sh ../c-install 'test#2'
  Registering foo as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  -> installed foo.1
  Done.
  $ cat c-installed
  succesfully c-installed test#2!
  $ opam pin
  foo.1    local definition
  $ opam show foo --raw
  opam-version: "2.0"
  name: "foo"
  version: "1"
  build: ["false" "local"]
  install: "false"
  $ rm c-installed
  $ opam reinstall foo 2>&1 | grep -v "#"
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  [ERROR] The compilation of foo.1 failed at "false local".
  
  
  
  
  <><> Error report <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  +- The following actions failed
  | - build foo 1
  +- 
  - No changes have been performed
  $ test ! -f c-installed
  $ opam unpin foo -n
  Ok, foo is no longer pinned locally (version 1)
  $ opam remove foo
  The following actions will be performed:
  === remove 1 package
    - remove foo 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  Done.
  $ cd ..
=== Test 3 ===
With no repo & no local opam file
  $ mkdir bar
  $ cd bar
  $ opam-custom-install bar -- sh ../c-install 'test#3'
  Registering bar as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#3!
  $ opam pin
  bar.dev    local definition
  $ opam show bar --raw
  opam-version: "2.0"
  name: "bar"
  version: "dev"
  synopsis: "Package installed using 'opam custom-install'"
  $ rm c-installed
  $ opam reinstall bar
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ test ! -f c-installed
  $ opam unpin bar
  Ok, bar is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove bar dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  Done.
=== Test 4 ===
With no repo & local opam file
  $ cat > bar.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > EOF
  $ opam-custom-install bar -- sh ../c-install 'test#4'
  Registering bar as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#4!
  $ opam pin
  bar.dev    local definition
  $ opam show bar --raw
  opam-version: "2.0"
  name: "bar"
  version: "dev"
  build: ["false" "local"]
  install: "false"
  $ rm c-installed
  $ opam reinstall bar 2>&1 | grep -v "#"
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  [ERROR] The compilation of bar.dev failed at "false local".
  
  
  
  
  <><> Error report <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  +- The following actions failed
  | - build bar dev
  +- 
  - No changes have been performed
  $ test ! -f c-installed
  $ opam unpin bar
  Ok, bar is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove bar dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  Done.
  $ cd ..
=== Test 5 ===
Various dependencies
  $ mkdir -p REPO/packages/baz-dep/baz-dep.1
  $ cat > REPO/packages/baz-dep/baz-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-post-dep/baz-post-dep.1
  $ cat > REPO/packages/baz-post-dep/baz-post-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-build-dep/baz-build-dep.1
  $ cat > REPO/packages/baz-build-dep/baz-build-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-installed-dep/baz-installed-dep.1
  $ cat > REPO/packages/baz-installed-dep/baz-installed-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-test-dep/baz-test-dep.1
  $ cat > REPO/packages/baz-test-dep/baz-test-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ opam update
  
  <><> Updating package repositories ><><><><><><><><><><><><><><><><><><><><><><>
  [default] synchronised from file:///home/rjbou/ocamlpro/opam-custom-install/_build/.sandbox/07a029ab13f560a3330d1af2f853708c/default/test/REPO
  Now run 'opam upgrade' to apply any package updates.
  $ mkdir baz
  $ cd baz
=== 5A: already installed dependency
  $ cat > baz.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > depends: [
  >   "baz-dep"
  >   "baz-installed-dep"
  > ]
  > EOF
  $ opam install baz-installed-dep
  The following actions will be performed:
  === install 1 package
    - install baz-installed-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz-installed-dep.1
  Done.
  $ opam-custom-install baz -- sh ../c-install 'test#5A'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#5A!
  $ opam show baz --raw
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: ["baz-installed-dep"]
  build: ["false" "local"]
  install: "false"
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove baz dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
=== 5B: post dependency
  $ cat > baz.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > depends: [
  >   "baz-dep"
  >   "baz-installed-dep"
  >   "baz-post-dep" { post }
  > ]
  > EOF
  $ opam-custom-install baz -y -- sh ../c-install 'test#5B'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz          dev (pinned)
  === install 1 package
    - install   baz-post-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  -> installed baz-post-dep.1
  Done.
  $ cat c-installed
  succesfully c-installed test#5B!
  $ opam show baz --raw --normalise
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: [
    "baz-installed-dep"
    "baz-post-dep" {post}
  ]
  build: ["false" "local"]
  install: "false"
  $ opam install baz-post-dep
  [NOTE] Package baz-post-dep is already installed (current version is 1).
  $ opam remove baz
  The following actions will be performed:
  === remove 1 package
    - remove baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
  $ opam-custom-install baz -- sh ../c-install 'test#5B'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove baz dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
=== 5C: build dependency
  $ cat > baz.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > depends: [
  >   "baz-dep"
  >   "baz-installed-dep"
  >   "baz-build-dep" { build }
  > ]
  > EOF
  $ opam-custom-install baz -y -- sh ../c-install 'test#5C'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-build-dep
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#5C!
  $ opam show baz --raw
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: ["baz-installed-dep"]
  build: ["false" "local"]
  install: "false"
  $ opam install baz-build-dep
  The following actions will be performed:
  === install 1 package
    - install baz-build-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz-build-dep.1
  Done.
  $ opam remove baz
  The following actions will be performed:
  === remove 1 package
    - remove baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
  $ opam-custom-install baz -- sh ../c-install 'test#5C'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove baz dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
=== 5D: test dependency
  $ cat > baz.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > depends: [
  >   "baz-dep"
  >   "baz-installed-dep"
  >   "baz-test-dep" { with-test }
  > ]
  > EOF
  $ opam-custom-install baz -y -- sh ../c-install 'test#5D'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-test-dep
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#5D!
  $ opam show baz --raw
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: ["baz-installed-dep"]
  build: ["false" "local"]
  install: "false"
  $ opam install baz-test-dep
  The following actions will be performed:
  === install 1 package
    - install baz-test-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz-test-dep.1
  Done.
  $ opam remove baz
  The following actions will be performed:
  === remove 1 package
    - remove baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
  $ opam-custom-install baz -- sh ../c-install 'test#5D'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === recompile 1 package
    - recompile baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed baz.dev
  Done.
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove baz dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
