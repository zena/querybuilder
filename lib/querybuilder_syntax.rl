%%{
  machine querybuilder;
  # Pseudo sql syntax:
  #
  # 'RELATION [where CLAUSE] [select ATTR as NAME, ...] [in SCOPE]
  #  [from SUB_QUERY] [group by GROUP_CLAUSE] [having CLAUSE] [order by ORDER_CLAUSE] [limit num(,num)] [offset num] [paginate key]'
  #

  ws       = ' ' | '\t' | '\n';
  var      = ws* ([a-zA-Z_][a-zA-Z0-9_:]*) $str_a;
  dquote   = ([^"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  squote   = ([^'\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  string   = ws* ("'" squote* "'" >string | '"' dquote* '"' >dstring);
  rcontent = ('"' dquote* '"') $str_a | ([^\}"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a) ;
  rubyless = ws* "#{" rcontent+ "}" >rubyless ('.' %function var %method)*;
  real     = ws* ('-'? ('0'..'9' digit* '.' digit+) ) $str_a %real;
  integer  = ws* ('-'? digit+ ) $str_a %integer;
  number   = (real | integer);
  literal  = (string | number | rubyless);

  field    = var %field ('.' %function var %method ('(' (var %field | literal) (',' (var % field | literal))* ')')*)*;
  op       = ws* ('+' | '-' | '<' | '<=' | '=' | '>=' | '>' | '<>' | '!=' ) $str_a;
  text_op  = ws+ (('or' | 'and' | 'lt' | 'le' | 'eq' | 'ne' | 'ge' | 'gt' | 'match') $str_a | ('not' $str_a %operator ws+)? 'like' $str_a);
  operator = (op %operator | text_op %operator ws+ );
  interval = ws+ ('second'|'minute'|'hour'|'day'|'week'|'month'|'year') $str_a %interval 's'?;
  value    = ((field | literal) interval? | ws* '(' >goto_expr_p ws* ')');
  in_value = literal (ws* ',' literal)*;
  in_expr  = ws+ ('not' $str_a %operator ws+)? 'in' ws* '(' %in_op in_value ws* ')'; # wait until '(' to execute 'operator' to avoid confusion with scope
  is_null  = ws+ 'is' %is ws+ (('not' ws+)* ('null' | 'NULL')) $str_a %raw;
  expr     = value (operator value | in_expr | is_null)*;
  expr_p  := expr ws* ')' $expr_close;

  relation = ws* var %relation;
  filter   = expr ;
  filters  = ws+ 'where'  %filter ws filter;

  select_f = field ws+ 'as' ws+ var %select_one;
  select   = select_f (ws* ',' ws* select_f)*;
  selects  = ws+ 'select' %select ws select;

  scope    = ws+ 'in' ws var %scope;

  offset   = ws+ 'offset' %offset literal;
  paginate = ws+ 'paginate' %paginate var %param;
  limit    = ws+ 'limit' %limit literal (ws* ',' literal)?;
  direction= ws+ ('asc' | 'desc' | 'ASC' | 'DESC') $str_a %direction;
  order    = ws+ 'order' ws+ 'by' %order field (direction)? (ws* ',' field (direction)?)*;
  group    = ws+ 'group'  ws+ 'by' %group field (ws* ',' field)*;
  having   = ws+ 'having' ws+ %having expr;

  part     = (relation selects? filters? scope? | ws* '(' >goto_clause_p ws* ')');
  clause   = (part (ws+ 'from' %from_ part)* | '(' >goto_clause_p ws* ')' );
  clause_p:= clause ws* ')' $clause_close;
  main    := clause (ws+ ('or' | 'and') $str_a %join_clause ws clause)* group? having? order? limit? offset? paginate? ('\n' | ws)+ $err(error);

}%%