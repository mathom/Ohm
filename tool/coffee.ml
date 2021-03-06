(* Ohm is © 2012 Victor Nicollet *)

open BatPervasives

(* #>> funcname(param:type,?param:type) *)

let type_regexp = Str.regexp "#>>.*"
let func_regexp = Str.regexp "#>> *\\([a-z][A-Za-z0-9_]*\\) *(\\([^)]*\\))"

let space_regexp = Str.regexp "[ \t]+" 

let (!!) fmt = Printf.sprintf fmt

let clean string = 
  let string = BatString.trim string in 
  Str.global_replace space_regexp " " string

let genuid = 
  let n = ref 0 in
  fun () -> incr n ; !n

let type_fmt = function 
  | "html"        -> None, !! "Ohm.Html.to_json %s"
  | "json"        -> None, identity
  | "int"         -> None, !! "Ohm.Json.Int    %s"
  | "string"      -> None, !! "Ohm.Json.String %s"
  | "float"       -> None, !! "Ohm.Json.Float  %s"
  | "bool"        -> None, !! "Ohm.Json.Bool   %s"
  | "int list"    -> None, !! "Ohm.Json.Array (List.map (fun _x -> Ohm.Json.Int _x) %s)"
  | "string list" -> None, !! "Ohm.Json.Array (List.map (fun _x -> Ohm.Json.String _x) %s)"
  | "float list"  -> None, !! "Ohm.Json.Array (List.map (fun _x -> Ohm.Json.Float _x) %s)" 
  | "bool list"   -> None, !! "Ohm.Json.Array (List.map (fun _x -> Ohm.Json.Bool _x) %s)" 
  | other         -> let name = !! "F%d" (genuid ()) in
		     let fmt  = !! "module %s = Ohm.Fmt.Make(struct\n  open Ohm\n  type json t = (%s)\nend)"
		       name other 
		     in
		     Some fmt, !! "%s.to_json %s" name

type typ = bool * string * string * (string option * (string -> string)) 

let parse_types types = 
  let types = BatString.nsplit types "," in
  BatList.filter_map begin fun t -> 
    try let param, typ = BatString.split t ":" in
	let param = BatString.trim param in
	let typ   = BatString.trim typ in
	let opt, param = 
	  if param.[0] = '?' then 
	    true, BatString.trim (String.sub param 1 (String.length param - 1))
	  else
	    false, param
	in
	Some (opt, param, typ, type_fmt typ)
    with _ -> None
  end types
  
let extract_types coffee = 

  (* Extract all the type definition lines from the source *)
  let rec all acc pos = 
    let next = 
      try let pos  = Str.search_forward type_regexp coffee pos in
	  let what = Str.matched_string coffee in 
	  Some (what,pos+1)
      with Not_found -> None
    in
    match next with 
      | None           -> acc
      | Some (str,pos) -> all (str :: acc) pos
  in

  (* Extract the function and parameter list from a regular expression *)
  let extract definition = 
    if Str.string_match func_regexp definition 0 then 
      let name  = Str.matched_group 1 definition in
      let types = Str.matched_group 2 definition in      
      let types = parse_types types in
      Some (name, types) 
    else
      None
  in

  let functions = BatList.filter_map extract (all [] 0) in

  let formats = 
    List.concat 
      (List.map (fun (_,l) -> BatList.filter_map (fun (_,_,_,t) -> fst t) l) functions) 
  in

  let formats_ml = String.concat "\n" formats in

  let to_ml (name,types) =
    let params = 
      List.map 
	(fun (opt,name,_,_) -> !! "%c%s" (if opt then '?' else '~') name) types
    and args = 
      List.map 
	(fun (opt,name,_,(_,t)) -> 
	  if opt then
	    !! "BatOption.default Ohm.Json.Null (BatOption.map (fun _x -> %s) %s)"
	      (t "_x") name
	  else
	    t name) types	  
    in 

    !! "let %s %s () =\n  Ohm.JsCode.make ~name:%S ~args:[\n    %s\n  ]\n"
      name (String.concat " " params) name (String.concat " ;\n    " args)
  in
  
  let to_mli (name,types) = 
    let params = 
      List.map 
	(fun (opt,name,t,_) -> !! "%s%s:%s" (if opt then "?" else "") name t) types
    in
    if types = [] then
      !! "val %s : unit -> Ohm.JsCode.t" name 
    else 
      !! "val %s : %s -> unit -> Ohm.JsCode.t"
	name (String.concat " -> " params)  
  in

  let ml = 
    "(* This file was generated by ohm-tool *)\n"
    ^ "type html = Ohm.Html.writer\n"
    ^ "module Json = Ohm.Json\n"
    ^ formats_ml
    ^ "\n"
    ^ String.concat "\n" (List.map to_ml functions) 
  and mli =
    "(* This file was generated by ohm-tool *)\n"
    ^ "type html = Ohm.Html.writer\n"
    ^ "module Json : sig type t = Ohm.Json.t end\n"
    ^ String.concat "\n" (List.map to_mli functions)  
  in
  
  ml, mli
    
