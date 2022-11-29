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
  === install 1 package
    - install foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 1 package
    - install foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 1 package
    - install bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 1 package
    - install bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  $ mkdir -p REPO/packages/random-dep/random-dep.1
  $ cat > REPO/packages/random-dep/random-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-dep/baz-dep.1
  $ cat > REPO/packages/baz-dep/baz-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-post-dep/baz-post-dep.1
  $ cat > REPO/packages/baz-post-dep/baz-post-dep.1/opam << EOF
  > opam-version: "2.0"
  > depends: "random-dep"
  > EOF
  $ mkdir -p REPO/packages/baz-build-dep/baz-build-dep.1
  $ cat > REPO/packages/baz-build-dep/baz-build-dep.1/opam << EOF
  > opam-version: "2.0"
  > depends: "random-dep"
  > EOF
  $ mkdir -p REPO/packages/baz-installed-dep/baz-installed-dep.1
  $ cat > REPO/packages/baz-installed-dep/baz-installed-dep.1/opam << EOF
  > opam-version: "2.0"
  > EOF
  $ mkdir -p REPO/packages/baz-test-dep/baz-test-dep.1
  $ cat > REPO/packages/baz-test-dep/baz-test-dep.1/opam << EOF
  > opam-version: "2.0"
  > depends: "random-dep"
  > EOF
  $ mkdir -p REPO/packages/baz-depopt/baz-depopt.1
  $ cat > REPO/packages/baz-depopt/baz-depopt.1/opam << EOF
  > opam-version: "2.0"
  > depends: "random-dep"
  > EOF
  $ opam update 2>&1 | grep -v synchronised
  
  <><> Updating package repositories ><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 3 packages
    - install baz          dev (pinned)
    - install baz-post-dep 1
    - install random-dep   1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz.dev
  -> installed random-dep.1
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz.dev
  Done.
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
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove baz dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  Done.
  $ opam remove random-dep
  The following actions will be performed:
  === remove 2 packages
    - remove baz-post-dep 1 [uses random-dep]
    - remove random-dep   1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz-post-dep.1
  -> removed   random-dep.1
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 2 packages
    - install baz-build-dep 1
    - install random-dep    1 [required by baz-build-dep]
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed random-dep.1
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  $ opam remove random-dep
  The following actions will be performed:
  === remove 2 packages
    - remove baz-build-dep 1 [uses random-dep]
    - remove random-dep    1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz-build-dep.1
  -> removed   random-dep.1
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  === install 2 packages
    - install baz-test-dep 1
    - install random-dep   1 [required by baz-test-dep]
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed random-dep.1
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
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
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
  $ opam remove random-dep
  The following actions will be performed:
  === remove 2 packages
    - remove baz-test-dep 1 [uses random-dep]
    - remove random-dep   1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz-test-dep.1
  -> removed   random-dep.1
  Done.
=== 5E: depopt dependency
  $ opam install baz-depopt
  The following actions will be performed:
  === install 2 packages
    - install baz-depopt 1
    - install random-dep 1 [required by baz-depopt]
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed random-dep.1
  -> installed baz-depopt.1
  Done.
  $ cat > baz.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > depends: [
  >   "baz-dep"
  >   "baz-installed-dep"
  > ]
  > depopts: "baz-depopt"
  > EOF
ERROR: should reinstall depopt?
  $ opam-custom-install baz -y -- sh ../c-install 'test#5E'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz.dev
  Done.
  $ cat c-installed
  succesfully c-installed test#5E!
  $ opam show baz --raw --normalise
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: ["baz-installed-dep"]
  depopts: ["baz-depopt"]
  build: ["false" "local"]
  install: "false"
  $ opam remove baz baz-depopt random-dep
  The following actions will be performed:
  === remove 3 packages
    - remove baz        dev (pinned)
    - remove baz-depopt 1
    - remove random-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> removed   baz-depopt.1
  -> removed   random-dep.1
  Done.
  $ opam-custom-install baz -- sh ../c-install 'test#5E'
  Registering baz as pinned
  [WARNING] Ignored non-installed dependency on baz-dep
  The following actions will be performed:
  === install 1 package
    - install baz dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> installed baz.dev
  Done.
  $ opam show baz --raw --normalise
  opam-version: "2.0"
  name: "baz"
  version: "dev"
  depends: ["baz-installed-dep"]
  depopts: ["baz-depopt"]
  build: ["false" "local"]
  install: "false"
  $ opam install baz-depopt
  The following actions will be performed:
  === recompile 1 package
    - recompile baz        dev (pinned) [uses baz-depopt]
  === install 2 packages
    - install   baz-depopt 1
    - install   random-dep 1            [required by baz-depopt]
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz.dev
  -> installed random-dep.1
  -> installed baz-depopt.1
  [ERROR] The compilation of baz.dev failed at "false local".
  
  #=== ERROR while compiling baz.dev ============================================#
  # context     2.2.0~alpha~dev | linux/x86_64 |  | pinned
  # path        ~/ocamlpro/opam-custom-install/_build/.sandbox/7ec8d5c3ee7033cb2da4e71f5604ba7c/default/test/OPAMROOT/one/.opam-switch/build/baz.dev
  # command     ~/ocamlpro/opam-custom-install/_build/.sandbox/7ec8d5c3ee7033cb2da4e71f5604ba7c/default/test/OPAMROOT/opam-init/hooks/sandbox.sh build false local
  # exit-code   1
  # env-file    ~/ocamlpro/opam-custom-install/_build/.sandbox/7ec8d5c3ee7033cb2da4e71f5604ba7c/default/test/OPAMROOT/log/baz-1520077-07745a.env
  # output-file ~/ocamlpro/opam-custom-install/_build/.sandbox/7ec8d5c3ee7033cb2da4e71f5604ba7c/default/test/OPAMROOT/log/baz-1520077-07745a.out
  
  
  
  <><> Error report <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  +- The following actions failed
  | - build baz dev
  +- 
  +- The following changes have been performed
  | - remove  baz        dev
  | - install baz-depopt 1
  | - install random-dep 1
  +- 
  
  The former state can be restored with:
      /home/rjbou/ocp_usr/bin/opam switch import "$TESTCASE_ROOT/OPAMROOT/one/.opam-switch/backup/state-20221129171534.export"
  Or you can retry to install your package selection with:
      /home/rjbou/ocp_usr/bin/opam install --restore
  [31]
  $ rm c-installed
  $ opam unpin baz
  Ok, baz is no longer pinned locally (version dev)
  $ opam remove random-dep
  The following actions will be performed:
  === remove 2 packages
    - remove baz-depopt 1 [uses random-dep]
    - remove random-dep 1
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   baz-depopt.1
  -> removed   random-dep.1
  Done.
