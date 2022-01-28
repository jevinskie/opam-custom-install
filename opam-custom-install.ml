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

let custom_install_doc =
  "Install a package using a custom command."

let get_source_definition ?version ?subpath st nv url =
  let root = st.switch_global.root in
  let srcdir = OpamFilename.cwd () in
  let subsrcdir =
    match OpamFile.URL.subpath url with
    | None -> srcdir
    | Some subpath -> OpamFilename.Op.(srcdir / subpath)
  in
  let open OpamStd.Option.Op in
  OpamPinned.find_opam_file_in_source nv.name subsrcdir >>= fun f ->
  OpamPinCommand.read_opam_file_for_pinning ~quiet:true
    nv.name f (OpamFile.URL.url url)
  >>| fun opam ->
  OpamFile.OPAM.with_url url @@
  (match version with
   | Some v -> OpamFile.OPAM.with_version v
   | None -> fun o -> o) @@
  opam


let source_pin st name ?version ?subpath target_url =
  log "pin %a to %a %a%a"
    (slog OpamPackage.Name.to_string) name
    (slog (OpamStd.Option.to_string OpamPackage.Version.to_string)) version
    (slog (OpamStd.Option.to_string ~none:"none" OpamUrl.to_string)) target_url;

  let open OpamStd.Option.Op in

  let cur_version, cur_urlf =
    try
      let cur_version = OpamPinned.version st name in
      let nv = OpamPackage.create name cur_version in
      let cur_opam = OpamSwitchState.opam st nv in
      let cur_urlf = OpamFile.OPAM.url cur_opam in
    with Not_found ->
      let version = default_version st name in
      version, None
  in

  let pin_version = version +! cur_version in

  let nv = OpamPackage.create name pin_version in

  let urlf = target_url >>| OpamFile.URL.create ?subpath in

  let opam_opt =
    try
      urlf >>= fun url ->
      OpamProcess.Job.run @@ get_source_definition ?version ?subpath ?locked st nv url
    with Fetch_Fail err ->
      if force then None else
        (OpamConsole.error_and_exit `Sync_error
           "Error getting source from %s:\n%s"
           (OpamStd.Option.to_string OpamUrl.to_string target_url)
           (OpamStd.Format.itemize (fun x -> x) [err]));
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

  let opam_opt =
    opam_opt >>+ fun () ->
    OpamPackage.Map.find_opt nv st.installed_opams >>+ fun () ->
    OpamSwitchState.opam_opt st nv
  in

  let opam_opt =
    match opam_local, opam_opt with
    | Some local, None ->
      OpamConsole.warning
        "Couldn't retrieve opam file from versioned source, \
         using the one found locally.";
      Some local
    | Some local, Some vers when
        not OpamFile.(OPAM.effectively_equal
                        (OPAM.with_url URL.empty local)
                        (OPAM.with_url URL.empty vers)) ->
      OpamConsole.warning
        "%s's opam file has uncommitted changes, using the versioned one"
        (OpamPackage.Name.to_string name);
      opam_opt
    | _ -> opam_opt
  in

  if not need_edit && opam_opt = None then
    OpamConsole.note
      "No package definition found for %s: please complete the template"
      (OpamConsole.colorise `bold (OpamPackage.to_string nv));

  let need_edit = need_edit || opam_opt = None in

  let opam_opt =
    let opam_base = match opam_opt with
      | None -> OpamFileTools.template nv
      | Some opam -> opam
    in
    let opam_base =
      OpamFile.OPAM.with_url_opt urlf opam_base
    in
    if need_edit then
      (if not (OpamFile.exists temp_file) then
         OpamFile.OPAM.write_with_preserved_format
           ?format_from:(OpamPinned.orig_opam_file st name opam_base)
           temp_file opam_base;
       edit_raw name temp_file >>|
       (* Preserve metadata_dir so that copy_files below works *)
       OpamFile.OPAM.(with_metadata_dir (metadata_dir opam_base))
      )
    else
      Some opam_base
  in
  match opam_opt with
  | None ->
    OpamConsole.error_and_exit `Not_found
      "No valid package definition found"
  | Some opam ->
    let opam =
      match OpamFile.OPAM.get_url opam with
      | Some _ -> opam
      | None -> OpamFile.OPAM.with_url_opt urlf opam
    in
    let version = version +! (OpamFile.OPAM.version_opt opam +! nv.version) in
    let nv = OpamPackage.create nv.name version in
    let st =
      if ignore_extra_pins then st
      else handle_pin_depends st nv opam
    in
    let opam =
      opam |>
      OpamFile.OPAM.with_name name |>
      OpamFile.OPAM.with_version version
    in
    OpamFilename.rmdir
      (OpamPath.Switch.Overlay.package st.switch_global.root st.switch nv.name);

    let opam = copy_files st opam in

    OpamFile.OPAM.write_with_preserved_format
      ?format_from:(OpamPinned.orig_opam_file st name opam)
      (OpamPath.Switch.Overlay.opam st.switch_global.root st.switch nv.name)
      opam;

    OpamFilename.remove (OpamFile.filename temp_file);

    let st = OpamSwitchState.update_pin nv opam st in

    if not OpamClientConfig.(!r.show) then
      OpamSwitchAction.write_selections st;
    OpamConsole.msg "%s is now %s\n"
      (OpamPackage.Name.to_string name)
      (string_of_pinned opam);

    st


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
      ();
    OpamGlobalState.with_ `Lock_none @@ fun gt ->
    OpamSwitchState.with_ `Lock_write gt @@ fun st ->
    let build_dir = OpamFilename.cwd () in
    let url =
      OpamUrl.parse ~backend:`rsync (OpamFilename.Dir.to_string build_dir)
    in
    let st =
      OpamPinCommand.source_pin st name ?version url
    in
    let nv = OpamPinned.package st name in
    let pin_opam_file = OpamSwitchState.opam st nv in
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
    let pin_opam_file =
      pin_opam_file
      |> OpamFile.OPAM.with_depends patched_depends
      (* |> OpamFile.OPAM.with_url (\* needed for inplace_build correct build dir *\)
       *   (OpamFile.URL.create url) *)
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
        (* XXX what happens in case there is a .install file ? *)
    in
    let st = OpamSwitchState.update_package_metadata nv patched_opam_file st in
    let st =
      let atoms = [name, Some (`Eq, nv.version)] in
      let request = OpamSolver.request ~install:atoms ~criteria:`Fixup () in
      let requested = OpamPackage.Name.Set.singleton name in
      let solution =
        OpamSolution.resolve st Reinstall
          ~reinstall:(OpamPackage.packages_of_names st.installed requested)
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
                (fun nv -> OpamPackage.Name.Set.mem nv.name requested)
                solution
            else solution
          in
          OpamSolution.apply st ~requested ~assume_built:true solution
      in
      let st =
        match res with
        | OK acts | Partial_error { actions_successes = acts; _ } ->
          if List.mem (`Install nv) acts then
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
  match Term.eval ~catch:false (custom_install (OpamCLIVersion.default, `Default)) with
  | `Error _ -> exit (OpamStd.Sys.get_exit_code `Bad_arguments)
  | _        -> exit (OpamStd.Sys.get_exit_code `Success)




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

