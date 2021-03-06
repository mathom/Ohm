(* Ohm is © 2013 Victor Nicollet *)

open BatPervasives

type pos = Lexing.position * Lexing.position 

type cell = 
  | Cell_String of string
  | Cell_Print  of expr 
  | Cell_AdLib  of located * expr option
  | Cell_If     of expr * cell list * cell list
  | Cell_Id     of located
  | Cell_Option of located option * expr * cell list * cell list
  | Cell_List   of located option * expr * cell list * cell list
  | Cell_Sub    of expr * cell list
  | Cell_Define of bool * located * cell list
  | Cell_Style  of string
  | Cell_Script of string option * string
and expr = located option * expr_flag list 
and expr_flag = located list
and located = {
  contents : string ;
  position : pos
}
    
let pos lexbuf = 
  Lexing.lexeme_start_p lexbuf, Lexing.lexeme_end_p lexbuf
    
let cell c = c
  
let located (contents,position) = { contents ; position }

(* This cleans up the separate "string" cells by merging them together and applying
   a whitespace-to-' ', ' '*-to-' ', &foo;-to-UTF8 series of transforms that help
   shorten the source. *)
let whitespace_chars =
  String.concat ""
    (List.map (String.make 1)
       [
         Char.chr 9;  (* HT *)
         Char.chr 10; (* LF *)
         Char.chr 11; (* VT *)
         Char.chr 12; (* FF *)
         Char.chr 13; (* CR *)
         Char.chr 32; (* space *)
       ])

let whitespace_re = Str.regexp ("[" ^ whitespace_chars ^ "]+")
let entity_re = Str.regexp "&\\([a-zA-Z0-9]+\\);"  

