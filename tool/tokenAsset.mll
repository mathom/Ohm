{ 

  (* Ohm is © 2012 Victor Nicollet *)
  open ParseAsset
  open SyntaxAsset

  let string_of_token = function
    | STR _ -> "%"
    | EOL _ -> "\n" 
    | ID _ -> "id=$"
    | OPEN_LIST _ -> "{#"
    | CLOSE_LIST _ -> "{/#}"
    | OPEN_OPTION _ -> "{?"
    | CLOSE_OPTION _ -> "}"
    | OPEN_SUB _ -> "{="
    | CLOSE_SUB _ -> "{/=}"
    | OPEN_DEF _ -> "{@"
    | OPEN_SDEF _ -> "{@!"
    | CLOSE_DEF _ -> "{/@}"
    | OPEN_IF _ -> "{if "
    | CLOSE_IF _ -> "{/if}"
    | ELSE _ -> "{else}"
    | OPEN _ -> "{"
    | CLOSE _ -> "}"
    | SCRIPT _ -> "<script/>"
    | STYLE _ -> "<style/>"
    | EOF -> "EOF"
    | MODULE (_,_) -> "Module"
    | DOT _ -> "."
    | PIPE _ -> "|"
    | IDENT (_,_) -> "ident"
    | EQUAL _ -> "="
    | VARIANT (_,_) -> "`Variant"
    | ERROR (c,_) -> Printf.sprintf "#! %C !#" c
}

rule outer = parse
  | ( [ ^ '\n' '{' '<' ] | "\\{" ) + as str { STR (str, pos lexbuf)  } 
  | '\n' { Lexing.new_line lexbuf ; EOL (pos lexbuf) } 
  | '<' { STR ("<", pos lexbuf) }

  | "{#"      { OPEN_LIST    (pos lexbuf) }
  | "{/#}"    { CLOSE_LIST   (pos lexbuf) } 
  | "{/?}"    { CLOSE_OPTION (pos lexbuf) } 
  | "{else}"  { ELSE         (pos lexbuf) } 
  | "{if "    { OPEN_IF      (pos lexbuf) } 
  | "{/if}"   { CLOSE_IF     (pos lexbuf) }
  | "{?"      { OPEN_OPTION  (pos lexbuf) } 
  | "{"       { OPEN         (pos lexbuf) } 
  | "{="      { OPEN_SUB     (pos lexbuf) } 
  | "{/=}"    { CLOSE_SUB    (pos lexbuf) } 
  | "{@"      { OPEN_DEF     (pos lexbuf) }
  | "{@!"     { OPEN_SDEF    (pos lexbuf) }
  | "{/@}"    { CLOSE_DEF    (pos lexbuf) } 

  | "{$" (['a'-'z' 'A'-'Z' '0'-'9' '_'] + as id) '}' { ID (id,pos lexbuf) } 

  | "<style>" { let s = style lexbuf in STYLE s }
  | "<script>" { let s = script lexbuf in SCRIPT (None,s) } 
  | "<script type=\"" ( [^ '\"'] * as t ) "\">"
      { let s = script lexbuf in SCRIPT (Some t, s) }

  | eof       { EOF } 

and inner = parse 
  | '\n' { Lexing.new_line lexbuf ; inner lexbuf } 
  | [ ' ' '\t' '\r' ] { inner lexbuf } 
  | [ 'A' - 'Z'] [ 'A'-'Z' 'a'-'z' '_' '0'-'9' ] * as str
      { MODULE (str, pos lexbuf) } 
  | '`' [ 'A' - 'Z'] [ 'A'-'Z' 'a'-'z' '_' '0'-'9' ] * as str
      { VARIANT (str, pos lexbuf) }
  | '.' { DOT (pos lexbuf) }  
  | '|' { PIPE (pos lexbuf) } 
  | [ 'a' - 'z' ] [ 'A'-'Z' 'a'-'z' '_' '0'-'9' ] * as str 
      { IDENT (str, pos lexbuf) } 
  | '}' { CLOSE (pos lexbuf) } 
  | '=' { EQUAL (pos lexbuf) } 

  | _ as c { ERROR (c, pos lexbuf) } 
  | eof    { EOF } 

and style = shortest 
  | ([^ '\n']* as s) "</style>" { s }
  | ([^ '\n']* as s) '\n' { Lexing.new_line lexbuf ; s ^ "\n" ^ style lexbuf }
  | ([^ '\n']* as s) eof { s }

and script = shortest 
  | ([^ '\n']* as s) "</script>" { s }
  | ([^ '\n']* as s) '\n' { Lexing.new_line lexbuf ; s ^ "\n" ^ script lexbuf }
  | ([^ '\n']* as s) eof { s }

{

  let opens = function 
    | OPEN_LIST _ 
    | OPEN_OPTION _
    | OPEN_IF _ 
    | OPEN _ 
    | OPEN_SUB _ 
    | OPEN_SDEF _
    | OPEN_DEF _ -> true
    | _ -> false

  let closes = function 
    | CLOSE _ -> true
    | _ -> false

  let read () = 
    let mode = ref `OUTER in 
    fun lexbuf -> 
      match !mode with 
	| `OUTER -> let tok = outer lexbuf in 
		    if opens tok then mode := `INNER ;
		    (* print_string (string_of_token tok) ; *) 
		    tok
	| `INNER -> let tok = inner lexbuf in 
		    if closes tok then mode := `OUTER ;
		    (* print_string (string_of_token tok) ; *)
		    tok 

}
