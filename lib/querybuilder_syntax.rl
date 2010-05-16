%%{
  machine querybuilder;
  # Pseudo sql syntax:
  #
  # 'RELATION [where CLAUSE] [in SCOPE]
  #  [from SUB_QUERY] [limit num(,num)] [offset num] [paginate key] [order by ORDER_CLAUSE] [group by GROUP_CLAUSE]'
  #
  # The where CLAUSE can contain the following operators

  ws       = ' ' | '\t' | '\n';
  var      = ws* ([a-zA-Z_]+) $str_a;
  dquote   = ([^"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  squote   = ([^'\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  string   = ws* ("'" squote* "'" >string | '"' dquote* '"' >dstring);
  field    = var %field ('.' %function var %method)*;
  rcontent = ('"' dquote* '"') $str_a | ([^\}"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a) ;
  rubyless = ws* "#{" rcontent+ "}" >rubyless ('.' %function var %method)*;
  real     = ws* ('-'? ('0'..'9' digit* '.' digit+) ) $str_a %real;
  integer  = ws* ('-'? digit+ ) $str_a %integer;
  number   = (real | integer);
  op       = ws* ('+' | '-' | '<' | '<=' | '=' | '>=' | '>') $str_a;
  text_op  = ws+ (('or' | 'and' | 'lt' | 'le' | 'eq' | 'ne' | 'ge' | 'gt' | 'match') $str_a | ('not' $str_a %operator ws+)? 'like' $str_a);
  operator = (op %operator | text_op %operator ws+ );
  interval = ws+ ('second'|'minute'|'hour'|'day'|'week'|'month'|'year') $str_a %interval 's'?;
  value    = ((field | string | number | rubyless) interval? | ws* '(' >goto_expr_p ws* ')');
  is_null  = ws+ 'is' %is ws+ (('not' ws+)* ('null' | 'NULL')) $str_a %raw;
  expr     = value (operator value | is_null)*;
  expr_p  := expr ws* ')' $expr_close;

  relation = ws* var %relation;
  filter   = expr ;
  filters  = ws+ 'where' %filter ws filter;
  scope    = ws+ 'in' ws var %scope;

  offset   = ws+ 'offset' %offset integer;
  paginate = ws+ 'paginate' %paginate var %param;
  limit    = ws+ 'limit' %limit integer (ws* ',' integer)?;
  direction= ws+ ('asc' | 'desc' | 'ASC' | 'DESC') $str_a %direction;
  order    = ws+ 'order' ws+ 'by' %order field (direction)? (ws* ',' field (direction)?)*;
  group    = ws+ 'group' ws+ 'by' %group field (ws* ',' field)*;

  part     = (relation filters? scope? | ws* '(' >goto_clause_p ws* ')');
  clause   = (part (ws+ 'from' %from_ part)* | '(' >goto_clause_p ws* ')' );
  clause_p:= clause ws* ')' $clause_close;
  main    := clause (ws+ ('or' | 'and') $str_a %join_clause ws clause)* group? order? limit? offset? paginate? ('\n' | ws)+ $err(error);

}%%