let clean_string s = 
  let s = Str.global_replace whitespace_re " " s in
  let s = Str.global_substitute entity_re (fun s -> 
    match Str.matched_group 1 s with 
      | "iexcl"  -> "¡"
      | "cent"   -> "¢"
      | "pound"  -> "£"
      | "curren" -> "¤"
      | "yen"    -> "¥"
      | "brvbar" -> "¦"
      | "sect"   -> "§"
      | "uml"    -> "¨"
      | "copy"   -> "©"
      | "ordf"   -> "ª"
      | "laquo"  -> "«"
      | "not"    -> "¬"
      | "reg"    -> "®"
      | "macr"   -> "¯"
      | "deg"    -> "°"
      | "plusmn" -> "±"
      | "sup2"   -> "²"
      | "sup3"   -> "³"
      | "acute"  -> "´"
      | "micro"  -> "µ"
      | "para"   -> "¶"
      | "middot" -> "·"
      | "cedil"  -> "¸"
      | "sup1"   -> "¹"
      | "ordm"   -> "º"
      | "raquo"  -> "»"
      | "frac14" -> "¼"
      | "frac12" -> "½"
      | "frac34" -> "¾"
      | "iquest" -> "¿"
      | "Agrave" -> "À"
      | "Aacute" -> "Á"
      | "Acirc"  -> "Â"
      | "Atilde" -> "Ã"
      | "Auml"   -> "Ä"
      | "Aring"  -> "Å"
      | "AElig"  -> "Æ"
      | "Ccedil" -> "Ç"
      | "Egrave" -> "È"
      | "Eacute" -> "É"
      | "Ecirc"  -> "Ê"
      | "Euml"   -> "Ë"
      | "Igrave" -> "Ì"
      | "Iacute" -> "Í"
      | "Icirc"  -> "Î"
      | "Iuml"   -> "Ï"
      | "ETH"    -> "Ð"
      | "Ntilde" -> "Ñ"
      | "Ograve" -> "Ò"
      | "Oacute" -> "Ó"
      | "Ocirc"  -> "Ô"
      | "Otilde" -> "Õ"
      | "Ouml"   -> "Ö"
      | "times"  -> "×"
      | "Oslash" -> "Ø"
      | "Ugrave" -> "Ù"
      | "Uacute" -> "Ú"
      | "Ucirc"  -> "Û"
      | "Uuml"   -> "Ü"
      | "Yacute" -> "Ý"
      | "THORN"  -> "Þ"
      | "szlig"  -> "ß"
      | "agrave" -> "à"
      | "aacute" -> "á"
      | "acirc"  -> "â"
      | "atilde" -> "ã"
      | "auml"   -> "ä"
      | "aring"  -> "å"
      | "aelig"  -> "æ"
      | "ccedil" -> "ç"
      | "egrave" -> "è"
      | "eacute" -> "é"
      | "ecirc"  -> "ê"
      | "euml"   -> "ë"
      | "igrave" -> "ì"
      | "iacute" -> "í"
      | "icirc"  -> "î"
      | "iuml"   -> "ï"
      | "eth"    -> "ð"
      | "ntilde" -> "ñ"
      | "ograve" -> "ò"
      | "oacute" -> "ó"
      | "ocirc"  -> "ô"
      | "otilde" -> "õ"
      | "ouml"   -> "ö"
      | "divide" -> "÷"
      | "oslash" -> "ø"
      | "ugrave" -> "ù"
      | "uacute" -> "ú"
      | "ucirc"  -> "û"
      | "uuml"   -> "ü"
      | "yacute" -> "ý"
      | "thorn"  -> "þ"
      | "yuml"   -> "ÿ"
      | "OElig"  -> "Œ"
      | "oelig"  -> "œ"
      | "Scaron" -> "Š"
      | "scaron" -> "š"
      | "Yuml"   -> "Ÿ"
      | "fnof"   -> "ƒ"
      | "circ"   -> "ˆ"
      | "tilde"  -> "˜"
      | "Alpha"  -> "Α"
      | "Beta"   -> "Β"
      | "Gamma"  -> "Γ"
      | "Delta"  -> "Δ"
      | "Epsilon" -> "Ε"
      | "Zeta"   -> "Ζ"
      | "Eta"    -> "Η"
      | "Theta"  -> "Θ"
      | "Iota"   -> "Ι"
      | "Kappa"  -> "Κ"
      | "Lambda" -> "Λ"
      | "Mu"     -> "Μ"
      | "Nu"     -> "Ν"
      | "Xi"     -> "Ξ"
      | "Omicron" -> "Ο"
      | "Pi"     -> "Π"
      | "Rho"    -> "Ρ"
      | "Sigma"  -> "Σ"
      | "Tau"    -> "Τ"
      | "Upsilon" -> "Υ"
      | "Phi"    -> "Φ"
      | "Chi"    -> "Χ"
      | "Psi"    -> "Ψ"
      | "Omega"  -> "Ω"
      | "alpha"  -> "α"
      | "beta"   -> "β"
      | "gamma"  -> "γ"
      | "delta"  -> "δ"
      | "epsilon" -> "ε"
      | "zeta"   -> "ζ"
      | "eta"    -> "η"
      | "theta"  -> "θ"
      | "iota"   -> "ι"
      | "kappa"  -> "κ"
      | "lambda" -> "λ"
      | "mu"     -> "μ"
      | "nu"     -> "ν"
      | "xi"     -> "ξ"
      | "omicron" -> "ο"
      | "pi"     -> "π"
      | "rho"    -> "ρ"
      | "sigmaf" -> "ς"
      | "sigma"  -> "σ"
      | "tau"    -> "τ"
      | "upsilon" -> "υ"
      | "phi"    -> "φ"
      | "chi"    -> "χ"
      | "psi"    -> "ψ"
      | "omega"  -> "ω"
      | "thetasym" -> "ϑ"
      | "upsih"  -> "ϒ"
      | "piv"    -> "ϖ"
      | "ensp"   -> " "
      | "emsp"   -> " "
      | "thinsp" -> " "
      | "ndash"  -> "–"
      | "mdash"  -> "—"
      | "lsquo"  -> "‘"
      | "rsquo"  -> "’"
      | "sbquo"  -> "‚"
      | "ldquo"  -> "“"
      | "rdquo"  -> "”"
      | "bdquo"  -> "„"
      | "dagger" -> "†"
      | "Dagger" -> "‡"
      | "bull"   -> "•"
      | "hellip" -> "…"
      | "permil" -> "‰"
      | "prime"  -> "′"
      | "Prime"  -> "″"
      | "lsaquo" -> "‹"
      | "rsaquo" -> "›"
      | "oline"  -> "‾"
      | "frasl"  -> "⁄"
      | "euro"   -> "€"
      | "image"  -> "ℑ"
      | "weierp" -> "℘"
      | "real"   -> "ℜ"
      | "trade"  -> "™"
      | "alefsym" -> "ℵ"
      | "larr"   -> "←"
      | "uarr"   -> "↑"
      | "rarr"   -> "→"
      | "darr"   -> "↓"
      | "harr"   -> "↔"
      | "crarr"  -> "↵"
      | "lArr"   -> "⇐"
      | "uArr"   -> "⇑"
      | "rArr"   -> "⇒"
      | "dArr"   -> "⇓"
      | "hArr"   -> "⇔"
      | "forall" -> "∀"
      | "part"   -> "∂"
      | "exist"  -> "∃"
      | "empty"  -> "∅"
      | "nabla"  -> "∇"
      | "isin"   -> "∈"
      | "notin"  -> "∉"
      | "ni"     -> "∋"
      | "prod"   -> "∏"
      | "sum"    -> "∑"
      | "minus"  -> "−"
      | "lowast" -> "∗"
      | "radic"  -> "√"
      | "prop"   -> "∝"
      | "infin"  -> "∞"
      | "ang"    -> "∠"
      | "and"    -> "∧"
      | "or"     -> "∨"
      | "cap"    -> "∩"
      | "cup"    -> "∪"
      | "int"    -> "∫"
      | "there4" -> "∴"
      | "sim"    -> "∼"
      | "cong"   -> "≅"
      | "asymp"  -> "≈"
      | "ne"     -> "≠"
      | "equiv"  -> "≡"
      | "le"     -> "≤"
      | "ge"     -> "≥"
      | "sub"    -> "⊂"
      | "sup"    -> "⊃"
      | "nsub"   -> "⊄"
      | "sube"   -> "⊆"
      | "supe"   -> "⊇"
      | "oplus"  -> "⊕"
      | "otimes" -> "⊗"
      | "perp"   -> "⊥"
      | "sdot"   -> "⋅"
      | "lceil"  -> "⌈"
      | "rceil"  -> "⌉"
      | "lfloor" -> "⌊"
      | "rfloor" -> "⌋"
      | "lang"   -> "〈"
      | "rang"   -> "〉"
      | "loz"    -> "◊"
      | "spades" -> "♠"
      | "clubs"  -> "♣"
      | "hearts" -> "♥"
      | "diams"  -> "♦"
      | other -> "&"^other^";"
  ) s in
  s

