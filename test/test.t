repo
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
  $ cat > compile << EOF
  > touch compiled
  > EOF
init opam
  $ mkdir $OPAMROOT
  $ opam init --bare ./REPO --no-setup --bypass-checks
  No configuration file found, using built-in defaults.
  
  <><> Fetching repository information ><><><><><><><><><><><><><><><><><><><><><>
  [default] Initialised
  $ opam switch create one --empty
launch test
Test 1: with repo & no local opam file
  $ mkdir foo
  $ cd foo
  $ opam-custom-install foo -- sh ../compile
  Registering foo as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  -> installed foo.1
  Done.
  $ test -f compiled
  $ opam pin
  foo.1    local definition
  $ rm compiled
  $ opam show foo --raw
  opam-version: "2.0"
  name: "foo"
  version: "1"
  build: ["false" "repo"]
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
Test 2: with repo & local opam file
  $ cat > foo.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > EOF
  $ opam-custom-install foo -- sh ../compile
  Registering foo as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile foo 1 (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   foo.1
  -> installed foo.1
  Done.
  $ test -f compiled
  $ opam pin
  foo.1    local definition
  $ opam show foo --raw
  opam-version: "2.0"
  name: "foo"
  version: "1"
  build: ["false" "local"]
  install: "false"
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
Test 3: with no repo & no local opam file
  $ mkdir bar
  $ cd bar
  $ opam-custom-install bar -- sh ../compile
  Registering bar as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ test -f compiled
  $ opam pin
  bar.dev    local definition
  $ opam show bar --raw
  opam-version: "2.0"
  name: "bar"
  version: "dev"
  synopsis: "Package installed using 'opam custom-install'"
  $ opam reinstall bar
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ opam unpin bar
  Ok, bar is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove bar dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  Done.
Test 4: with no repo & local opam file
  $ cat > bar.opam << EOF
  > opam-version: "2.0"
  > build: [ "false" "local" ]
  > install: "false"
  > EOF
  $ opam-custom-install bar -- sh ../compile
  Registering bar as pinned
  The following actions will be performed:
  === recompile 1 package
    - recompile bar dev (pinned)
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  -> installed bar.dev
  Done.
  $ test -f compiled
  $ opam pin
  bar.dev    local definition
  $ opam show bar --raw
  opam-version: "2.0"
  name: "bar"
  version: "dev"
  build: ["false" "local"]
  install: "false"
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
  $ opam unpin bar
  Ok, bar is no longer pinned locally (version dev)
  The following actions will be performed:
  === remove 1 package
    - remove bar dev
  
  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> removed   bar.dev
  Done.
