(**************************************************************************)
(*                                                                        *)
(*    Copyright 2020 OCamlPro                                             *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

open Cmdliner
open OpamTypes
open OpamStateTypes

let custom_install_doc =
  "Install a package using a custom command."

let get_source_definition ?version nv url =
  let srcdir = OpamFilename.cwd () in
  let subsrcdir =
    match OpamFile.URL.subpath url with
    | None -> srcdir
    | Some subpath -> OpamFilename.SubPath.(srcdir / subpath)
  in
  let open OpamStd.Option.Op in
  OpamPinned.find_opam_file_in_source nv.name subsrcdir >>= fun (f, _locked_ext) ->
  OpamPinCommand.read_opam_file_for_pinning ~quiet:true
    nv.name f (OpamFile.URL.url url)
  >>| fun opam ->
  OpamFile.OPAM.with_url url @@
  (match version with
   | Some v -> OpamFile.OPAM.with_version v
   | None -> fun o -> o) @@
  opam

let default_opam nv =
  OpamFile.OPAM.create nv |>
  OpamFile.OPAM.with_synopsis
    ("Package installed using 'opam custom-install'")

let default_version st name =
  try OpamPackage.version (OpamSwitchState.get_package st name)
  with Not_found -> OpamPackage.Version.of_string "dev"

let source_pin st name ?version ?subpath target_url =
  let open OpamStd.Option.Op in

  let cur_version =
    try OpamPinned.version st name
    with Not_found -> default_version st name
  in

  let pin_version = version +! cur_version in

  let nv = OpamPackage.create name pin_version in

  let urlf = OpamFile.URL.create ?subpath target_url in

  let opam_opt =
    get_source_definition ?version nv urlf
  in
  let opam_opt = opam_opt >>| OpamFormatUpgrade.opam_file in

  let nv =
    match version with
    | Some _ -> nv
    | None ->
      OpamPackage.create name
        ((opam_opt >>= OpamFile.OPAM.version_opt)
         +! cur_version)
  in

  let opam =
    (opam_opt >>+ fun () ->
     OpamPackage.Map.find_opt nv st.installed_opams >>+ fun () ->
     OpamSwitchState.opam_opt st nv)
    +! default_opam nv
  in
  let version = version +! (OpamFile.OPAM.version_opt opam +! nv.version) in
  let opam =
    opam |>
    OpamFile.OPAM.with_name name |>
    OpamFile.OPAM.with_version version |>
    OpamFile.OPAM.with_extra_files [] |>
    OpamFile.OPAM.with_extra_sources [] |>
    OpamFile.OPAM.with_patches [] |>
    OpamFile.OPAM.with_url_opt None
  in

  let st = OpamSwitchState.update_pin nv opam st in

  OpamSwitchAction.write_selections st;

  OpamConsole.msg "Registering %s as pinned\n"
    (OpamPackage.Name.to_string name);

  st, opam


let custom_install cli =
  let doc = custom_install_doc in
  let man = [
    `S Manpage.s_description;
    `P "This command allows to wrap a custom install command, and make opam \
        register it as the installation of a given package.";
    `P "Be aware that this is a low-level command that allows you to break \
        some opam invariants: use this if you want to be in complete control \
        over the installation of the given package, and are ready to cope with \
        the consequences in the opam commands that you will run next.";
    `P "Any previously installed version of the package will still be removed \
        before performing the installation, together with packages that have a \
        dependency on $(i,PACKAGE) (unless $(b,--no-recompilations) was \
        specified), which will be recompiled afterwards.";
    `P "Usecase: you are working on the source of some package, pinned or not, \
        and want to quickly test your patched version without having opam \
        clone and recompile the whole source. Running $(b,opam custom-install \
        foo -- make install) instead of just $(b,make install) has the \
        benefits that (i) opam will allow you to intall packages depending on \
        $(b,foo), and (ii) when you choose to reinstall $(b,foo) later on, \
        opam will be able to cleanly remove your custom installation.";
    `S Manpage.s_arguments;
    `S Manpage.s_options;
  ] @ OpamArg.man_build_option_section
  in
  let no_recompilations =
    Arg.(value & flag & info ["no-recompilations"; "n"] ~doc:
           "Just do the installation, ignoring and preserving the state of any \
            dependent packages.")
  in
  let packages =
    Arg.(required & pos 0 (some OpamArg.package) None &
         info [] ~docv:"PACKAGE[.VERSION]" ~doc:
           "Package which should be registered as installed with the files \
            installed by $(i,COMMAND).")
  in
  let cmd =
    Arg.(non_empty & pos_right 0 string [] &
         info [] ~docv:"-- COMMAND [ARG]" ~doc:
           "Command to run in the current directory that is expected to \
            install the files for $(i,PACKAGE) to the current opam switch \
            prefix. Variable expansions like $(b,%{prefix}%), $(b,%{name}%), \
            $(b,%{version}%) and $(b,%{package}%) are expanded as per the \
            $(i,install:) package definition field.")
  in
  let custom_install
      global_options build_options no_recompilations (name, version) cmd () =
    OpamArg.apply_global_options cli global_options;
    OpamArg.apply_build_options cli build_options;
    OpamClientConfig.update
      ~inplace_build:true
      ~working_dir:true
      ~assume_depexts:true
      ();
    OpamGlobalState.with_ `Lock_none @@ fun gt ->
    OpamSwitchState.with_ `Lock_write gt @@ fun st ->
    let build_dir = OpamFilename.cwd () in
    let url =
      OpamUrl.parse ~backend:`rsync (OpamFilename.Dir.to_string build_dir)
    in

    let st, pin_opam_file = source_pin st name ?version url in
    let nv = OpamFile.OPAM.package pin_opam_file in

    let depends = OpamFile.OPAM.depends pin_opam_file in
    let patched_depends =
      (* let deps_formula =
       *   OpamPackageVar.all_depends
       *     ~build:true ~post:true ~test:true ~doc:true ~dev:true ~depopts:false
       *     st pin_opam_file
       * in *)
      OpamFormula.map (fun (name, cstr) ->
          let f ~post ~default =
            OpamPackageVar.filter_depends_formula ~post ~default
              ~build:true ~test:true ~doc:true ~dev:true
              ~env:(OpamPackageVar.resolve_switch ~package:nv st)
              (Atom (name, cstr))
            |> OpamFormula.to_atom_formula
          in
          if OpamPackage.Set.exists (fun nv ->
              OpamFormula.eval (fun at -> OpamFormula.check at nv)
                (f ~post:true ~default:false))
              st.installed
          then Atom (name, cstr)
          else if f ~post:false ~default:true = OpamFormula.Empty
          then Atom (name, cstr) (* keep post-dependencies *)
          else if OpamPackage.has_name st.installed name then
            (OpamConsole.warning
               "Ignored non-matching version constraint for %s"
               (OpamPackage.Name.to_string name);
             Atom (name, Empty))
          else
            (OpamConsole.warning
               "Ignored non-installed dependency on %s"
               (OpamPackage.Name.to_string name);
             Empty))
        depends
    in
    (* todo? Also remove installed conflicts? *)
    let pin_opam_file =
      pin_opam_file
      |> OpamFile.OPAM.with_depends patched_depends
    in
    if not OpamStateConfig.(!r.dryrun) then
      OpamFile.OPAM.write_with_preserved_format
        (OpamPath.Switch.Overlay.opam st.switch_global.root st.switch name)
        pin_opam_file;
    let patched_opam_file =
      pin_opam_file
      (* |> OpamFile.OPAM.with_build [] *)
      |> OpamFile.OPAM.with_install
        [List.map (fun a -> CString a, None) cmd, None]
      |> OpamFile.OPAM.with_url (* needed for inplace_build correct build dir *)
        (OpamFile.URL.create url)
        (* XXX what happens in case there is a .install file ? *)
    in
    let st = OpamSwitchState.update_package_metadata nv patched_opam_file st in
    let st =
      let atoms = [name, Some (`Eq, nv.version)] in
      let request = OpamSolver.request ~install:atoms ~criteria:`Fixup () in
      let names = OpamPackage.Name.Set.singleton name in
      let requested = OpamPackage.packages_of_names st.packages names in
      let reinstall = OpamPackage.packages_of_names st.installed names in
      let solution =
        OpamSolution.resolve st Reinstall
          ~reinstall
          ~requested
          request
      in
      let st, res = match solution with
        | Conflicts cs ->
          (* this shouldn't happen, we checked the requirements already *)
          OpamConsole.error "Package conflict!";
          OpamConsole.errmsg "%s"
            (OpamCudf.string_of_conflicts st.packages
               (OpamSwitchState.unavailable_reason st) cs);
          OpamStd.Sys.exit_because `No_solution
        | Success solution ->
          let solution =
            if no_recompilations then
              OpamSolver.filter_solution
                (fun nv -> OpamPackage.Name.Set.mem nv.name names)
                solution
            else solution
          in
          OpamSolution.apply st ~requested ~assume_built:true solution
      in
      let st =
        match res with
        | OK acts | Partial_error { actions_successes = acts; _ }
          when List.mem (`Install nv) acts ->
          (* Revert the install instructions to what appears in the overlay
             (avoids prompt to reinstall on next run) *)
          let st =
            OpamSwitchState.update_package_metadata nv pin_opam_file st
          in
          if not OpamStateConfig.(!r.dryrun) then
            OpamSwitchAction.install_metadata st nv;
          st
        | _ -> st
      in
      OpamSolution.check_solution st (Success res);
      st
    in
    OpamSwitchState.drop st
  in
  OpamArg.mk_command ~cli OpamArg.cli_original "custom-install" ~doc ~man
    Term.(const custom_install
          $ OpamArg.global_options cli
          $ OpamArg.build_options cli
          $ no_recompilations $ packages $ cmd)

let () =
  OpamStd.Option.iter OpamVersion.set_git OpamGitVersion.version;
  OpamSystem.init ();
  (* OpamArg.preinit_opam_envvariables (); *)
  OpamCliMain.main_catch_all @@ fun () ->
  let term, info = custom_install (OpamCLIVersion.default, `Default) in
  exit @@ Cmd.eval ~catch:false (Cmd.v info term)





(* -- junkyard, might be useful for scrap code if we want to do the
   recompilations more manually *)


(* let with_recompile_cone st nv f =
 *   let revdeps =
 *     let deps nv =
 *       OpamSwitchState.opam st nv |>
 *       OpamPackageVar.all_depends
 *         ~build:true ~post:false ~test:false ~doc:false
 *         ~dev:(OpamSwitchState.is_dev_package st nv)
 *     in
 *     OpamPackage.Set.filter (fun nv1 -> OpamFormula.verifies (deps nv1) nv)
 *       st.installed_packages
 *   in
 *   if OpamPackage.Set.is_empty revdeps then f () else
 *   let univ =
 *     OpamSwitchState.universe ~reinstall:revdeps ~requested:nv st
 *   in
 * 
 *    * let sol =
 *    *   OpamSolver.resolve universe ~orphans:OpamPackage.Set.empty
 *    *     { criteria=`Fixup;
 *    *       wish_install=[];
 *    *       wish_remove=[];
 *    *       wish_upgrade=[];
 *    *       extra_attributes=[];
 *    *     } *)


(* let recompile_cone =
 *   OpamPackage.Set.of_list @@
 *   OpamSolver.reverse_dependencies
 *     ~depopts:true ~installed:true ~unavailable:true
 *     ~build:true ~post:false
 *     universe (OpamPackage.Set.singleton nv)
 * in
 * 
 * (\* The API exposes no other way to create an empty solution *\)
 * let solution = OpamSolver.solution_of_json `Null in
 * OpamSolver.print_solution
 *   ~messages:(fun _ -> [])
 *   ~append:(fun nv -> if OpamSwitchState.Set.mem nv st.pinned then "*" else "")
 *   ~requested:OpamPackage.Name.Set.empty
 *   ~reinstall:recompile_cone
 *   solution;
 * 
 * let 
 *   OpamSwitchState.universe ~reinstall:(OpamPackage.Set.singleton nv) ~requested:nv st
 * in
 * let sol =
 *   OpamSolver.resolve universe ~orphans:OpamPackage.Set.empty
 *     { criteria=`Fixup;
 *       wish_install=[];
 *       wish_remove=[];
 *       wish_upgrade=[];
 *       extra_attributes=[];
 *     }
 * in *)