let rec clean_strings = function 
  | [] -> [] 
  | Cell_Id s :: tail -> Cell_Id s :: clean_strings tail 
  | Cell_Script (t,s) :: tail -> Cell_Script (t,s) :: clean_strings tail
  | Cell_Style  s :: tail -> Cell_Style s :: clean_strings tail 
  | Cell_String a :: Cell_String b :: tail -> clean_strings (Cell_String (a ^ b) :: tail) 
  | Cell_String a :: tail -> Cell_String (clean_string a) :: clean_strings tail
  | Cell_Print  x :: tail -> Cell_Print x :: clean_strings tail
  | Cell_AdLib (v,e) :: tail -> Cell_AdLib (v,e) :: clean_strings tail
  | Cell_If (e,a,b) :: tail -> Cell_If (e,
					clean_strings a, 
					clean_strings b) :: clean_strings tail 
  | Cell_Option (l,e,a,b) :: tail -> Cell_Option (l,e, 
						  clean_strings a,
						  clean_strings b) :: clean_strings tail
  | Cell_List (l,e,a,b) :: tail -> Cell_List (l,e,
					      clean_strings a,
					      clean_strings b) :: clean_strings tail
  | Cell_Sub (e,l) :: tail -> Cell_Sub (e,clean_strings l) :: clean_strings tail
  | Cell_Define (s,n,l) :: tail -> Cell_Define (s,n,clean_strings l) :: clean_strings tail

(* This extracts the strings from the asset AST into a side buffer ("current") 
   by eliminating duplicate strings. This turns every Cell_String into a 
   `String (start,length) that references this side buffer *)

type buffered_cell = 
    [ `Print  of expr
    | `Id     of located
    | `AdLib  of located * expr option
    | `If     of expr * buffered_cell list * buffered_cell list
    | `Option of located option * expr * buffered_cell list * buffered_cell list
    | `List   of located option * expr * buffered_cell list * buffered_cell list
    | `String of int * int
    | `Script of string * Coffee.typ list
    | `Sub    of expr * buffered_cell list 
    | `Define of bool * located * buffered_cell list
    ]
  
type extracted = {
  html   : string ;
  htmls  : (string * string) list ; 
  css    : Buffer.t ;
  id     : int ;
  coffee : Buffer.t ;
}

let rec extract_strings extracted list = 

  let list = clean_strings list in 

  let find extracted substring = 
    let string = extracted.html in 
    let n = String.length string and m = String.length substring in 
    let rec at i j = i + j >= n || j >= m || string.[i+j] = substring.[j] && at i (succ j) in 
    let rec search i = if at i 0 then i else search (succ i) in
    let start  = search 0 in
    let concat = max 0 (start + m - n) in
    (if concat = 0 then extracted else 
	{ extracted with html = string ^ String.sub substring (m - concat) concat } ),
    start, m 
  in

  let coffee extracted types script =
    let types = BatOption.default [] (BatOption.map Coffee.parse_types types) in
    let args  = String.concat "," (List.map (fun (_,n,_,_) -> n) types) in
    let id = extracted.id in
    let name = "ohm" ^ string_of_int id in 
    Buffer.add_string extracted.coffee 
      (Printf.sprintf "\n@%s = (here%s%s) ->\n  here[k] = $('#'+here[k]) for k of here\n  " name 
	 (if types = [] then "" else ",") args) ;
    let script = String.concat "\n  " (BatString.nsplit script "\n") in
    Buffer.add_string extracted.coffee script ; 
    let extracted = { extracted with id = succ id } in    
    extracted, `Script (name,types)
  in

  let extract extracted = function
    | Cell_Print e -> extracted, `Print e
    | Cell_Id id -> extracted, `Id id
    | Cell_AdLib (v,e) -> extracted, `AdLib (v,e)
    | Cell_Style s -> Buffer.add_string extracted.css s ; extracted, `String (0,0)
    | Cell_Script (t,s) -> coffee extracted t s 
    | Cell_If (e,a,b) -> let extracted, a = extract_strings extracted a in
			 let extracted, b = extract_strings extracted b in 
			 extracted, `If (e,a,b)
    | Cell_Option (l,e,a,b) -> let extracted, a = extract_strings extracted a in
			       let extracted, b = extract_strings extracted b in
			       extracted, `Option (l,e,a,b)
    | Cell_List (l,e,a,b) -> let extracted, a = extract_strings extracted a in
			     let extracted, b = extract_strings extracted b in 
			     extracted, `List (l,e,a,b)
    | Cell_Sub (e,l) -> let extracted, l = extract_strings extracted l in
			extracted, `Sub (e,l) 
    | Cell_Define (sub,n,l) -> let extracted, l = extract_strings extracted l in 
			   extracted, `Define (sub,n,l)
    | Cell_String s -> let extracted, start, length = find extracted s in 
		       extracted, `String (start, length)
  in

  List.fold_right 
    (fun cell (extracted, out) -> 
      let extracted, cell = extract extracted cell in 
      (extracted, cell :: out))
    list (extracted,[])

(* This extracts `Define cells and replaces them with an appropriate `Call cell. The
   extracted definitions all have a complete REVERSED name. *)

type clean_cell = 
  [ `Print  of expr
  | `AdLib  of located * expr option
  | `Id     of located 
  | `If     of expr * clean_cell list * clean_cell list
  | `Option of located option * expr * clean_cell list * clean_cell list
  | `List   of located option * expr * clean_cell list * clean_cell list
  | `String of int * int
  | `Sub    of expr * clean_cell list 
  | `Call   of string list
  | `Script of string * Coffee.typ list
  ]

let extract_assets add revpath sub (list : buffered_cell list) = 
  let rec aux revpath sub list = 
    let extract sub = function
      | `Print e    -> sub, `Print e 
      | `Script s   -> sub, `Script s
      | `Id id      -> sub, `Id id
      | `AdLib (v,e) -> sub, `AdLib (v,e)
      | `If (e,a,b) -> let sub, a = aux revpath sub a in
		       let sub, b = aux revpath sub b in 
		       sub, `If (e,a,b) 
      | `Option (l,e,a,b) -> let sub, a = aux revpath sub a in
			     let sub, b = aux revpath sub b in 
			     sub, `Option (l,e,a,b) 
      | `List (l,e,a,b) -> let sub, a = aux revpath sub a in
			   let sub, b = aux revpath sub b in 
			   sub, `List (l,e,a,b) 
      | `Sub (e,l) -> let sub, l = aux revpath sub l in
		      sub, `Sub (e,l)
      | `String (s,l) -> sub, `String (s,l) 
      | `Define (s,n,l) -> let revpath = n.contents :: revpath in 
			   let sub, l = aux revpath sub l in
			   add revpath l :: sub, 
			   (if s then `Call revpath else `String (0,0))
    in
    List.fold_right 
      (fun cell (sub,out) -> 
	let sub, cell = extract sub cell in 
	match cell with 
	| `String (_,0) -> (sub,out) 
	| _ ->  (sub, cell :: out))
      list (sub,[])
  in
  aux revpath sub list 

(* This extracts `Id cells back to the highest scope they can be defined in. *)

type id_cell = 
  [ `Print  of expr
  | `AdLib  of located * expr option
  | `Id     of int
  | `DefId  of (int * located) list * id_cell list
  | `If     of expr * id_cell list * id_cell list
  | `Option of located option * expr * id_cell list * id_cell list
  | `List   of located option * expr * id_cell list * id_cell list
  | `String of int * int
  | `Sub    of expr * id_cell list 
  | `Call   of string list
  | `Script of string * Coffee.typ list
  ]

let extract_ids (list : clean_cell list) = 

  let uid = ref 0 in
  let getuid () = incr uid ; !uid in

  let wrap (defs,inner) = 
    if defs <> [] then [`DefId (defs,inner)] else inner
  in
  
  let rec recurse defs list = 
    let extract defs = function
      | `Print e    -> defs, `Print e 
      | `Script s   -> defs, `Script s
      | `Id id      -> let n = getuid () in
		       ((n,id) :: defs), `Id n
      | `AdLib (v,e) -> defs, `AdLib (v,e)
      | `If (e,a,b) -> let a = wrap (recurse [] a) in
		       let b = wrap (recurse [] b) in 
		       defs, `If (e,a,b) 
      | `Option (l,e,a,b) -> let a = wrap (recurse [] a) in
			     let b = wrap (recurse [] b) in
			     defs, `Option (l,e,a,b) 
      | `List (l,e,a,b) -> let a = wrap (recurse [] a) in
			   let b = wrap (recurse [] b) in 
			   defs, `List (l,e,a,b) 
      | `Sub (e,l) -> let defs, l = recurse defs l in
		      defs, `Sub (e,l)
      | `String (s,l) -> defs, `String (s,l) 
      | `Call l -> defs, `Call l 
    in
 
    List.fold_right 
      (fun cell (defs,out) -> 
	let defs, cell = extract defs cell in 
	(defs, cell :: out))
      list (defs,[])
  in

  wrap (recurse [] list)

(* This extracts expressions from a cell list upward to a root,
   so they are evaluated together. *)

type rooted_cell = 
    [ `Print  of int 
    | `String of int * int
    | `Id     of int
    | `Script of string * (int * located) list * Coffee.typ list
    ]

and cell_root = 
  [ `Render  of rooted_cell list
  | `DefId   of int list * cell_root 
  | `Seq     of cell_root * cell_root 
  | `Extract of int * located option * cell_root
  | `AdLib   of int * located * int option * cell_root
  | `Apply   of int * int * located list * cell_root
  | `Ohm     of int * int * cell_root
  | `Put     of int * int * [ `Raw | `Esc ] * cell_root
  | `If      of int * int * cell_root * cell_root * cell_root
  | `Option  of int * located option * int * cell_root * cell_root * cell_root
  | `List    of int * located option * int * cell_root * cell_root * cell_root
  | `Sub     of int * int * cell_root * cell_root
  | `Call    of int * string list * cell_root
  ]

let contents x = x.contents

let extract_roots list = 

  let rec max_id acc = function 
    | [] -> acc
    | `Id id :: tail -> max_id (max id acc) tail 
    | `DefId (i,l) :: tail -> max_id (List.fold_left (fun a (i,_) -> max a i) acc i) tail 
    | `Option (_,_,a,b) :: tail
    | `List (_,_,a,b) :: tail 
    | `If (_,a,b) :: tail -> max_id (max_id (max_id acc a) b) tail
    | _ :: tail -> max_id acc tail  
  in
    
  let uid = ref (max_id 0 list) in
  let getuid () = incr uid ; !uid in

  let rec aux ?(ids=[]) ?(accum=[]) (list:id_cell list) = 

    let split_expr ?(printed=false) (var,flags) = 
      let uid  = getuid () in 
      let fill inner = `Extract (uid, var, inner) in
      if printed && flags = [] then
	let uid' = getuid () in
	(uid', fun inner -> fill (`Put (uid',uid,`Esc,inner)))
      else
	List.fold_left begin fun (uid,fill) flag -> 
	  match flag with 
	  | [ { contents = "ohm" } ] -> let uid' = getuid () in
					(uid', fun inner -> fill (`Ohm (uid',uid,inner)))
	  | [ { contents = "raw" } ] -> let uid' = getuid () in
					(uid', fun inner -> fill (`Put (uid',uid,`Raw,inner)))
	  | [ { contents = "esc" } ] -> let uid' = getuid () in
					(uid', fun inner -> fill (`Put (uid',uid,`Esc,inner)))
	  | [ { contents = "verbatim" } ] -> uid, fill
	  | [] -> uid, fill
	  | list -> let uid' = getuid () in
		    (uid', fun inner -> fill (`Apply (uid', uid, list, inner)))
	end (uid,fill) flags 
    in
    
    match list with 
    | [] -> `Render (List.rev accum) 
    | `Id id :: tail -> let accum = `Id id :: accum in
			aux ~ids ~accum tail 
    | [`DefId (i,l)]  -> let ids = ids @ i in 
			 `DefId (List.map fst i,aux ~ids ~accum l) 
    | `DefId (i,l) :: tail -> let a = 
				let ids = ids @ i in 
				`DefId (List.map fst i,aux ~ids ~accum l)
			      in
 			      let b = aux ~ids ~accum tail in
			      `Seq ( a, b ) 
    | `String (start,length) :: tail -> let accum = `String (start,length) :: accum in 
					aux ~ids ~accum tail 
    | `Print expr :: tail -> let uid, fill = split_expr ~printed:true expr in 
			     let accum = `Print uid :: accum in
			     fill (aux ~ids ~accum tail) 
    | `Script (name,types) :: tail -> let accum = `Script (name,ids,types) :: accum in 
				      aux ~ids ~accum tail 
    | `AdLib (variant,expr) :: tail -> let uid, fill = match expr with 
                                         | None -> None, (fun inner -> inner) 
					 | Some e -> let uid, fill = split_expr e in
						     Some uid, fill
				       in
				       let uid' = getuid () in
				       let accum = `Print uid' :: accum in
				       let fill inner = 
					 fill (`AdLib (uid', variant, uid, inner))
				       in
				       fill (aux ~ids ~accum tail) 
    | `Sub (e,l) :: tail -> let uid, fill = split_expr e in 
			    let uid' = getuid () in
			    let fill inner = fill (`Sub (uid', uid, aux ~ids l, inner)) in
			    let accum = `Print uid' :: accum in
			    fill (aux ~ids ~accum tail) 
    | `Option (l,e,a,b) :: tail -> let uid, fill = split_expr e in
				   let uid' = getuid () in
				   let a, b = aux ~ids a, aux ~ids b in
				   let fill inner = fill (`Option (uid',l,uid,a,b,inner)) in 
				   let accum = `Print uid' :: accum in 
				   fill (aux ~ids ~accum tail) 
    | `List (l,e,a,b) :: tail ->  let uid, fill = split_expr e in
				  let uid' = getuid () in
				  let a, b = aux ~ids a, aux ~ids b in 
				  let fill inner = fill (`List (uid',l,uid,a,b,inner)) in
				  let accum = `Print uid' :: accum in 
				  fill (aux ~ids ~accum tail) 
    | `If (e,a,b) :: tail -> let uid, fill = split_expr e in
			     let uid' = getuid () in
			     let a, b = aux ~ids a, aux ~ids b in 
			     let fill inner = fill (`If (uid',uid,a,b,inner)) in
			     let accum = `Print uid' :: accum in 
			     fill (aux ~ids ~accum tail) 
    | `Call l :: tail -> let uid = getuid () in
			 `Call (uid, l, aux ~ids ~accum:(`Print uid :: accum) tail) 

  in

  aux list
			   
let formats root = 
  let rec recurse (acc:string list) = function
    | `Render list -> List.concat ((List.map (function 
	| `Script (_,_,types) -> BatList.filter_map (fun (_,_,_,(fmt,_)) -> fmt) types
	| _                 -> []) list) @ [acc])
    | `Extract (_,_,r)
    | `AdLib (_,_,_,r) 
    | `Apply (_,_,_,r) 
    | `Ohm (_,_,r) 
    | `Put (_,_,_,r)
    | `DefId (_,r)  
    | `Call (_,_,r) -> recurse acc r
    | `List (_,_,_,a,b,r)  
    | `Option (_,_,_,a,b,r) 
    | `If (_,_,a,b,r) -> let acc = recurse acc r in
			 let acc = recurse acc a in
			 recurse acc b 
    | `Sub (_,_,a,b) 
    | `Seq (a,b) -> recurse (recurse acc a) b
  in
  recurse [] root

